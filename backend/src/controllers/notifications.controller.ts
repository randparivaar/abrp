import { Context } from 'hono';
import { UserSession } from '../middleware/auth.js';
import { 
  registerDeviceToken, 
  unregisterDeviceToken, 
  getUserDevices, 
  getMultipleUserDevices,
  getAllDevices,
  sendPushNotification,
  dispatchDailyWishes
} from '../services/notifications.service.js';
import { RegisterDeviceRequest, UnregisterDeviceRequest, SendTestNotificationRequest } from '../types/notifications.types.js';

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

export async function handleSendTest(c: Context) {
  try {
    const { targetUserId, targetUserIds, title, body } = await c.req.json<SendTestNotificationRequest>();

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

    const sent = await sendPushNotification(tokens, title, body, {
      test: 'true',
      isBroadcast: isBroadcast ? 'true' : 'false',
    });

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
 * Endpoint for cron execution (e.g. Vercel Cron at 6:00 AM IST)
 */
export async function handleDailyWishesCron(c: Context) {
  try {
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
