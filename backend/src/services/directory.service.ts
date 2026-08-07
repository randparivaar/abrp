import { db, dbRetry } from '../db/index.js';
import { users, families, familyMembers, villages, regions, businessProfiles, businessMembers, businessLocations, coordinatorRegions } from '../db/schema.js';
import { eq, sql, and, inArray, desc } from 'drizzle-orm';
import { OnboardFamilyRequest, AddFamilyMemberRequest } from '../types/directory.types.js';
import { getUserDevices, sendPushNotification } from './notifications.service.js';

/**
 * Generate a unique family code (e.g. ABRP-10001)
 */
async function generateUniqueFamilyCode(): Promise<string> {
  const [lastFamily] = await db
    .select({ id: families.id })
    .from(families)
    .orderBy(desc(families.id))
    .limit(1);
  const nextId = lastFamily ? lastFamily.id + 1 : 1;
  return `ABRP-${10000 + nextId}`;
}

/**
 * Get all available villages with their region/zone name
 */
export async function getVillagesList() {
  return await db.query.villages.findMany({
    with: {
      region: true
    },
    orderBy: (v: any, { asc }: any) => [asc(v.name)]
  });
}

/**
 * Get all administrative regions/zones
 */
export async function getRegionsList() {
  return await db.query.regions.findMany({
    orderBy: (r: any, { asc }: any) => [asc(r.name)]
  });
}


/**
 * Onboard a new family
 */
export async function onboardNewFamily(sessionUserId: string, payload: OnboardFamilyRequest) {
  // Check if user has already created or is linked to a family
  const existingMember = await db.query.familyMembers.findFirst({
    where: (m: any, { or, eq }: any) => or(eq(m.userId, sessionUserId), eq(m.createdBy, sessionUserId)),
  });
  if (existingMember) {
    throw new Error('User has already created a family.');
  }

  // Check mobile uniqueness for family head if mobile provided
  if (payload.head.mobile && payload.head.mobile.trim().length > 0) {
    const existingMobile = await db.query.familyMembers.findFirst({
      where: eq(familyMembers.mobile, payload.head.mobile.trim()),
    });
    if (existingMobile) {
      throw new Error('This mobile number is already registered with another family member.');
    }
  }

  // 1. Generate unique family code
  const familyCode = await generateUniqueFamilyCode();

  // 2. Create the family record
  const [newFamily] = await db.insert(families).values({
    familyCode,
    address: payload.family.address,
    city: payload.family.city || null,
    state: payload.family.state || null,
    pincode: payload.family.pincode || null,
    villageId: payload.family.villageId,
  }).returning();

  try {
    // 3. Create the Family Head
    const birthDateParsed = payload.head.birthDate ? new Date(payload.head.birthDate) : null;
    let estimatedBirthYear: number | null = null;
    if (payload.head.estimatedAgeOnCreation) {
      const currentYear = new Date().getFullYear();
      estimatedBirthYear = currentYear - payload.head.estimatedAgeOnCreation;
    }

    const [newHead] = await db.insert(familyMembers).values({
      familyId: newFamily.id,
      userId: sessionUserId, // Link current authenticated user to the head node
      fullName: payload.head.fullName,
      gender: payload.head.gender,
      relationshipToHead: 'self', // Family Head relationship is always 'self'
      birthDate: birthDateParsed,
      estimatedAgeOnCreation: payload.head.estimatedAgeOnCreation || null,
      estimatedBirthYear,
      mobile: payload.head.mobile || null,
      whatsappMobile: payload.head.whatsappMobile || null,
      gotra: payload.head.gotra || null,
      bloodGroup: payload.head.bloodGroup || null,
      education: payload.head.education || null,
      occupationType: payload.head.occupationType || 'other',
      occupationDetail: payload.head.occupationDetail || null,
      yearlyIncome: payload.head.yearlyIncome || null,
      createdBy: sessionUserId,
      status: 'pending', // Starts as pending until validated by coordinator
    }).returning();

    // 4. Update family record to set the familyHeadId circular reference
    await db.update(families)
      .set({ familyHeadId: newHead.id })
      .where(eq(families.id, newFamily.id));

    return {
      family: newFamily,
      head: newHead
    };
  } catch (error) {
    // Clean up created family if subsequent inserts fail
    await db.delete(families).where(eq(families.id, newFamily.id));
    throw error;
  }
}

/**
 * Add a member to a family unit
 */
