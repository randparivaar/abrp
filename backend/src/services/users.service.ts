import { db } from '../db/index.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';
import { UpdateUserProfileRequest } from '../types/users.types.js';

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
    // Bi-directional Sync: Update linked family member node avatar
    try {
      const { familyMembers } = await import('../db/schema.js');
      await db.update(familyMembers)
        .set({ avatarUrl: data.avatarUrl, updatedAt: new Date() })
        .where(eq(familyMembers.userId, userId));
    } catch (err) {
      console.error('Error syncing user avatar to familyMember node:', err);
    }
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
