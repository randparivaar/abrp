import { db } from '../db/index.js';
import { devices, familyMembers } from '../db/schema.js';
import { eq, and, isNotNull, inArray, sql } from 'drizzle-orm';
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

export async function sendPushNotification(tokens: string[], title: string, body: string, data: Record<string, string> = {}) {
  if (tokens.length === 0) return false;
  // Chunk in batches of 500 (FCM multicast limit)
  let anySuccess = false;
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const success = await fcmService.sendMulticast(batch, title, body, data);
    if (success) anySuccess = true;
  }
  return anySuccess;
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
        const title = '🎂 जन्मदिन की शुभकामनाएं / Birthday Reminder';
        const body = `Today is ${bMember.fullName}'s Birthday! Wish them a very Happy Birthday! 💐`;
        await sendPushNotification(tokens, title, body, {
          type: 'birthday_wish',
          memberId: bMember.id.toString(),
          familyId: bMember.familyId.toString(),
        });
        birthdaysSent++;
      }
    }
  }

  // Process Anniversary Notifications
  for (const aMember of anniversaryMembers) {
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
        const title = '💍 सालगिरह की शुभकामनाएं / Anniversary Reminder';
        const body = `Today is ${aMember.fullName}'s Wedding Anniversary! Send your best wishes! 💐`;
        await sendPushNotification(tokens, title, body, {
          type: 'anniversary_wish',
          memberId: aMember.id.toString(),
          familyId: aMember.familyId.toString(),
        });
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
