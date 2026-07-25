import { db } from '../db/index.js';
import { devices } from '../db/schema.js';
import { eq } from 'drizzle-orm';
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

export async function sendPushNotification(tokens: string[], title: string, body: string, data: Record<string, string> = {}) {
  return await fcmService.sendMulticast(tokens, title, body, data);
}
