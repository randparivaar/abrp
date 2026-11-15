import { db } from '../db/index.js';
import { devices, familyMembers, notifications, notificationReads, users } from '../db/schema.js';
import { eq, and, isNotNull, inArray, sql, or, desc } from 'drizzle-orm';
import { fcmService } from './fcm.service.js';

export async function registerDeviceToken(userId: string, fcmToken: string, deviceType: 'android' | 'ios' = 'android') {
  await db.insert(devices)
    .values({
      userId,
      fcmToken,
      deviceType,
    })
    .onConflictDoUpdate({
      target: devices.fcmToken,
      set: {
        userId,
        deviceType,
        updatedAt: new Date(),
      },
    });
}

export async function unregisterDeviceToken(fcmToken: string) {
  await db.delete(devices).where(eq(devices.fcmToken, fcmToken));
}

export async function getUserDevices(userId: string) {
  return await db.select().from(devices).where(eq(devices.userId, userId));
}

export async function getMultipleUserDevices(userIds: string[]) {
  if (!userIds || userIds.length === 0) return [];
  return await db.select().from(devices).where(inArray(devices.userId, userIds));
}

export async function getAllDevices() {
  return await db.select().from(devices);
}

export async function sendPushNotification(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string> = {},
  imageUrl?: string
) {
  if (tokens.length === 0) return false;
  // Chunk in batches of 500 (FCM multicast limit)
  let anySuccess = false;
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const success = await fcmService.sendMulticast(batch, title, body, data, imageUrl);
    if (success) anySuccess = true;
  }
  return anySuccess;
}

/**
 * Creates and persists a notification in the database.
 */
export async function createNotification(params: {
  title: string;
  body: string;
  imageUrl?: string | null;
  type?: string;
  targetType?: string;
  targetId?: string | null;
  metadata?: Record<string, any>;
  createdBy?: string | null;
}) {
  const [created] = await db.insert(notifications).values({
    title: params.title,
    body: params.body,
    imageUrl: params.imageUrl || null,
    type: params.type || 'general',
    targetType: params.targetType || 'all',
    targetId: params.targetId || null,
    metadata: params.metadata || {},
    createdBy: params.createdBy || null,
  }).returning();

  return created;
}

/**
 * Retrieves in-app notification center history for a user, tagged with read status and today flag.
 */
export async function getUserNotifications(userId: string, familyId?: number | null) {
  const familyIdStr = familyId ? familyId.toString() : null;

  // Filter: targetType = 'all' OR targetId = userId OR targetId = familyId
  const conditions = [
    eq(notifications.targetType, 'all'),
    and(eq(notifications.targetType, 'user'), eq(notifications.targetId, userId)),
  ];

  if (familyIdStr) {
    conditions.push(
      and(eq(notifications.targetType, 'family'), eq(notifications.targetId, familyIdStr))
    );
  }

  const rows = await db
    .select({
      id: notifications.id,
      title: notifications.title,
      body: notifications.body,
      imageUrl: notifications.imageUrl,
      type: notifications.type,
      targetType: notifications.targetType,
      targetId: notifications.targetId,
      metadata: notifications.metadata,
      createdAt: notifications.createdAt,
      readAt: notificationReads.readAt,
    })
    .from(notifications)
    .leftJoin(
      notificationReads,
      and(
        eq(notificationReads.notificationId, notifications.id),
        eq(notificationReads.userId, userId)
      )
    )
    .where(or(...conditions))
    .orderBy(desc(notifications.createdAt))
    .limit(100);

  // Compute start of today in Indian Standard Time (UTC + 5:30)
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istNow = new Date(now.getTime() + istOffset);
  const istStartOfToday = new Date(Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate(), 0, 0, 0) - istOffset);

  const formatted = rows.map((r) => {
    const createdDate = new Date(r.createdAt);
    const isToday = createdDate >= istStartOfToday;
    const isRead = r.readAt !== null;

    return {
      id: r.id,
      title: r.title,
      body: r.body,
      imageUrl: r.imageUrl,
      type: r.type,
      targetType: r.targetType,
      targetId: r.targetId,
      metadata: (r.metadata as Record<string, any>) || null,
      createdAt: r.createdAt.toISOString(),
      isRead,
      isToday,
    };
  });

  // Separate today's notifications and earlier ones
  const todayNotifications = formatted.filter((n) => n.isToday);
  const earlierNotifications = formatted.filter((n) => !n.isToday);
  const unreadCount = formatted.filter((n) => !n.isRead).length;

  return {
    today: todayNotifications,
    earlier: earlierNotifications,
    unreadCount,
    total: formatted.length,
  };
}