export async function addMemberToFamily(sessionUserId: string, payload: AddFamilyMemberRequest) {
  // Check mobile uniqueness if mobile provided
  if (payload.mobile && payload.mobile.trim().length > 0) {
    const existingMobile = await db.query.familyMembers.findFirst({
      where: eq(familyMembers.mobile, payload.mobile.trim()),
    });
    if (existingMobile) {
      throw new Error('This mobile number is already registered with another family member.');
    }
  }

  const birthDateParsed = payload.birthDate ? new Date(payload.birthDate) : null;
  let estimatedBirthYear: number | null = null;
  if (payload.estimatedAgeOnCreation) {
    const currentYear = new Date().getFullYear();
    estimatedBirthYear = currentYear - payload.estimatedAgeOnCreation;
  }

  const anniversaryDateParsed = payload.anniversaryDate ? new Date(payload.anniversaryDate) : null;
  const isSpouseRelation = payload.relationshipToHead === 'spouse' || payload.spouseId;
  const finalMaritalStatus = isSpouseRelation ? 'married' : (payload.maritalStatus || 'single');

  const [newMember] = await db.insert(familyMembers).values({
    familyId: payload.familyId,
    fullName: payload.fullName,
    gender: payload.gender,
    relationshipToHead: payload.relationshipToHead,
    birthDate: birthDateParsed,
    estimatedAgeOnCreation: payload.estimatedAgeOnCreation || null,
    estimatedBirthYear,
    mobile: payload.mobile || null,
    whatsappMobile: payload.whatsappMobile || null,
    email: payload.email || null,
    bloodGroup: payload.bloodGroup || null,
    gotra: payload.gotra || null,
    maritalStatus: finalMaritalStatus,
    anniversaryDate: anniversaryDateParsed,
    currentAddress: payload.currentAddress || null,
    currentCity: payload.currentCity || null,
    currentState: payload.currentState || null,
    currentPincode: payload.currentPincode || null,
    education: payload.education || null,
    occupationType: payload.occupationType || 'other',
    occupationDetail: payload.occupationDetail || null,
    yearlyIncome: payload.yearlyIncome || null,
    specialRemarks: payload.specialRemarks || null,
    avatarUrl: payload.avatarUrl || null,
    fatherId: payload.fatherId || null,
    motherId: payload.motherId || null,
    spouseId: payload.spouseId || null,
    createdBy: sessionUserId,
    status: 'pending', // Starts as pending validation
  }).returning();

  // If a spouseId is provided, we should also update the target spouse's record to point back to this new member
  if (payload.spouseId && newMember.id) {
    await db.update(familyMembers)
      .set({ 
        spouseId: newMember.id,
        maritalStatus: 'married',
        anniversaryDate: anniversaryDateParsed,
      })
      .where(eq(familyMembers.id, payload.spouseId));
  }

  // Create business profile if requested
  if (payload.businessProfile && newMember.id) {
    const bp = payload.businessProfile;
    const [newBp] = await db.insert(businessProfiles).values({
      businessName: bp.businessName,
      logoUrl: null,
      industryCategory: bp.industryCategory,
      contactMobile: bp.contactMobile,
      whatsappMobile: bp.whatsappMobile || null,
      email: bp.email || null,
      websiteUrl: bp.websiteUrl || null,
      gstin: bp.gstin || null,
      description: bp.description || null,
      tags: bp.tags || null,
      operatingHours: bp.operatingHours || null,
      communityPerk: bp.communityPerk || null,
      catalog: bp.catalog || null,
      createdBy: sessionUserId,
      isApproved: false,
    }).returning();

    if (newBp && newBp.id) {
      // 1. Link member to business
      await db.insert(businessMembers).values({
        businessId: newBp.id,
        memberId: newMember.id,
        roleInBusiness: 'Owner',
      });

      // 2. Add primary location
      await db.insert(businessLocations).values({
        businessId: newBp.id,
        branchName: 'Main Branch',
        address: bp.address,
        city: bp.city,
        state: bp.state || null,
        pincode: bp.pincode || null,
        googleMapsLink: bp.googleMapsLink || null,
        isPrimary: true,
      });
    }
  }

  return newMember;
}

/**
 * Get family unit and all its member nodes
 */
export async function getFamilyTreeData(familyId: number, currentUserId: string) {
  // 1. Fetch family record — flat query, avoids double-nested lateral join
  const familyRaw = await dbRetry(() => db.query.families.findFirst({
    where: eq(families.id, familyId),
  }));

  if (!familyRaw) return null;

  // 1b. Separately fetch village + region (avoids nested lateral join)
  let villageWithRegion: any = null;
  if (familyRaw.villageId) {
    const villageRaw = await dbRetry(() => db.query.villages.findFirst({
      where: eq(villages.id, familyRaw.villageId!),
      with: { region: true },
    }));
    villageWithRegion = villageRaw ?? null;
  }

  const family: any = { ...familyRaw, village: villageWithRegion };

  // 2. Fetch family members
  const members = await dbRetry(() => db.select().from(familyMembers).where(eq(familyMembers.familyId, familyId)));

  // 3. Filter members based on authorization status
  // Policy: Members of the SAME family or Admins/Moderators can see pending nodes.
  // Others can only see approved nodes.
  const userRec = await dbRetry(() => db.query.users.findFirst({
    where: eq(users.id, currentUserId),
  }));
  const isAdminOrMod = userRec?.role === 'admin' || userRec?.role === 'moderator';
  const isMemberOfFamily = members.some((m: any) => m.userId === currentUserId || m.createdBy === currentUserId);

  const filteredMembers = (isMemberOfFamily || isAdminOrMod)
    ? members
    : members.filter((m: any) => m.status === 'approved');

  let membersWithBiz = filteredMembers.map((m: any) => ({ ...m, businessProfile: null }));

  try {
    const memberIds = filteredMembers.map((m: any) => m.id);
    if (memberIds.length > 0) {
      const bizLinks = await dbRetry(() => db.select().from(businessMembers).where(inArray(businessMembers.memberId, memberIds)));

      if (bizLinks.length > 0) {
        const bizIds = Array.from(new Set(bizLinks.map((b: any) => b.businessId)));

        const [profiles, locations] = await Promise.all([
          dbRetry(() => db.select().from(businessProfiles).where(inArray(businessProfiles.id, bizIds))),
          dbRetry(() => db.select().from(businessLocations).where(
            and(
              inArray(businessLocations.businessId, bizIds),
              eq(businessLocations.isPrimary, true)
            )
          )),
        ]);

        const profileMap = new Map(profiles.map((p: any) => [p.id, p]));
        const locationMap = new Map(locations.map((l: any) => [l.businessId, l]));
        const memberBizMap = new Map(bizLinks.map((b: any) => [b.memberId, b.businessId]));

        membersWithBiz = filteredMembers.map((m: any) => {
          const bizId = memberBizMap.get(m.id);
          let businessProfile: any = null;
          if (bizId) {
            const bp = profileMap.get(bizId);
            if (bp) {
              const loc = locationMap.get(bp.id);
              businessProfile = {
                ...bp,
                address: loc?.address || '',
                city: loc?.city || '',
                state: loc?.state || '',
                pincode: loc?.pincode || '',
                googleMapsLink: loc?.googleMapsLink || '',
              };
            }
          }
          return { ...m, businessProfile };
        });
      }
    }
  } catch (err) {
    console.error('Error fetching business profiles for family tree:', err);
    // Fallback: return members without business profile if DB glitch occurs
  }

  const myMemberInFamily = members.find((m: any) => m.userId === currentUserId || m.createdBy === currentUserId);
  const canEdit = myMemberInFamily
    ? (myMemberInFamily.createdBy === currentUserId ||
       myMemberInFamily.relationshipToHead === 'self' ||
       family.familyHeadId === myMemberInFamily.id)
    : false;

  return { family, members: membersWithBiz, canEdit };
}

