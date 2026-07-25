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

    // Save FCM Token & Associate Family Member reliably before returning response
    await Promise.allSettled([
      fcmToken ? registerDeviceToken(user.id, fcmToken, deviceType || 'android') : Promise.resolve(),
      associateUserWithFamilyMemberByMobile(user.id, user.mobile),
    ]);

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

    // Save FCM Token & Associate Family Member reliably before returning response
    await Promise.allSettled([
      fcmToken ? registerDeviceToken(newUser.id, fcmToken, deviceType || 'android') : Promise.resolve(),
      associateUserWithFamilyMemberByMobile(newUser.id, cleanMobile),
    ]);

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

    // Save FCM Token & Associate Family Member reliably before returning response
    await Promise.allSettled([
      fcmToken ? registerDeviceToken(user.id, fcmToken, deviceType || 'android') : Promise.resolve(),
      associateUserWithFamilyMemberByMobile(user.id, user.mobile),
    ]);

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

// In-memory OTP Cache for Password Reset (valid for 15 mins)
const otpStore = new Map<string, { otp: string; expiresAt: number }>();

export async function handleForgotPassword(c: Context) {
  try {
    const { email } = await c.req.json<{ email: string }>();

    if (!email || !email.trim()) {
      return c.json({ error: 'Please enter a valid email address.' }, 400);
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = await findUserByEmail(cleanEmail);

    if (!user) {
      return c.json({ message: 'If an account exists with this email, an OTP has been sent.', success: true });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 15 * 60 * 1000;

    otpStore.set(cleanEmail, { otp, expiresAt });

    console.log(`[AUTH] Password Reset OTP for ${cleanEmail}: ${otp}`);

    return c.json({
      message: 'Password reset OTP has been sent to your email.',
      success: true,
      otp,
    });
  } catch (error: any) {
    console.error('Forgot Password handler error:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleResetPassword(c: Context) {
  try {
    const { email, otp, newPassword } = await c.req.json<{ email: string; otp: string; newPassword: string }>();

    if (!email || !otp || !newPassword) {
      return c.json({ error: 'Missing required parameters: email, otp, newPassword' }, 400);
    }

    if (newPassword.length < 6) {
      return c.json({ error: 'New password must be at least 6 characters long.' }, 400);
    }

    const cleanEmail = email.toLowerCase().trim();
    const storedOtpData = otpStore.get(cleanEmail);

    if (!storedOtpData || storedOtpData.otp !== otp.trim()) {
      return c.json({ error: 'Invalid or expired OTP code.' }, 400);
    }

    if (Date.now() > storedOtpData.expiresAt) {
      otpStore.delete(cleanEmail);
      return c.json({ error: 'OTP code has expired. Please request a new one.' }, 400);
    }

    const user = await findUserByEmail(cleanEmail);
    if (!user) {
      return c.json({ error: 'User not found.' }, 404);
    }

    const { updateUserPassword } = await import('../services/auth.service.js');
    const newPasswordHash = await hashPassword(newPassword);
    await updateUserPassword(user.id, newPasswordHash);

    otpStore.delete(cleanEmail);

    return c.json({
      message: 'Password updated successfully. Please log in with your new password.',
      success: true,
    });
  } catch (error: any) {
    console.error('Reset Password handler error:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

