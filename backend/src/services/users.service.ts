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

export async function updateUserRole(userId: string, newRole: 'admin' | 'member' | 'moderator', regionIds?: number[]) {
  const [updatedUser] = await db.update(users)
    .set({ role: newRole, updatedAt: new Date() })
    .where(eq(users.id, userId))
    .returning();

  if (!updatedUser) return null;

  // Manage region assignment for moderators
  const { coordinatorRegions } = await import('../db/schema.js');
  
  // Clear existing region assignments for this user
  await db.delete(coordinatorRegions).where(eq(coordinatorRegions.userId, userId));

  // If role is moderator and regionIds are provided, insert new assignments
  if (newRole === 'moderator' && regionIds && regionIds.length > 0) {
    const recordsToInsert = regionIds.map(rId => ({
      userId,
      regionId: rId,
    }));
    await db.insert(coordinatorRegions).values(recordsToInsert);
  }

  return updatedUser;
}

export async function listAllUsers() {
  const { coordinatorRegions, regions } = await import('../db/schema.js');
  
  const userList = await db.select().from(users);

  // Fetch assigned regions for moderators
  const assignments = await db
    .select({
      userId: coordinatorRegions.userId,
      regionId: coordinatorRegions.regionId,
      regionName: regions.name,
    })
    .from(coordinatorRegions)
    .innerJoin(regions, eq(coordinatorRegions.regionId, regions.id));

  const userRegionMap: Record<string, { id: number; name: string }[]> = {};
  for (const a of assignments) {
    if (!userRegionMap[a.userId]) {
      userRegionMap[a.userId] = [];
    }
    userRegionMap[a.userId].push({ id: a.regionId, name: a.regionName });
  }

  return userList.map(u => ({
    ...u,
    assignedRegions: userRegionMap[u.id] || [],
  }));
}