/**
 * Get the family that belongs to the logged-in user (where they are a member with userId set)
 */
export async function getMyFamily(sessionUserId: string) {
  // Find a member node where userId == sessionUserId
  let myMember = await dbRetry(() => db.query.familyMembers.findFirst({
    where: (m: any, { eq }: any) => eq(m.userId, sessionUserId),
  }));

  // If not found by userId directly, check if sessionUserId created any member
  if (!myMember) {
    myMember = await dbRetry(() => db.query.familyMembers.findFirst({
      where: (m: any, { eq }: any) => eq(m.createdBy, sessionUserId),
    }));
  }

  if (!myMember) return null;

  // Fetch the family (flat query + separate village fetch to avoid nested lateral join)
  const familyRaw = await dbRetry(() => db.query.families.findFirst({
    where: (f: any, { eq }: any) => eq(f.id, myMember!.familyId),
  }));

  let villageWithRegion: any = null;
  if (familyRaw?.villageId) {
    const villageRaw = await dbRetry(() => db.query.villages.findFirst({
      where: eq(villages.id, familyRaw.villageId!),
      with: { region: true },
    }));
    villageWithRegion = villageRaw ?? null;
  }

  const family: any = familyRaw ? { ...familyRaw, village: villageWithRegion } : null;

  let businessProfile: any = null;
  const bizLink = await dbRetry(() => db.query.businessMembers.findFirst({
    where: eq(businessMembers.memberId, myMember!.id),
  }));
  if (bizLink) {
    const bp = await dbRetry(() => db.query.businessProfiles.findFirst({
      where: eq(businessProfiles.id, bizLink.businessId),
    }));
    if (bp) {
      const loc = await dbRetry(() => db.query.businessLocations.findFirst({
        where: and(
          eq(businessLocations.businessId, bp.id),
          eq(businessLocations.isPrimary, true)
        ),
      }));
      businessProfile = {
        ...bp,
        address: loc?.address || '',
        city: loc?.city || '',
        state: loc?.state || '',
        pincode: loc?.pincode || '',
        googleMapsLink: loc?.googleMapsLink || '',
      };
    }
  }

  const memberWithBiz = { ...myMember, businessProfile };

  const isHeadOrCreator =
    myMember.createdBy === sessionUserId ||
    myMember.relationshipToHead === 'self' ||
    family?.familyHeadId === myMember.id;

  return family ? { family, member: memberWithBiz, canEdit: isHeadOrCreator } : null;
}

/**
 * Update details of a family member node
 */
