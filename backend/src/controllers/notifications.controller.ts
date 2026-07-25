import { Context } from 'hono';
import { UserSession } from '../middleware/auth';
import { 
  registerDeviceToken, 
  unregisterDeviceToken, 
  getUserDevices, 
  sendPushNotification 
} from '../services/notifications.service';
import { RegisterDeviceRequest, UnregisterDeviceRequest, SendTestNotificationRequest } from '../types/notifications.types';

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

    const userDevices = await getUserDevices(targetUserId);

    if (userDevices.length === 0) {
      return c.json({ error: 'No active device registrations found for this user.' }, 404);
    }

    const tokens = userDevices.map(d => d.fcmToken);
    const sent = await sendPushNotification(tokens, title, body, { test: 'true' });

    return c.json({
      success: sent,
      message: sent ? 'Test notification dispatched.' : 'FCM delivery failed.',
      recipientDeviceCount: tokens.length,
    });
  } catch (error: any) {
    console.error('Error dispatching test notification:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}
