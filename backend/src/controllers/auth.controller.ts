import { Context } from 'hono';
import { db } from '../db/index.js';
import { 
  findUserByEmail, 
  createUser, 
  updateGoogleLink, 
  verifyGoogleIdToken, 
  generateSessionToken 
} from '../services/auth.service.js';
import { registerDeviceToken } from '../services/notifications.service.js';
import { associateUserWithFamilyMemberByMobile } from '../services/directory.service.js';
import { GoogleLoginRequest, RegisterRequest, LoginRequest } from '../types/auth.types.js';
import { hashPassword, verifyPassword } from '../utils/crypto.js';

export async function handleGoogleLogin(c: Context) {
  try {
    const { idToken, fcmToken, deviceType } = await c.req.json<GoogleLoginRequest>();
    
    if (!idToken) {
      return c.json({ error: 'Missing required field: idToken' }, 400);
    }

    let payload;
    try {
      payload = await verifyGoogleIdToken(idToken);
    } catch (err: any) {
      console.error('Google ID token verification failed:', err);
      return c.json({ error: 'Invalid Google ID token.' }, 400);
    }

    if (!payload || !payload.email) {
      return c.json({ error: 'Failed to retrieve user profile from Google token.' }, 400);
    }

    const { email, name, picture, sub } = payload;

    let user = await findUserByEmail(email);

    if (!user) {
      user = await createUser({
        email,
        fullName: name || 'Google User',
        googleId: sub,
        avatarUrl: picture || undefined,
      });
    } else {
      let needsUpdate = false;
      let targetAvatar = user.avatarUrl;
      if (!user.googleId) {
        needsUpdate = true;
      }
      if (picture && user.avatarUrl !== picture) {
        needsUpdate = true;
        targetAvatar = picture;
      }
      if (needsUpdate) {
        user = await updateGoogleLink(user.id, sub, targetAvatar || undefined);
      }
    }

    if (user.status !== 'active') {
      return c.json({ error: `Your account is currently ${user.status}. Access denied.` }, 403);
    }

    // Save FCM Token if provided
    if (fcmToken) {
      try {
        await registerDeviceToken(user.id, fcmToken, deviceType || 'android');
      } catch (fcmError) {
        console.error('FCM Token registration failed in Google Login:', fcmError);
      }
    }

    // Associate family member by mobile if available (fire & forget)
    associateUserWithFamilyMemberByMobile(user.id, user.mobile).catch((e: any) =>
      console.error('associateUserWithFamilyMemberByMobile error:', e)
    );

    const token = generateSessionToken(user);

    return c.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        role: user.role,
        preferredLanguage: user.preferredLanguage,
        status: user.status,
      },
    });
  } catch (error: any) {
    console.error('Google Login handler error:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleRegister(c: Context) {
  try {
    const { email, fullName, password, mobile, fcmToken, deviceType } = await c.req.json<RegisterRequest>();

    if (!email || !fullName || !password || !mobile) {
      return c.json({ error: 'Missing required parameters: email, fullName, password, mobile' }, 400);
    }

    if (password.length < 6) {
      return c.json({ error: 'Password must be at least 6 characters long.' }, 400);
    }

    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      return c.json({ error: 'This email is already registered. Please log in.' }, 409);
    }

    // Check if mobile number is already registered in users table
    const cleanMobile = mobile.trim();
    const existingMobile = await db.query.users.findFirst({
      where: (u: any, { eq }: any) => eq(u.mobile, cleanMobile),
    });
    if (existingMobile) {
      return c.json({ error: 'This mobile number is already registered. Please log in.' }, 409);
    }

    const passwordHash = await hashPassword(password);

    const newUser = await createUser({
      email,
      fullName,
      passwordHash,
      mobile: cleanMobile,
    });

    // Try associating user with existing family member node by mobile (fire & forget)
    associateUserWithFamilyMemberByMobile(newUser.id, cleanMobile).catch((e: any) =>
      console.error('associateUserWithFamilyMemberByMobile error:', e)
    );

    // Save FCM Token if provided
    if (fcmToken) {
      try {
        await registerDeviceToken(newUser.id, fcmToken, deviceType || 'android');
      } catch (fcmError) {
        console.error('FCM Token registration failed in Register:', fcmError);
      }
    }

    const token = generateSessionToken(newUser);

    return c.json({
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
        avatarUrl: newUser.avatarUrl,
        role: newUser.role,
        preferredLanguage: newUser.preferredLanguage,
        status: newUser.status,
      },
    });
  } catch (error: any) {
    console.error('Registration handler error:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleLogin(c: Context) {
  try {
    const { email, password, fcmToken, deviceType } = await c.req.json<LoginRequest>();

    if (!email || !password) {
      return c.json({ error: 'Missing required parameters: email, password' }, 400);
    }

    const user = await findUserByEmail(email);

    if (!user || !user.passwordHash) {
      return c.json({ error: 'Invalid email address or password.' }, 401);
    }

    const isPasswordValid = await verifyPassword(password, user.passwordHash);
    if (!isPasswordValid) {
      return c.json({ error: 'Invalid email address or password.' }, 401);
    }

    if (user.status !== 'active') {
      return c.json({ error: `Your account is currently ${user.status}. Access denied.` }, 403);
    }

    // Save FCM Token if provided (fire & forget)
    if (fcmToken) {
      registerDeviceToken(user.id, fcmToken, deviceType || 'android').catch((fcmError) => {
        console.error('FCM Token registration failed in Login:', fcmError);
      });
    }

    // Associate family member by mobile if available (fire & forget)
    associateUserWithFamilyMemberByMobile(user.id, user.mobile).catch((e: any) =>
      console.error('associateUserWithFamilyMemberByMobile error:', e)
    );

    const token = generateSessionToken(user);

    return c.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        role: user.role,
        preferredLanguage: user.preferredLanguage,
        status: user.status,
      },
    });
  } catch (error: any) {
    console.error('Login handler error:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}