export async function updateFamilyMember(sessionUserId: string, memberId: number, payload: any) {
  // 1. Fetch the target member
  const member = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, memberId),
  });

  if (!member) throw new Error('Member not found');

  // 2. Fetch all members of this family to check authorization
  const familyMems = await db.select().from(familyMembers).where(eq(familyMembers.familyId, member.familyId));
  const isAuthorized = familyMems.some((m: any) => m.userId === sessionUserId || m.createdBy === sessionUserId);

  if (!isAuthorized) throw new Error('Unauthorized');

  // Check mobile uniqueness if updating mobile
  if (payload.mobile && payload.mobile.trim().length > 0) {
    const existingMobile = await db.query.familyMembers.findFirst({
      where: and(
        eq(familyMembers.mobile, payload.mobile.trim()),
        sql`${familyMembers.id} != ${memberId}`
      ),
    });
    if (existingMobile) {
      throw new Error('This mobile number is already registered with another family member.');
    }
  }

  // 3. Update the member record
  const birthDateParsed = payload.birthDate ? new Date(payload.birthDate) : undefined;
  let estimatedBirthYear: number | undefined = undefined;
  if (payload.estimatedAgeOnCreation !== undefined) {
    if (payload.estimatedAgeOnCreation === null) {
      estimatedBirthYear = null as any;
    } else {
      const currentYear = new Date().getFullYear();
      estimatedBirthYear = currentYear - payload.estimatedAgeOnCreation;
    }
  }

  const anniversaryDateParsed = payload.anniversaryDate !== undefined 
    ? (payload.anniversaryDate ? new Date(payload.anniversaryDate) : null) 
    : undefined;

  const isFamilyApproved = familyMems.some((m: any) => m.status === 'approved');
  const targetStatus = (isFamilyApproved || member.status === 'approved') ? 'approved' : 'pending';

  const [updatedMember] = await db.update(familyMembers).set({
    fullName: payload.fullName,
    gender: payload.gender,
    relationshipToHead: payload.relationshipToHead,
    birthDate: birthDateParsed !== undefined ? birthDateParsed : undefined,
    estimatedAgeOnCreation: payload.estimatedAgeOnCreation,
    estimatedBirthYear,
    mobile: payload.mobile,
    whatsappMobile: payload.whatsappMobile,
    email: payload.email,
    bloodGroup: payload.bloodGroup,
    gotra: payload.gotra,
    maritalStatus: payload.maritalStatus,
    anniversaryDate: anniversaryDateParsed,
    currentAddress: payload.currentAddress,
    currentCity: payload.currentCity,
    currentState: payload.currentState,
    currentPincode: payload.currentPincode,
    education: payload.education,
    occupationType: payload.occupationType,
    occupationDetail: payload.occupationDetail,
    yearlyIncome: payload.yearlyIncome,
    specialRemarks: payload.specialRemarks,
    avatarUrl: payload.avatarUrl,
    fatherId: payload.fatherId,
    motherId: payload.motherId,
    spouseId: payload.spouseId,
    status: targetStatus,
    validationFeedback: targetStatus === 'pending' ? null : member.validationFeedback,
  }).where(eq(familyMembers.id, memberId)).returning();

  // Bi-directional Sync: Update linked user profile avatar if member is linked to a user account
  if (updatedMember.userId && payload.avatarUrl !== undefined) {
    try {
      await db.update(users)
        .set({ avatarUrl: updatedMember.avatarUrl, updatedAt: new Date() })
        .where(eq(users.id, updatedMember.userId));
    } catch (err) {
      console.error('Error syncing family member avatar to user profile:', err);
    }
  }

  // If a spouseId is provided and was updated, we should update the target spouse
  if (payload.spouseId && updatedMember.id) {
    await db.update(familyMembers)
      .set({ 
        spouseId: updatedMember.id,
        maritalStatus: 'married',
        anniversaryDate: updatedMember.anniversaryDate
      })
      .where(eq(familyMembers.id, payload.spouseId));
  } else if (updatedMember.spouseId) {
    // If not spouseId update, but the member is married and has a spouseId, sync changes
    await db.update(familyMembers)
      .set({ 
        maritalStatus: updatedMember.maritalStatus,
        anniversaryDate: updatedMember.anniversaryDate
      })
      .where(eq(familyMembers.id, updatedMember.spouseId));
  }

  // Update or Create business profile if requested
  if (payload.businessProfile && updatedMember.id) {
    const bp = payload.businessProfile;
    // Check if member already has a business profile linked
    const existingMembership = await db.query.businessMembers.findFirst({
      where: eq(businessMembers.memberId, updatedMember.id),
    });

    if (existingMembership) {
      // Update existing business profile
      await db.update(businessProfiles).set({
        businessName: bp.businessName,
        industryCategory: bp.industryCategory,
        contactMobile: bp.contactMobile,
        whatsappMobile: bp.whatsappMobile || null,
        email: bp.email || null,
        websiteUrl: bp.websiteUrl || null,
        gstin: bp.gstin || null,
        description: bp.description || null,
        tags: bp.tags || null,
        operatingHours: bp.operatingHours || null,
        communityPerk: bp.communityPerk || null,
        catalog: bp.catalog || null,
        updatedAt: new Date(),
      }).where(eq(businessProfiles.id, existingMembership.businessId));

      // Update primary location
      const primaryLoc = await db.query.businessLocations.findFirst({
        where: and(
          eq(businessLocations.businessId, existingMembership.businessId),
          eq(businessLocations.isPrimary, true)
        ),
      });

      if (primaryLoc) {
        await db.update(businessLocations).set({
          address: bp.address,
          city: bp.city,
          state: bp.state || null,
          pincode: bp.pincode || null,
          googleMapsLink: bp.googleMapsLink || null,
          updatedAt: new Date(),
        }).where(eq(businessLocations.id, primaryLoc.id));
      } else {
        // Create new primary location if somehow missing
        await db.insert(businessLocations).values({
          businessId: existingMembership.businessId,
          branchName: 'Main Branch',
          address: bp.address,
          city: bp.city,
          state: bp.state || null,
          pincode: bp.pincode || null,
          googleMapsLink: bp.googleMapsLink || null,
          isPrimary: true,
        });
      }
    } else {
      // Create new business profile
      const [newBp] = await db.insert(businessProfiles).values({
        businessName: bp.businessName,
        logoUrl: null,
        industryCategory: bp.industryCategory,
        contactMobile: bp.contactMobile,
        whatsappMobile: bp.whatsappMobile || null,
        email: bp.email || null,
        websiteUrl: bp.websiteUrl || null,
        gstin: bp.gstin || null,
        description: bp.description || null,
        tags: bp.tags || null,
        operatingHours: bp.operatingHours || null,
        communityPerk: bp.communityPerk || null,
        catalog: bp.catalog || null,
        createdBy: sessionUserId,
        isApproved: updatedMember.status === 'approved',
      }).returning();

      if (newBp && newBp.id) {
        await db.insert(businessMembers).values({
          businessId: newBp.id,
          memberId: updatedMember.id,
          roleInBusiness: 'Owner',
        });

        await db.insert(businessLocations).values({
          businessId: newBp.id,
          branchName: 'Main Branch',
          address: bp.address,
          city: bp.city,
          state: bp.state || null,
          pincode: bp.pincode || null,
          googleMapsLink: bp.googleMapsLink || null,
          isPrimary: true,
        });
      }
    }
  }

  return updatedMember;
}

/**
 * Delete a family member node and clean up references
 */
export async function deleteFamilyMember(sessionUserId: string, memberId: number) {
  // 1. Fetch target member
  const member = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, memberId),
  });

  if (!member) throw new Error('Member not found');

  // 2. Fetch all members of this family to check authorization
  const familyMems = await db.select().from(familyMembers).where(eq(familyMembers.familyId, member.familyId));
  const isAuthorized = familyMems.some((m: any) => m.userId === sessionUserId || m.createdBy === sessionUserId);

  if (!isAuthorized) throw new Error('Unauthorized');

  // 3. Delete the member record
  await db.delete(familyMembers).where(eq(familyMembers.id, memberId));

  // 4. Clean up any references pointing to this member
  await db.update(familyMembers).set({ spouseId: null }).where(eq(familyMembers.spouseId, memberId));
  await db.update(familyMembers).set({ fatherId: null }).where(eq(familyMembers.fatherId, memberId));
  await db.update(familyMembers).set({ motherId: null }).where(eq(familyMembers.motherId, memberId));

  return { success: true };
}

/**
 * Helper to check moderator region permission
 */
async function checkModeratorAreaPermission(moderatorId: string, familyId: number) {
  const modUser = await db.query.users.findFirst({ where: eq(users.id, moderatorId) });
  if (!modUser) return;
  if (modUser.role === 'admin') return;
  if (modUser.role === 'moderator') {
    const userRegions = await db.select({ regionId: coordinatorRegions.regionId })
      .from(coordinatorRegions)
      .where(eq(coordinatorRegions.userId, moderatorId));
    const assignedRegionIds = userRegions.map((r: any) => r.regionId);

    const fam = await db.query.families.findFirst({
      where: eq(families.id, familyId),
      with: { village: true }
    });
    if (!fam || !fam.village?.regionId || !assignedRegionIds.includes(fam.village.regionId)) {
      throw new Error('Unauthorized: You can only moderate family members in your assigned area/zone');
    }
  }
}

