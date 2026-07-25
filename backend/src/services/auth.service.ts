import { db } from '../db';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { hashPassword } from '../utils/crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'abrp_local_development_jwt_secret_key_change_me_in_production';
const googleClientIds = (process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || '').split(',').map(id => id.trim()).filter(Boolean);
const oauthClient = new OAuth2Client();

export async function findUserByEmail(email: string) {
  return await db.query.users.findFirst({
    where: eq(users.email, email.toLowerCase().trim()),
  });
}

export async function createUser(data: { email: string; fullName: string; passwordHash?: string; googleId?: string; avatarUrl?: string; mobile?: string }) {
  const [newUser] = await db.insert(users).values({
    email: data.email.toLowerCase().trim(),
    fullName: data.fullName.trim(),
    passwordHash: data.passwordHash || null,
    googleId: data.googleId || null,
    avatarUrl: data.avatarUrl || null,
    mobile: data.mobile || null,
    role: 'member',
    preferredLanguage: 'en',
    status: 'active',
  }).returning();
  return newUser;
}

export async function updateGoogleLink(userId: string, googleId: string, avatarUrl?: string) {
  let updateFields: Partial<typeof users.$inferInsert> = {
    googleId,
  };
  if (avatarUrl) {
    updateFields.avatarUrl = avatarUrl;
  }

  const [updatedUser] = await db.update(users)
    .set(updateFields)
    .where(eq(users.id, userId))
    .returning();
  return updatedUser;
}

export async function verifyGoogleIdToken(idToken: string) {
  const ticket = await oauthClient.verifyIdToken({
    idToken,
    audience: googleClientIds.length > 0 ? googleClientIds : undefined,
  });
  return ticket.getPayload();
}

export function generateSessionToken(user: { id: string; email: string | null; role: string }): string {
  return jwt.sign(
    {
      id: user.id,
      email: user.email || '',
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