/**
 * Marks a single notification as read for a user.
 */
export async function markNotificationAsRead(userId: string, notificationId: string) {
  await db
    .insert(notificationReads)
    .values({
      userId,
      notificationId,
    })
    .onConflictDoNothing();
  return true;
}

/**
 * Marks all notifications visible to a user as read.
 */
export async function markAllNotificationsAsRead(userId: string, familyId?: number | null) {
  const { today, earlier } = await getUserNotifications(userId, familyId);
  const allNotifications = [...today, ...earlier];
  const unread = allNotifications.filter((n) => !n.isRead);

  if (unread.length === 0) return 0;

  for (const n of unread) {
    await db
      .insert(notificationReads)
      .values({
        userId,
        notificationId: n.id,
      })
      .onConflictDoNothing();
  }

  return unread.length;
}

/**
 * Dispatches daily Birthday and Anniversary notifications to family members.
 * Configured to run around 6:00 AM IST.
 */
export async function dispatchDailyWishes() {
  // Compute current date in Indian Standard Time (UTC + 5:30)
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istDate = new Date(now.getTime() + istOffset);
  const currentMonth = istDate.getUTCMonth() + 1; // 1 to 12
  const currentDay = istDate.getUTCDate(); // 1 to 31

  // 1. Find birthday members who are alive and have birthDate matching today
  const birthdayMembers = await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    avatarUrl: familyMembers.avatarUrl,
    relationshipToHead: familyMembers.relationshipToHead,
    familyId: familyMembers.familyId,
    userId: familyMembers.userId,
  }).from(familyMembers)
    .where(
      and(
        eq(familyMembers.isAlive, true),
        isNotNull(familyMembers.birthDate),
        sql`EXTRACT(MONTH FROM ${familyMembers.birthDate}) = ${currentMonth}`,
        sql`EXTRACT(DAY FROM ${familyMembers.birthDate}) = ${currentDay}`
      )
    );

  // 2. Find anniversary members who are alive and have anniversaryDate matching today
  const anniversaryMembers = await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    avatarUrl: familyMembers.avatarUrl,
    relationshipToHead: familyMembers.relationshipToHead,
    familyId: familyMembers.familyId,
    userId: familyMembers.userId,
  }).from(familyMembers)
    .where(
      and(
        eq(familyMembers.isAlive, true),
        isNotNull(familyMembers.anniversaryDate),
        sql`EXTRACT(MONTH FROM ${familyMembers.anniversaryDate}) = ${currentMonth}`,
        sql`EXTRACT(DAY FROM ${familyMembers.anniversaryDate}) = ${currentDay}`
      )
    );

  let birthdaysSent = 0;
  let anniversariesSent = 0;

  // Process Birthday Notifications
  for (const bMember of birthdayMembers) {
    const title = `🎂 जन्मदिन की हार्दिक शुभकामनाएँ: ${bMember.fullName}`;
    const body = `आज हमारे परिवार सदस्य ${bMember.fullName} का जन्मदिन है! उन्हें बधाई एवं शुभकामनाएँ प्रेषित करें। 💐`;

    // Persist in notifications table
    const record = await createNotification({
      title,
      body,
      imageUrl: bMember.avatarUrl || null,
      type: 'birthday',
      targetType: 'family',
      targetId: bMember.familyId.toString(),
      metadata: {
        memberId: bMember.id,
        memberName: bMember.fullName,
        familyId: bMember.familyId,
        avatarUrl: bMember.avatarUrl,
        wishType: 'birthday',
      },
    });

    // Find registered family members belonging to the same family
    const relatives = await db.select({
      userId: familyMembers.userId,
    }).from(familyMembers)
      .where(
        and(
          eq(familyMembers.familyId, bMember.familyId),
          isNotNull(familyMembers.userId)
        )
      );

    const userIds = relatives.map(r => r.userId!).filter(Boolean);
    if (userIds.length > 0) {
      const relativeDevices = await db.select({
        fcmToken: devices.fcmToken,
      }).from(devices)
        .where(inArray(devices.userId, userIds));

      const tokens = relativeDevices.map(d => d.fcmToken);
      if (tokens.length > 0) {
        await sendPushNotification(
          tokens,
          title,
          body,
          {
            type: 'birthday_wish',
            notificationId: record.id,
            memberId: bMember.id.toString(),
            familyId: bMember.familyId.toString(),
            memberName: bMember.fullName,
            avatarUrl: bMember.avatarUrl || '',
          },
          bMember.avatarUrl || undefined
        );
        birthdaysSent++;
      }
    }
  }

  // Process Anniversary Notifications
  for (const aMember of anniversaryMembers) {
    // Try to find spouse in the same family
    const familyAll = await db.select({
      id: familyMembers.id,
      fullName: familyMembers.fullName,
      avatarUrl: familyMembers.avatarUrl,
      relationshipToHead: familyMembers.relationshipToHead,
    }).from(familyMembers)
      .where(eq(familyMembers.familyId, aMember.familyId));

    const spouse = familyAll.find(m => 
      m.id !== aMember.id && 
      (m.relationshipToHead === 'spouse' || aMember.relationshipToHead === 'spouse')
    );

    const coupleNames = spouse 
      ? `${aMember.fullName} एवं ${spouse.fullName}`
      : aMember.fullName;

    const title = `💍 वैवाहिक वर्षगांठ की शुभकामनाएँ: ${coupleNames}`;
    const body = `आज ${coupleNames} की वैवाहिक वर्षगांठ है! उनके सुखद दांपत्य जीवन हेतु मंगलकामनाएँ। 💐`;

    // Persist in notifications table
    const record = await createNotification({
      title,
      body,
      imageUrl: aMember.avatarUrl || spouse?.avatarUrl || null,
      type: 'anniversary',
      targetType: 'family',
      targetId: aMember.familyId.toString(),
      metadata: {
        memberId: aMember.id,
        memberName: aMember.fullName,
        spouseName: spouse?.fullName || null,
        coupleNames,
        familyId: aMember.familyId,
        avatarUrl: aMember.avatarUrl,
        spouseAvatarUrl: spouse?.avatarUrl || null,
        wishType: 'anniversary',
      },
    });

    const relatives = await db.select({
      userId: familyMembers.userId,
    }).from(familyMembers)
      .where(
        and(
          eq(familyMembers.familyId, aMember.familyId),
          isNotNull(familyMembers.userId)
        )
      );

    const userIds = relatives.map(r => r.userId!).filter(Boolean);
    if (userIds.length > 0) {
      const relativeDevices = await db.select({
        fcmToken: devices.fcmToken,
      }).from(devices)
        .where(inArray(devices.userId, userIds));

      const tokens = relativeDevices.map(d => d.fcmToken);
      if (tokens.length > 0) {
        await sendPushNotification(
          tokens,
          title,
          body,
          {
            type: 'anniversary_wish',
            notificationId: record.id,
            memberId: aMember.id.toString(),
            familyId: aMember.familyId.toString(),
            coupleNames,
            avatarUrl: aMember.avatarUrl || '',
          },
          aMember.avatarUrl || spouse?.avatarUrl || undefined
        );
        anniversariesSent++;
      }
    }
  }

  return {
    matchedBirthdays: birthdayMembers.length,
    matchedAnniversaries: anniversaryMembers.length,
    birthdaysSent,
    anniversariesSent,
    dateIST: `${currentDay}/${currentMonth}`,
  };
}