/**
 * Get all pending family members for moderation
 */
export async function getPendingFamilyMembers(sessionUser?: any) {
  let assignedRegionIds: number[] | null = null;
  if (sessionUser && sessionUser.role === 'moderator') {
    const userRegions = await db
      .select({ regionId: coordinatorRegions.regionId })
      .from(coordinatorRegions)
      .where(eq(coordinatorRegions.userId, sessionUser.id));
    assignedRegionIds = userRegions.map((r: any) => r.regionId);
    if (assignedRegionIds.length === 0) {
      return [];
    }
  }

  const rows = await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    gender: familyMembers.gender,
    relationshipToHead: familyMembers.relationshipToHead,
    mobile: familyMembers.mobile,
    gotra: familyMembers.gotra,
    estimatedAgeOnCreation: familyMembers.estimatedAgeOnCreation,
    birthDate: familyMembers.birthDate,
    education: familyMembers.education,
    occupationType: familyMembers.occupationType,
    occupationDetail: familyMembers.occupationDetail,
    yearlyIncome: familyMembers.yearlyIncome,
    fatherId: familyMembers.fatherId,
    motherId: familyMembers.motherId,
    spouseId: familyMembers.spouseId,
    status: familyMembers.status,
    bloodGroup: familyMembers.bloodGroup,
    maritalStatus: familyMembers.maritalStatus,
    anniversaryDate: familyMembers.anniversaryDate,
    currentAddress: familyMembers.currentAddress,
    currentCity: familyMembers.currentCity,
    currentState: familyMembers.currentState,
    currentPincode: familyMembers.currentPincode,
    avatarUrl: familyMembers.avatarUrl,
    specialRemarks: familyMembers.specialRemarks,
    createdBy: familyMembers.createdBy,
    createdAt: familyMembers.createdAt,
    familyId: familyMembers.familyId,
    familyCode: families.familyCode,
    address: families.address,
    regionId: villages.regionId,
  })
  .from(familyMembers)
  .innerJoin(families, eq(familyMembers.familyId, families.id))
  .leftJoin(villages, eq(families.villageId, villages.id))
  .where(eq(familyMembers.status, 'pending'));

  if (assignedRegionIds !== null) {
    return rows.filter((r: any) => r.regionId && assignedRegionIds!.includes(r.regionId));
  }
  return rows;
}

/**
 * Approve a pending family member
 */
export async function approveFamilyMember(memberId: number, moderatorId: string) {
  const member = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, memberId),
  });
  if (!member) throw new Error('Member not found');

  await checkModeratorAreaPermission(moderatorId, member.familyId);

  await db.update(familyMembers)
    .set({
      status: 'approved',
      validatedBy: moderatorId,
      validatedAt: new Date(),
    })
    .where(eq(familyMembers.id, memberId));

  // Automatically approve any business profiles owned/linked by this family member
  try {
    const memberships = await db.query.businessMembers.findMany({
      where: eq(businessMembers.memberId, memberId),
    });
    for (const m of memberships) {
      await db.update(businessProfiles)
        .set({ isApproved: true, updatedAt: new Date() })
        .where(eq(businessProfiles.id, m.businessId));
    }
  } catch (err) {
    console.error('Failed to auto-approve associated business profiles:', err);
  }

  try {
    const devicesList = await getUserDevices(member.createdBy);
    if (devicesList.length > 0) {
      const tokens = devicesList.map((d: any) => d.fcmToken);
      await sendPushNotification(
        tokens,
        'Member Approved / सदस्य स्वीकृत',
        `${member.fullName} has been approved and is now visible on the family tree.`,
        { memberId: memberId.toString(), status: 'approved' }
      );
    }
  } catch (err) {
    console.error('Failed to send approval notification:', err);
  }

  return { success: true };
}

/**
 * Reject a pending family member
 */
export async function rejectFamilyMember(memberId: number, moderatorId: string, reason?: string) {
  const member = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, memberId),
  });
  if (!member) throw new Error('Member not found');

  await checkModeratorAreaPermission(moderatorId, member.familyId);

  try {
    const devicesList = await getUserDevices(member.createdBy);
    if (devicesList.length > 0) {
      const tokens = devicesList.map((d: any) => d.fcmToken);
      await sendPushNotification(
        tokens,
        'Request Rejected / अनुरोध अस्वीकृत',
        `The request for ${member.fullName} was rejected.${reason ? ` Reason: ${reason}` : ''}`,
        { memberId: memberId.toString(), status: 'rejected' }
      );
    }
  } catch (err) {
    console.error('Failed to send rejection notification:', err);
  }

  await db.update(familyMembers)
    .set({
      status: 'rejected',
      validationFeedback: reason || null,
      validatedBy: moderatorId,
      validatedAt: new Date(),
    })
    .where(eq(familyMembers.id, memberId));

  return { success: true };
}

/**
 * Get all pending families (families with at least 1 pending or rejected member)
 */
