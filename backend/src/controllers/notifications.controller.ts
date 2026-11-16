import { Context } from 'hono';
import { UserSession } from '../middleware/auth.js';
import {
  registerDeviceToken,
  unregisterDeviceToken,
  getUserDevices,
  getMultipleUserDevices,
  getAllDevices,
  sendPushNotification,
  dispatchDailyWishes,
  createNotification,
  getUserNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead
} from '../services/notifications.service.js';
import { r2Service } from '../services/r2.service.js';
import {
  RegisterDeviceRequest,
  UnregisterDeviceRequest,
  SendTestNotificationRequest,
  SendWishNotificationRequest
} from '../types/notifications.types.js';
import { db } from '../db/index.js';
import { familyMembers } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export async function handleRegisterDevice(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const { fcmToken, deviceType } = await c.req.json<RegisterDeviceRequest>();

    if (!fcmToken) {
      return c.json({ error: 'Missing required field: fcmToken' }, 400);
    }

    await registerDeviceToken(user.id, fcmToken, deviceType);

    return c.json({ success: true, message: 'Device token registered successfully.' });
  } catch (error: any) {
    console.error('Error registering FCM token:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleUnregisterDevice(c: Context) {
  try {
    const { fcmToken } = await c.req.json<UnregisterDeviceRequest>();

    if (!fcmToken) {
      return c.json({ error: 'Missing required field: fcmToken' }, 400);
    }

    await unregisterDeviceToken(fcmToken);

    return c.json({ success: true, message: 'Device token unregistered successfully.' });
  } catch (error: any) {
    console.error('Error unregistering FCM token:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Lists available poster images from Cloudflare R2 bucket.
 * GET /v1/notifications/posters?search=diwali
 */
export async function handleListPosters(c: Context) {
  try {
    const search = c.req.query('search') || '';
    const prefix = c.req.query('prefix') || '';

    const posters = await r2Service.listPosters(search, prefix);

    return c.json({
      success: true,
      posters,
      count: posters.length,
    });
  } catch (error: any) {
    console.error('Error listing R2 posters:', error);
    return c.json({ error: 'Failed to list posters', message: error.message }, 500);
  }
}

/**
 * Dispatches a festival or community wish notification with full poster image.
 * POST /v1/notifications/send-wish
 */
export async function handleSendWishNotification(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const body = await c.req.json<SendWishNotificationRequest>();

    const { title, body: content, imageUrl, type = 'festival', targetType = 'all', targetIds = [], metadata = {} } = body;

    if (!title) {
      return c.json({ error: 'Missing required field: title' }, 400);
    }

    const safeBody = (content && content.trim()) || '';

    // 1. Persist notification in database
    const notification = await createNotification({
      title,
      body: safeBody,
      imageUrl: imageUrl || null,
      type,
      targetType,
      targetId: targetIds.length === 1 ? targetIds[0] : (targetType === 'all' ? null : 'multiple'),
      metadata: {
        ...metadata,
        posterUrl: imageUrl || null,
      },
      createdBy: user.id,
    });

    // 2. Resolve target device tokens
    let tokens: string[] = [];
    const isBroadcast = targetType === 'all' || targetIds.includes('all');

    if (isBroadcast) {
      const allDevices = await getAllDevices();
      tokens = allDevices.map(d => d.fcmToken);
    } else if (targetType === 'family') {
      // Find members belonging to specified family ID(s)
      const familyUserIds = await db
        .select({ userId: familyMembers.userId })
        .from(familyMembers)
        .where(eq(familyMembers.familyId, parseInt(targetIds[0], 10)));
      const uIds = familyUserIds.map(f => f.userId!).filter(Boolean);
      const userDevices = await getMultipleUserDevices(uIds);
      tokens = userDevices.map(d => d.fcmToken);
    } else {
      const userDevices = await getMultipleUserDevices(targetIds);
      tokens = userDevices.map(d => d.fcmToken);
    }

    // Deduplicate
    tokens = Array.from(new Set(tokens.filter(Boolean)));

    if (tokens.length === 0) {
      return c.json({
        success: true,
        message: 'Notification saved to database, but no active recipient devices were found registered.',
        notification,
        recipientDeviceCount: 0,
      });
    }

    // 3. Dispatch FCM push with BigPicture image
    const sent = await sendPushNotification(
      tokens,
      title,
      safeBody,
      {
        type: type || 'festival_wish',
        notificationId: notification.id,
        posterUrl: imageUrl || '',
        title,
        body: safeBody,
      },
      imageUrl || undefined
    );

    return c.json({
      success: sent,
      message: sent
        ? (isBroadcast
          ? `Broadcast poster notification dispatched to ${tokens.length} devices.`
          : `Notification dispatched to ${tokens.length} device(s).`)
        : 'Saved to history, but FCM push delivery encountered an issue.',
      notification,
      recipientDeviceCount: tokens.length,
    });
  } catch (error: any) {
    console.error('Error sending wish notification:', error);
    return c.json({ error: 'Internal Server Error', message: error.message }, 500);
  }
}

/**
 * Retrieves in-app notification center history for the logged-in user.
 * GET /v1/notifications
 */
export async function handleGetNotifications(c: Context) {
  try {
    const user = c.get('user') as UserSession;

    // Look up user's familyId if available
    const member = await db.query.familyMembers.findFirst({
      where: eq(familyMembers.userId, user.id),
      columns: { familyId: true },
    });

    const result = await getUserNotifications(user.id, member?.familyId);

    return c.json({
      success: true,
      ...result,
    });
  } catch (error: any) {
    console.error('Error fetching user notifications:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Marks a notification as read.
 * POST /v1/notifications/:id/read
 */
export async function handleMarkAsRead(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const notificationId = c.req.param('id');

    if (!notificationId) {
      return c.json({ error: 'Missing notification id' }, 400);
    }

    await markNotificationAsRead(user.id, notificationId);

    return c.json({ success: true, message: 'Notification marked as read.' });
  } catch (error: any) {
    console.error('Error marking notification as read:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Marks all notifications as read for current user.
 * POST /v1/notifications/read-all
 */
export async function handleMarkAllAsRead(c: Context) {
  try {
    const user = c.get('user') as UserSession;

    const member = await db.query.familyMembers.findFirst({
      where: eq(familyMembers.userId, user.id),
      columns: { familyId: true },
    });

    const count = await markAllNotificationsAsRead(user.id, member?.familyId);

    return c.json({ success: true, markedCount: count, message: 'All notifications marked as read.' });
  } catch (error: any) {
    console.error('Error marking all notifications as read:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleSendTest(c: Context) {
  try {
    const { targetUserId, targetUserIds, title, body, imageUrl } = await c.req.json<SendTestNotificationRequest>();

    const targetList: string[] = targetUserIds && Array.isArray(targetUserIds) && targetUserIds.length > 0
      ? targetUserIds
      : (targetUserId ? [targetUserId] : []);

    if (targetList.length === 0 || !title || !body) {
      return c.json({ error: 'Missing parameters: targetUserId(s), title, or body' }, 400);
    }

    let tokens: string[] = [];
    const isBroadcast = targetList.includes('all');

    if (isBroadcast) {
      const allDevices = await getAllDevices();
      tokens = allDevices.map(d => d.fcmToken);
    } else {
      const userDevices = await getMultipleUserDevices(targetList);
      tokens = userDevices.map(d => d.fcmToken);
    }

    // Deduplicate and filter non-empty tokens
    tokens = Array.from(new Set(tokens.filter(Boolean)));

    if (tokens.length === 0) {
      return c.json({
        success: false,
        message: isBroadcast
          ? 'No registered member devices found to broadcast.'
          : 'No active device registrations found for selected user(s). The member(s) have not registered push tokens yet.',
      }, 400);
    }

    const sent = await sendPushNotification(
      tokens,
      title,
      body,
      {
        test: 'true',
        isBroadcast: isBroadcast ? 'true' : 'false',
        posterUrl: imageUrl || '',
      },
      imageUrl || undefined
    );

    return c.json({
      success: sent,
      message: sent
        ? (isBroadcast ? `Broadcast notification dispatched to ${tokens.length} devices.` : `Notification dispatched to ${tokens.length} device(s) across ${targetList.length} member(s).`)
        : 'FCM delivery failed.',
      recipientDeviceCount: tokens.length,
    });
  } catch (error: any) {
    console.error('Error dispatching test notification:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Endpoint for cron execution (e.g. GitHub Actions Cron at 6:00 AM IST)
 */
export async function handleDailyWishesCron(c: Context) {
  try {
    const cronSecret = process.env.CRON_SECRET;
    if (cronSecret) {
      const authHeader = c.req.header('authorization');
      const customHeader = c.req.header('x-cron-secret');
      if (authHeader !== `Bearer ${cronSecret}` && customHeader !== cronSecret) {
        return c.json({ error: 'Unauthorized: Invalid cron authorization' }, 401);
      }
    }

    const result = await dispatchDailyWishes();
    return c.json({
      success: true,
      message: 'Daily wishes dispatched.',
      ...result,
    });
  } catch (error: any) {
    console.error('Error in handleDailyWishesCron:', error);
    return c.json({ error: 'Internal Server Error', details: error.message }, 500);
  }
}
