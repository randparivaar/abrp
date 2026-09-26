import { db, dbRetry } from '../db/index.js';
import { users } from '../db/schema.js';
import { eq, ilike, or, count, desc, ne, and } from 'drizzle-orm';
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
  await dbRetry(() => db.delete(coordinatorRegions).where(eq(coordinatorRegions.userId, userId)));

  // If role is moderator and regionIds are provided, insert new assignments
  if (newRole === 'moderator' && regionIds && regionIds.length > 0) {
    const recordsToInsert = regionIds.map(rId => ({
      userId,
      regionId: rId,
    }));
    await dbRetry(() => db.insert(coordinatorRegions).values(recordsToInsert));
  }

  return updatedUser;
}

export async function listAllUsers(search?: string, page: number = 1, limit: number = 10) {
  const { coordinatorRegions, regions } = await import('../db/schema.js');
  
  const offset = (page - 1) * limit;
  let whereClause = undefined;
  
  if (search && search.trim().length > 0) {
    const q = `%${search.trim()}%`;
    whereClause = or(
      ilike(users.fullName, q),
      ilike(users.email, q),
      ilike(users.mobile, q)
    );
  }

  // Get total count
  const [{ value: totalCount }] = await dbRetry(() => db
    .select({ value: count() })
    .from(users)
    .where(whereClause));

  // Get paginated users
  const userList = await dbRetry(() => db
    .select()
    .from(users)
    .where(whereClause)
    .orderBy(desc(users.createdAt))
    .limit(limit)
    .offset(offset));

  // Fetch assigned regions for moderators
  const assignments = await dbRetry(() =>
    db
      .select({
        userId: coordinatorRegions.userId,
        regionId: coordinatorRegions.regionId,
        regionName: regions.name,
      })
      .from(coordinatorRegions)
      .innerJoin(regions, eq(coordinatorRegions.regionId, regions.id))
  );

  const userRegionMap: Record<string, { id: number; name: string }[]> = {};
  for (const a of assignments) {
    if (!userRegionMap[a.userId]) {
      userRegionMap[a.userId] = [];
    }
    userRegionMap[a.userId].push({ id: a.regionId, name: a.regionName });
  }

  const mappedUsers = userList.map(u => ({
    ...u,
    assignedRegions: userRegionMap[u.id] || [],
  }));

  const totalPages = Math.ceil(Number(totalCount) / limit);

  return {
    users: mappedUsers,
    totalCount: Number(totalCount),
    page,
    limit,
    totalPages: totalPages > 0 ? totalPages : 1,
  };
}

export async function deleteUserAccount(userId: string) {
  // 1. Fetch user to verify existence
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });
  if (!user) return null;

  const { devices, coordinatorRegions, familyMembers, advertisements, businessProfiles } = await import('../db/schema.js');

  // 2. Remove FCM device tokens
  await dbRetry(() => db.delete(devices).where(eq(devices.userId, userId)));

  // 3. Remove coordinator assignments if user was moderator
  await dbRetry(() => db.delete(coordinatorRegions).where(eq(coordinatorRegions.userId, userId)));

  // 4. Unlink family member node: preserves family tree structure, frees personal credentials
  await dbRetry(() => db.update(familyMembers)
    .set({ userId: null, updatedAt: new Date() })
    .where(eq(familyMembers.userId, userId)));

  // 5. Handle user-created records to satisfy foreign key constraints
  const fallbackAdmin = await db.query.users.findFirst({
    where: and(ne(users.id, userId), eq(users.role, 'admin')),
  });
  
  let fallbackId = fallbackAdmin?.id;
  if (!fallbackId) {
    const anyOtherUser = await db.query.users.findFirst({
      where: ne(users.id, userId),
    });
    fallbackId = anyOtherUser?.id;
  }

  if (fallbackId) {
    // Reassign created records to fallback admin/system user
    await dbRetry(() => db.update(familyMembers).set({ createdBy: fallbackId }).where(eq(familyMembers.createdBy, userId)));
    await dbRetry(() => db.update(businessProfiles).set({ createdBy: fallbackId }).where(eq(businessProfiles.createdBy, userId)));
    await dbRetry(() => db.update(advertisements).set({ createdBy: fallbackId }).where(eq(advertisements.createdBy, userId)));
  }

  // 6. Delete user record - frees email, mobile, and googleId for clean re-registration
  await dbRetry(() => db.delete(users).where(eq(users.id, userId)));

  return { success: true };
}