export async function getPendingFamilies(sessionUser?: any) {
  let assignedRegionIds: number[] | null = null;
  if (sessionUser && sessionUser.role === 'moderator') {
    const userRegions = await db
      .select({ regionId: coordinatorRegions.regionId })
      .from(coordinatorRegions)
      .where(eq(coordinatorRegions.userId, sessionUser.id));
    assignedRegionIds = userRegions.map((r: any) => r.regionId);
    if (assignedRegionIds.length === 0) return [];
  }

  // 1. Find all familyIds that have members with status 'pending' or 'rejected'
  const pendingMemberRows = await db
    .select({ familyId: familyMembers.familyId })
    .from(familyMembers)
    .where(inArray(familyMembers.status, ['pending', 'rejected']));

  const familyIds = Array.from(new Set(pendingMemberRows.map((r: any) => r.familyId)));
  if (familyIds.length === 0) return [];

  // 2. Fetch families with village and region details
  const familyList = await db.query.families.findMany({
    where: inArray(families.id, familyIds),
    with: {
      village: {
        with: {
          region: true,
        },
      },
      members: true,
    },
  });

  const filteredFamilyList = assignedRegionIds !== null
    ? familyList.filter((fam: any) => fam.village?.regionId && assignedRegionIds!.includes(fam.village.regionId))
    : familyList;

  // Map to structured output
  return filteredFamilyList.map((fam: any) => {
    const head = fam.members.find((m: any) => m.relationshipToHead === 'self' || m.id === fam.familyHeadId) || fam.members[0];
    const pendingCount = fam.members.filter((m: any) => m.status === 'pending').length;
    const rejectedCount = fam.members.filter((m: any) => m.status === 'rejected').length;
    const approvedCount = fam.members.filter((m: any) => m.status === 'approved').length;

    return {
      familyId: fam.id,
      familyCode: fam.familyCode,
      address: fam.address,
      city: fam.city,
      state: fam.state,
      pincode: fam.pincode,
      villageName: fam.village?.name || '',
      regionName: fam.village?.region?.name || '',
      headName: head?.fullName || 'Unknown',
      headMobile: head?.mobile || null,
      totalMembers: fam.members.length,
      pendingCount,
      rejectedCount,
      approvedCount,
      members: fam.members,
    };
  });
}

/**
 * Approve an entire family (all non-approved members of the family)
 */
export async function approveEntireFamily(familyId: number, moderatorId: string) {
  const members = await db.select().from(familyMembers).where(eq(familyMembers.familyId, familyId));
  if (members.length === 0) throw new Error('Family not found or has no members');

  await checkModeratorAreaPermission(moderatorId, familyId);

  await db.update(familyMembers)
    .set({
      status: 'approved',
      validationFeedback: null,
      validatedBy: moderatorId,
      validatedAt: new Date(),
    })
    .where(eq(familyMembers.familyId, familyId));

  // Automatically approve any business profiles owned/linked by these family members
  try {
    const memberIds = members.map((m: any) => m.id);
    if (memberIds.length > 0) {
      const memberships = await db.select().from(businessMembers).where(inArray(businessMembers.memberId, memberIds));
      for (const m of memberships) {
        await db.update(businessProfiles)
          .set({ isApproved: true, updatedAt: new Date() })
          .where(eq(businessProfiles.id, m.businessId));
      }
    }
  } catch (err) {
    console.error('Failed to auto-approve associated business profiles for family:', err);
  }

  // Push notifications to creator(s)
  try {
    const creatorIds = Array.from(new Set(members.map((m: any) => m.createdBy)));
    for (const creatorId of creatorIds) {
      const devicesList = await getUserDevices(creatorId);
      if (devicesList.length > 0) {
        const tokens = devicesList.map((d: any) => d.fcmToken);
        await sendPushNotification(
          tokens,
          'Family Approved / परिवार स्वीकृत',
          `Your family tree members have been approved and are now visible on the directory.`,
          { familyId: familyId.toString(), status: 'approved' }
        );
      }
    }
  } catch (err) {
    console.error('Failed to send family approval notification:', err);
  }

  return { success: true };
}

/**
 * Reject an entire family (or pending members of the family) with a reason
 */
export async function rejectEntireFamily(familyId: number, moderatorId: string, reason?: string) {
  const members = await db.select().from(familyMembers).where(eq(familyMembers.familyId, familyId));
  if (members.length === 0) throw new Error('Family not found or has no members');

  await checkModeratorAreaPermission(moderatorId, familyId);

  await db.update(familyMembers)
    .set({
      status: 'rejected',
      validationFeedback: reason || null,
      validatedBy: moderatorId,
      validatedAt: new Date(),
    })
    .where(and(eq(familyMembers.familyId, familyId), sql`${familyMembers.status} != 'approved'`));

  // Push notifications to creator(s)
  try {
    const creatorIds = Array.from(new Set(members.map((m: any) => m.createdBy)));
    for (const creatorId of creatorIds) {
      const devicesList = await getUserDevices(creatorId);
      if (devicesList.length > 0) {
        const tokens = devicesList.map((d: any) => d.fcmToken);
        await sendPushNotification(
          tokens,
          'Family Approval Update / परिवार अपडेट',
          `Your family registration needs updates.${reason ? ` Reason: ${reason}` : ''}`,
          { familyId: familyId.toString(), status: 'rejected', reason: reason || '' }
        );
      }
    }
  } catch (err) {
    console.error('Failed to send family rejection notification:', err);
  }

  return { success: true };
}

/**
 * Get all pending business profiles for moderation
 */
export async function getPendingBusinessProfiles() {
  return await db.select({
    id: businessProfiles.id,
    businessName: businessProfiles.businessName,
    industryCategory: businessProfiles.industryCategory,
    contactMobile: businessProfiles.contactMobile,
    email: businessProfiles.email,
    websiteUrl: businessProfiles.websiteUrl,
    description: businessProfiles.description,
    createdAt: businessProfiles.createdAt,
    locationAddress: businessLocations.address,
    locationCity: businessLocations.city,
    locationState: businessLocations.state,
    locationPincode: businessLocations.pincode,
    ownerName: familyMembers.fullName,
    ownerId: familyMembers.id,
  })
  .from(businessProfiles)
  .leftJoin(businessLocations, and(
    eq(businessLocations.businessId, businessProfiles.id),
    eq(businessLocations.isPrimary, true)
  ))
  .leftJoin(businessMembers, eq(businessMembers.businessId, businessProfiles.id))
  .leftJoin(familyMembers, eq(familyMembers.id, businessMembers.memberId))
  .where(eq(businessProfiles.isApproved, false))
  .orderBy(businessProfiles.createdAt);
}

