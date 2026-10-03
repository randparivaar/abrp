import { initializeApp, cert, getApps, type App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import dotenv from 'dotenv';

dotenv.config();

let fcmApp: App | null = null;

function getFcmApp(): App | null {
  if (fcmApp) return fcmApp;

  const existingApp = getApps().find((app) => app.name === 'abrp-fcm');
  if (existingApp) {
    fcmApp = existingApp;
    return fcmApp;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    console.warn('Firebase Cloud Messaging credentials are incomplete in environment variables.');
    return null;
  }

  // Handle potential surrounding quotes and escaped newlines
  if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
    privateKey = privateKey.slice(1, -1);
  }
  const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');

  try {
    fcmApp = initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        privateKey: formattedPrivateKey,
      }),
    }, 'abrp-fcm');
    return fcmApp;
  } catch (error) {
    console.error('Failed to initialize Firebase Admin SDK:', error);
    return null;
  }
}

export const fcmService = {
  /**
   * Send push notification to a single device.
   * @param token FCM Registration Token
   * @param title Title of the message
   * @param body Content description of the message
   * @param data Optional payload key-value pairs
   */
  async sendNotification(token: string, title: string, body: string, data?: Record<string, string>) {
    const app = getFcmApp();
    if (!app) return false;

    try {
      await getMessaging(app).send({
        token,
        notification: {
          title,
          body,
        },
        data: data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      return true;
    } catch (error) {
      console.error('FCM Error sending notification:', error);
      return false;
    }
  },

  /**
   * Send notification to a list of tokens.
   */
  async sendMulticast(tokens: string[], title: string, body: string, data?: Record<string, string>) {
    const app = getFcmApp();
    if (!app || tokens.length === 0) return false;

    try {
      const response = await getMessaging(app).sendEachForMulticast({
        tokens,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      return response.successCount > 0;
    } catch (error) {
      console.error('FCM Multicast Error:', error);
      return false;
    }
  },
};

