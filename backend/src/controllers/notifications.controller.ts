import { Context } from 'hono';
import { UserSession } from '../middleware/auth.js';
import { 
  registerDeviceToken, 
  unregisterDeviceToken, 
  getUserDevices, 
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
    const { targetUserId, title, body } = await c.req.json<SendTestNotificationRequest>();

    if (!targetUserId || !title || !body) {
      return c.json({ error: 'Missing parameters: targetUserId, title, or body' }, 400);
    }

    let tokens: string[] = [];

    if (targetUserId === 'all') {
      const allDevices = await getAllDevices();
      tokens = allDevices.map(d => d.fcmToken);
    } else {
      const userDevices = await getUserDevices(targetUserId);
      tokens = userDevices.map(d => d.fcmToken);
    }

    if (tokens.length === 0) {
      return c.json({
        success: false,
        message: targetUserId === 'all'
          ? 'No registered member devices found to broadcast.'
          : 'No active device registrations found for this user.',
      }, 404);
    }

    const sent = await sendPushNotification(tokens, title, body, {
      test: 'true',
      isBroadcast: targetUserId === 'all' ? 'true' : 'false',
    });

    return c.json({
      success: sent,
      message: sent
        ? (targetUserId === 'all' ? `Broadcast notification dispatched to ${tokens.length} devices.` : 'Notification dispatched successfully.')
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
