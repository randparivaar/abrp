import { db } from '@/db';
import { families, familyMembers, villages, businessProfiles, businessMembers, businessLocations } from '@/db/schema';
import { eq, sql, and } from 'drizzle-orm';
import { OnboardFamilyRequest, AddFamilyMemberRequest } from '@/types/directory.types';
import { getUserDevices, sendPushNotification } from '@/services/notifications.service';

/**
 * Generate a unique family code (e.g. ABRP-10001)
 */
async function generateUniqueFamilyCode(tx: any): Promise<string> {
  const lastFamily = await tx.query.families.findFirst({
    orderBy: (f: any, { desc }: any) => [desc(f.id)],
  });
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
 * Onboard a new family (Atomic Transaction)
 */
export async function onboardNewFamily(sessionUserId: string, payload: OnboardFamilyRequest) {
  return await db.transaction(async (tx: any) => {
    // 1. Generate unique family code
    const familyCode = await generateUniqueFamilyCode(tx);

    // 2. Create the family record
    const [newFamily] = await tx.insert(families).values({
      familyCode,
      address: payload.family.address,
      city: payload.family.city || null,
      state: payload.family.state || null,
      pincode: payload.family.pincode || null,
      villageId: payload.family.villageId,
    }).returning();

    // 3. Create the Family Head
    const birthDateParsed = payload.head.birthDate ? new Date(payload.head.birthDate) : null;
    let estimatedBirthYear: number | null = null;
    if (payload.head.estimatedAgeOnCreation) {
      const currentYear = new Date().getFullYear();
      estimatedBirthYear = currentYear - payload.head.estimatedAgeOnCreation;
    }

    const [newHead] = await tx.insert(familyMembers).values({
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
    await tx.update(families)
      .set({ familyHeadId: newHead.id })
      .where(eq(families.id, newFamily.id));

    return {
      family: newFamily,
      head: newHead
    };
  });
}

/**
 * Add a member to a family unit
 */
export async function addMemberToFamily(sessionUserId: string, payload: AddFamilyMemberRequest) {
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
    aadhaarNo: payload.aadhaarNo || null,
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
  // 1. Fetch family record
  const family = await db.query.families.findFirst({
    where: eq(families.id, familyId),
    with: {
      village: {
        with: {
          region: true
        }
      }
    }
  });

  if (!family) return null;

  // 2. Fetch family members
  const members = await db.select().from(familyMembers).where(eq(familyMembers.familyId, familyId));

  // 3. Filter members based on authorization status
  // Policy: Members of the SAME family can see pending nodes.
  // Others can only see approved nodes.
  const isMemberOfFamily = members.some((m: any) => m.userId === currentUserId || m.createdBy === currentUserId);

  const filteredMembers = isMemberOfFamily 
    ? members 
    : members.filter((m: any) => m.status === 'approved');

  const membersWithBiz = await Promise.all(
    filteredMembers.map(async (m) => {
      const bizLink = await db.query.businessMembers.findFirst({
        where: eq(businessMembers.memberId, m.id),
      });
      let businessProfile: any = null;
      if (bizLink) {
        const bp = await db.query.businessProfiles.findFirst({
          where: eq(businessProfiles.id, bizLink.businessId),
        });
        if (bp) {
          const loc = await db.query.businessLocations.findFirst({
            where: and(
              eq(businessLocations.businessId, bp.id),
              eq(businessLocations.isPrimary, true)
            ),
          });
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
      return {
        ...m,
        businessProfile,
      };
    })
  );

  return {
    family,
    members: membersWithBiz
  };
}

/**
 * Get the family that belongs to the logged-in user (where they are a member with userId set)
 */
export async function getMyFamily(sessionUserId: string) {
  // Find a member node where userId == sessionUserId
  const myMember = await db.query.familyMembers.findFirst({
    where: (m: any, { eq }: any) => eq(m.userId, sessionUserId),
  });

  if (!myMember) return null;

  // Fetch the family
  const family = await db.query.families.findFirst({
    where: (f: any, { eq }: any) => eq(f.id, myMember.familyId),
    with: {
      village: {
        with: { region: true },
      },
    },
  });

  let businessProfile: any = null;
  const bizLink = await db.query.businessMembers.findFirst({
    where: eq(businessMembers.memberId, myMember.id),
  });
  if (bizLink) {
    const bp = await db.query.businessProfiles.findFirst({
      where: eq(businessProfiles.id, bizLink.businessId),
    });
    if (bp) {
      const loc = await db.query.businessLocations.findFirst({
        where: and(
          eq(businessLocations.businessId, bp.id),
          eq(businessLocations.isPrimary, true)
        ),
      });
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

  const memberWithBiz = {
    ...myMember,
    businessProfile,
  };

  return family ? { family, member: memberWithBiz } : null;
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
    aadhaarNo: payload.aadhaarNo,
    specialRemarks: payload.specialRemarks,
    avatarUrl: payload.avatarUrl,
    fatherId: payload.fatherId,
    motherId: payload.motherId,
    spouseId: payload.spouseId,
    status: 'pending', // Re-evaluate status on edits
  }).where(eq(familyMembers.id, memberId)).returning();

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
        isApproved: false,
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
 * Get all pending family members for moderation
 */
export async function getPendingFamilyMembers() {
  return await db.select({
    id: familyMembers.id,
    fullName: familyMembers.fullName,
    gender: familyMembers.gender,
    relationshipToHead: familyMembers.relationshipToHead,
    estimatedAgeOnCreation: familyMembers.estimatedAgeOnCreation,
    gotra: familyMembers.gotra,
    createdBy: familyMembers.createdBy,
    createdAt: familyMembers.createdAt,
    familyId: familyMembers.familyId,
    familyCode: families.familyCode,
    address: families.address,
  })
  .from(familyMembers)
  .innerJoin(families, eq(familyMembers.familyId, families.id))
  .where(eq(familyMembers.status, 'pending'));
}

/**
 * Approve a pending family member
 */
export async function approveFamilyMember(memberId: number, moderatorId: string) {
  const member = await db.query.familyMembers.findFirst({
    where: eq(familyMembers.id, memberId),
  });
  if (!member) throw new Error('Member not found');

  await db.update(familyMembers)
    .set({
      status: 'approved',
      validatedBy: moderatorId,
      validatedAt: new Date(),
    })
    .where(eq(familyMembers.id, memberId));

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

  await db.delete(familyMembers).where(eq(familyMembers.id, memberId));
  await db.update(familyMembers).set({ spouseId: null }).where(eq(familyMembers.spouseId, memberId));
  await db.update(familyMembers).set({ fatherId: null }).where(eq(familyMembers.fatherId, memberId));
  await db.update(familyMembers).set({ motherId: null }).where(eq(familyMembers.motherId, memberId));

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
 * Link a family member to a business profile
 */
export async function addMemberToBusiness(sessionUserId: string, businessId: number, targetMemberId: number, role: string) {
  // Check if business exists
  const biz = await db.query.businessProfiles.findFirst({
    where: eq(businessProfiles.id, businessId),
  });
  if (!biz) throw new Error('Business not found');

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
    familyHeadName: m.family?.head?.fullName || '',
  }));
}