/**
 * Approve a pending business profile
 */
export async function approveBusinessProfile(businessId: number, moderatorId: string) {
  const biz = await db.query.businessProfiles.findFirst({
    where: eq(businessProfiles.id, businessId),
  });
  if (!biz) throw new Error('Business profile not found');

  await db.update(businessProfiles)
    .set({
      isApproved: true,
      updatedAt: new Date(),
    })
    .where(eq(businessProfiles.id, businessId));

  // Try to send push notification to creator
  try {
    const devicesList = await getUserDevices(biz.createdBy);
    if (devicesList.length > 0) {
      const tokens = devicesList.map((d: any) => d.fcmToken);
      await sendPushNotification(
        tokens,
        'Business Approved / व्यवसाय स्वीकृत',
        `${biz.businessName} has been approved and is now visible in the business directory.`,
        { businessId: businessId.toString(), status: 'approved' }
      );
    }
  } catch (err) {
    console.error('Failed to send business approval notification:', err);
  }

  return { success: true };
}

/**
 * Reject a pending business profile
 */
export async function rejectBusinessProfile(businessId: number, moderatorId: string) {
  const biz = await db.query.businessProfiles.findFirst({
    where: eq(businessProfiles.id, businessId),
  });
  if (!biz) throw new Error('Business profile not found');

  await db.delete(businessProfiles).where(eq(businessProfiles.id, businessId));

  // Try to send push notification to creator
  try {
    const devicesList = await getUserDevices(biz.createdBy);
    if (devicesList.length > 0) {
      const tokens = devicesList.map((d: any) => d.fcmToken);
      await sendPushNotification(
        tokens,
        'Business Rejected / व्यवसाय अस्वीकृत',
        `The request for ${biz.businessName} was rejected.`,
        { businessId: businessId.toString(), status: 'rejected' }
      );
    }
  } catch (err) {
    console.error('Failed to send business rejection notification:', err);
  }

  return { success: true };
}


/**
 * Search approved family members across any family by name
 */
export async function searchFamilyMembers(queryStr: string) {
  return await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    gender: familyMembers.gender,
    relationshipToHead: familyMembers.relationshipToHead,
    avatarUrl: familyMembers.avatarUrl,
    familyId: familyMembers.familyId,
  })
  .from(familyMembers)
  .where(
    and(
      eq(familyMembers.status, 'approved'),
      sql`${familyMembers.fullName} ILIKE ${'%' + queryStr + '%'}`
    )
  )
  .limit(20);
}

/**
 * List all members assigned to a business profile
 */
export async function getBusinessMembersList(businessId: number) {
  return await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    gender: familyMembers.gender,
    relationshipToHead: familyMembers.relationshipToHead,
    avatarUrl: familyMembers.avatarUrl,
    familyId: familyMembers.familyId,
    roleInBusiness: businessMembers.roleInBusiness,
  })
  .from(businessMembers)
  .innerJoin(familyMembers, eq(businessMembers.memberId, familyMembers.id))
  .where(eq(businessMembers.businessId, businessId));
}

/**
 * Get eligible family members for a business profile (Business Owner / Family Head / Family Members)
 */
export async function getBusinessEligiblePartners(businessId: number) {
  const bizMembers = await db.query.businessMembers.findMany({
    where: eq(businessMembers.businessId, businessId),
    with: { member: true }
  });

  const existingMemberIds = new Set(bizMembers.map(bm => bm.memberId));
  const familyIds = new Set<number>();

  for (const bm of bizMembers) {
    if (bm.member?.familyId) {
      familyIds.add(bm.member.familyId);
    }
  }

  if (familyIds.size === 0) {
    return [];
  }

  const eligible = await db.query.familyMembers.findMany({
    where: and(
      inArray(familyMembers.familyId, Array.from(familyIds)),
      eq(familyMembers.status, 'approved')
    ),
    with: {
      family: true
    }
  });

  return eligible.filter(m => !existingMemberIds.has(m.id));
}

/**
 * Link a family member to a business profile
 */
export async function addMemberToBusiness(sessionUserId: string, businessId: number, targetMemberId: number, role: string) {
  // Check if business exists
  const biz = await db.query.businessProfiles.findFirst({
    where: eq(businessProfiles.id, businessId),
  });
  if (!biz) throw new Error('Business not found');

  const sessionUserRecord = await db.query.users.findFirst({ where: eq(users.id, sessionUserId) });
  const isAdminOrMod = sessionUserRecord?.role === 'admin' || sessionUserRecord?.role === 'moderator';

  // Get current business members
  const existingBizMembers = await db.query.businessMembers.findMany({
    where: eq(businessMembers.businessId, businessId),
    with: { member: true }
  });

  const familyIds = new Set<number>();
  for (const bm of existingBizMembers) {
    if (bm.member?.familyId) {
      familyIds.add(bm.member.familyId);
    }
  }

  const targetMember = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, targetMemberId)
  });
  if (!targetMember) throw new Error('Target member not found');

  if (!isAdminOrMod && familyIds.size > 0 && !familyIds.has(targetMember.familyId)) {
    throw new Error('Only family members or family head of the business owner can be added as partners.');
  }

  // Insert link
  const [newLink] = await db.insert(businessMembers).values({
    businessId,
    memberId: targetMemberId,
    roleInBusiness: role,
  }).returning();

  return newLink;
}

/**
 * Unlink a family member from a business profile
 */
export async function removeMemberFromBusiness(sessionUserId: string, businessId: number, targetMemberId: number) {
  // Check if business exists
  const biz = await db.query.businessProfiles.findFirst({
    where: eq(businessProfiles.id, businessId),
  });
  if (!biz) throw new Error('Business not found');

  // Delete relationship
  await db.delete(businessMembers).where(
    and(
      eq(businessMembers.businessId, businessId),
      eq(businessMembers.memberId, targetMemberId)
    )
  );

  return { success: true };
}

/**
 * Get all approved community members with search and filter
 */
