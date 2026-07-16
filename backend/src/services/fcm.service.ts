import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

let fcmApp: any = null;

function getFcmApp() {
  if (fcmApp) return fcmApp;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    console.warn('Firebase Cloud Messaging credentials are incomplete in environment variables.');
    return null;
  }

  // Format private key correctly (replace escaped newlines if they are passed as raw \n)
  const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');

  try {
    fcmApp = admin.initializeApp({
      credential: (admin as any).credential.cert({
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
      await app.messaging().send({
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
      const response = await app.messaging().sendEachForMulticast({
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
