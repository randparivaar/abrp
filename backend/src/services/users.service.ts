import { db } from '@/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { UpdateUserProfileRequest } from '@/types/users.types';

export async function getUserById(userId: string) {
  return await db.query.users.findFirst({
    where: eq(users.id, userId),
  });
}

export async function updateUserProfile(userId: string, data: UpdateUserProfileRequest) {
  let updateFields: Partial<typeof users.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (data.fullName) {
    updateFields.fullName = data.fullName;
  }
  
  if (data.preferredLanguage) {
    updateFields.preferredLanguage = data.preferredLanguage;
  }

  if (data.avatarUrl !== undefined) {
    updateFields.avatarUrl = data.avatarUrl;
  }

  const [updatedUser] = await db.update(users)
    .set(updateFields)
    .where(eq(users.id, userId))
    .returning();
  return updatedUser;
}

export async function updateUserRole(userId: string, newRole: 'admin' | 'member' | 'moderator') {
  const [updatedUser] = await db.update(users)
    .set({ role: newRole, updatedAt: new Date() })
    .where(eq(users.id, userId))
    .returning();
  return updatedUser;
}

export async function listAllUsers() {
  return await db.select().from(users);
}