export async function getMembersList(search?: string, villageId?: number) {
  const allMembers = await db.query.familyMembers.findMany({
    where: eq(familyMembers.status, 'approved'),
    with: {
      family: {
        with: {
          village: {
            with: {
              region: true,
            }
          },
          head: true,
        }
      }
    }
  });

  let filtered = allMembers;
  if (villageId) {
    filtered = filtered.filter(m => m.family?.villageId === villageId);
  }

  if (search && search.trim().length > 0) {
    const q = search.toLowerCase().trim();
    filtered = filtered.filter(m => {
      const name = m.fullName.toLowerCase();
      const gotra = m.gotra?.toLowerCase() || '';
      const village = m.family?.village?.name.toLowerCase() || '';
      const city = m.family?.city?.toLowerCase() || '';
      const code = m.family?.familyCode.toLowerCase() || '';
      const headName = m.family?.head?.fullName.toLowerCase() || '';
      return name.includes(q) || gotra.includes(q) || village.includes(q) || city.includes(q) || code.includes(q) || headName.includes(q);
    });
  }

  filtered.sort((a, b) => a.fullName.localeCompare(b.fullName, undefined, { sensitivity: 'base' }));

  return filtered.map(m => ({
    id: m.id,
    fullName: m.fullName,
    avatarUrl: m.avatarUrl,
    occupationType: m.occupationType,
    occupationDetail: m.occupationDetail,
    gotra: m.gotra,
    mobile: m.mobile,
    gender: m.gender,
    relationshipToHead: m.relationshipToHead,
    familyId: m.familyId,
    familyCode: m.family?.familyCode || '',
    village: m.family?.village || null,
    city: m.family?.city || null,
    familyHeadName: m.family?.head?.fullName || '',
    isHead: m.family?.familyHeadId === m.id || m.relationshipToHead === 'self',
  }));
}

/**
 * Get all approved business profiles with primary location and owner details
 */
export async function getBusinessProfilesList(search?: string, category?: string) {
  const allBusinesses = await db.query.businessProfiles.findMany({
    where: eq(businessProfiles.isApproved, true),
    orderBy: (bp: any, { desc }: any) => [desc(bp.createdAt)],
  });

  if (allBusinesses.length === 0) return [];

  const bizIds = allBusinesses.map(bp => bp.id);

  const [locations, bizMembers] = await Promise.all([
    db.select().from(businessLocations).where(
      and(
        inArray(businessLocations.businessId, bizIds),
        eq(businessLocations.isPrimary, true)
      )
    ),
    db.query.businessMembers.findMany({
      where: inArray(businessMembers.businessId, bizIds),
      with: {
        member: true,
      },
    }),
  ]);

  const locationMap = new Map(locations.map(l => [l.businessId, l]));
  const ownersMap = new Map<number, any[]>();
  for (const bm of bizMembers) {
    if (!ownersMap.has(bm.businessId)) {
      ownersMap.set(bm.businessId, []);
    }
    ownersMap.get(bm.businessId)!.push({
      id: bm.member?.id,
      fullName: bm.member?.fullName,
      avatarUrl: bm.member?.avatarUrl,
      mobile: bm.member?.mobile,
      roleInBusiness: bm.roleInBusiness,
    });
  }

  const formattedBusinesses = allBusinesses.map((bp) => {
    const loc = locationMap.get(bp.id);
    const owners = ownersMap.get(bp.id) || [];

    return {
      id: bp.id,
      businessName: bp.businessName,
      logoUrl: bp.logoUrl,
      industryCategory: bp.industryCategory,
      contactMobile: bp.contactMobile,
      whatsappMobile: bp.whatsappMobile,
      email: bp.email,
      websiteUrl: bp.websiteUrl,
      gstin: bp.gstin,
      description: bp.description,
      tags: bp.tags,
      operatingHours: bp.operatingHours,
      communityPerk: bp.communityPerk,
      catalog: bp.catalog,
      address: loc?.address || '',
      city: loc?.city || '',
      state: loc?.state || '',
      pincode: loc?.pincode || '',
      googleMapsLink: loc?.googleMapsLink || '',
      owners,
    };
  });

  let filtered = formattedBusinesses;
  if (category && category.trim().length > 0 && category !== 'All') {
    filtered = filtered.filter(b => b.industryCategory.toLowerCase() === category.toLowerCase());
  }

  if (search && search.trim().length > 0) {
    const q = search.toLowerCase().trim();
    filtered = filtered.filter(b => {
      const name = b.businessName.toLowerCase();
      const cat = b.industryCategory.toLowerCase();
      const city = b.city.toLowerCase();
      const desc = (b.description || '').toLowerCase();
      const ownerNames = b.owners.map((o: any) => (o.fullName || '').toLowerCase()).join(' ');
      return name.includes(q) || cat.includes(q) || city.includes(q) || desc.includes(q) || ownerNames.includes(q);
    });
  }

  return filtered;
}

/**
 * Associate user with an existing family member record by matching mobile number
 */
export async function associateUserWithFamilyMemberByMobile(userId: string, mobile?: string | null) {
  if (!mobile) return;
  const cleanMobile = mobile.trim();
  if (!cleanMobile) return;

  const matchingMember = await db.query.familyMembers.findFirst({
    where: (m: any, { eq, and, isNull }: any) => and(eq(m.mobile, cleanMobile), isNull(m.userId)),
  });

  if (matchingMember) {
    const userRec = await db.query.users.findFirst({
      where: eq(users.id, userId),
    });

    const targetAvatar = userRec?.avatarUrl || matchingMember.avatarUrl;

    await db.update(familyMembers)
      .set({
        userId: userId,
        avatarUrl: targetAvatar || matchingMember.avatarUrl,
      })
      .where(eq(familyMembers.id, matchingMember.id));

    if (userRec && !userRec.avatarUrl && matchingMember.avatarUrl) {
      await db.update(users)
        .set({ avatarUrl: matchingMember.avatarUrl, updatedAt: new Date() })
        .where(eq(users.id, userId));
    }
  }
}


