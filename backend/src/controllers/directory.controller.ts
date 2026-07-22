import { Context } from 'hono';
import { UserSession } from '@/middleware/auth';
import { 
  getVillagesList, 
  onboardNewFamily, 
  addMemberToFamily, 
  getFamilyTreeData,
  getMyFamily,
  updateFamilyMember,
  deleteFamilyMember,
  getPendingFamilyMembers,
  approveFamilyMember,
  rejectFamilyMember,
  getPendingBusinessProfiles,
  approveBusinessProfile,
  rejectBusinessProfile,
  searchFamilyMembers,
  getBusinessMembersList,
  addMemberToBusiness,
  removeMemberFromBusiness,
  getMembersList,
  getBusinessProfilesList
} from '@/services/directory.service';
import { OnboardFamilyRequest, AddFamilyMemberRequest } from '@/types/directory.types';

/**
 * Handle listing all villages
 */
export async function handleGetVillages(c: Context) {
  try {
    const villages = await getVillagesList();
    return c.json({ villages });
  } catch (error: any) {
    console.error('Error in handleGetVillages:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle onboarding family head + family unit
 */
export async function handleOnboardFamily(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const payload = await c.req.json<OnboardFamilyRequest>();

    // Basic Validation
    if (!payload.family || !payload.family.address || !payload.family.villageId) {
      return c.json({ error: 'Missing required family details (address and villageId).' }, 400);
    }
    if (!payload.head || !payload.head.fullName || !payload.head.gender) {
      return c.json({ error: 'Missing required family head details (fullName and gender).' }, 400);
    }

    const result = await onboardNewFamily(sessionUser.id, payload);
    return c.json(result, 201);
  } catch (error: any) {
    console.error('Error in handleOnboardFamily:', error);
    if (error.message?.includes('already created') || error.message?.includes('already registered')) {
      return c.json({ error: error.message }, 400);
    }
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle adding a family member node
 */
export async function handleAddFamilyMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const payload = await c.req.json<AddFamilyMemberRequest>();

    // Basic Validation
    if (!payload.familyId || !payload.fullName || !payload.gender || !payload.relationshipToHead) {
      return c.json({ error: 'Missing required member fields (familyId, fullName, gender, relationshipToHead).' }, 400);
    }

    const newMember = await addMemberToFamily(sessionUser.id, payload);
    return c.json({ member: newMember }, 201);
  } catch (error: any) {
    console.error('Error in handleAddFamilyMember:', error);
    if (error.message?.includes('already registered')) {
      return c.json({ error: error.message }, 400);
    }
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle fetching the current user's own family
 */
export async function handleGetMyFamily(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const result = await getMyFamily(sessionUser.id);
    if (!result) {
      return c.json({ family: null });
    }
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleGetMyFamily:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle fetching family tree details
 */
export async function handleGetFamilyTree(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const familyIdStr = c.req.param('familyId') || '';
    const familyId = parseInt(familyIdStr, 10);

    if (isNaN(familyId)) {
      return c.json({ error: 'Invalid familyId parameter.' }, 400);
    }

    const data = await getFamilyTreeData(familyId, sessionUser.id);
    if (!data) {
      return c.json({ error: 'Family unit not found.' }, 404);
    }

    return c.json(data);
  } catch (error: any) {
    console.error('Error in handleGetFamilyTree:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle updating a family member node
 */
export async function handleUpdateFamilyMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const memberIdStr = c.req.param('id') || '';
    const memberId = parseInt(memberIdStr, 10);
    const payload = await c.req.json<any>();

    if (isNaN(memberId)) {
      return c.json({ error: 'Invalid member ID.' }, 400);
    }

    const updated = await updateFamilyMember(sessionUser.id, memberId, payload);
    return c.json({ member: updated });
  } catch (error: any) {
    console.error('Error in handleUpdateFamilyMember:', error);
    if (error.message === 'Member not found') {
      return c.json({ error: error.message }, 404);
    }
    if (error.message === 'Unauthorized') {
      return c.json({ error: error.message }, 403);
    }
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle deleting a family member node
 */
export async function handleDeleteFamilyMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const memberIdStr = c.req.param('id') || '';
    const memberId = parseInt(memberIdStr, 10);

    if (isNaN(memberId)) {
      return c.json({ error: 'Invalid member ID.' }, 400);
    }

    const result = await deleteFamilyMember(sessionUser.id, memberId);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleDeleteFamilyMember:', error);
    if (error.message === 'Member not found') {
      return c.json({ error: error.message }, 404);
    }
    if (error.message === 'Unauthorized') {
      return c.json({ error: error.message }, 403);
    }
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle listing all pending family members for approval
 */
export async function handleGetPendingMembers(c: Context) {
  try {
    const list = await getPendingFamilyMembers();
    return c.json({ pendingMembers: list });
  } catch (error: any) {
    console.error('Error in handleGetPendingMembers:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle approving a family member
 */
export async function handleApproveMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const id = parseInt(c.req.param('id') || '', 10);
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400);

    const result = await approveFamilyMember(id, sessionUser.id);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleApproveMember:', error);
    if (error.message === 'Member not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle rejecting a family member
 */
export async function handleRejectMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const id = parseInt(c.req.param('id') || '', 10);
    const { reason } = await c.req.json<{ reason?: string }>().catch(() => ({ reason: undefined }));
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400);

    const result = await rejectFamilyMember(id, sessionUser.id, reason);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleRejectMember:', error);
    if (error.message === 'Member not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle searching approved family members
 */
export async function handleSearchMembers(c: Context) {
  try {
    const q = c.req.query('q') || '';
    const members = await searchFamilyMembers(q);
    return c.json({ members });
  } catch (error: any) {
    console.error('Error in handleSearchMembers:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle getting all members linked to a business
 */
export async function handleGetBusinessMembers(c: Context) {
  try {
    const businessId = parseInt(c.req.param('businessId') || '', 10);
    if (isNaN(businessId)) return c.json({ error: 'Invalid business ID' }, 400);

    const members = await getBusinessMembersList(businessId);
    return c.json({ members });
  } catch (error: any) {
    console.error('Error in handleGetBusinessMembers:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle linking a member to a business
 */
export async function handleAddBusinessMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const businessId = parseInt(c.req.param('businessId') || '', 10);
    if (isNaN(businessId)) return c.json({ error: 'Invalid business ID' }, 400);

    const { memberId, roleInBusiness } = await c.req.json<{ memberId: number, roleInBusiness?: string }>();
    if (!memberId) return c.json({ error: 'Member ID is required' }, 400);

    const role = roleInBusiness || 'Partner';
    const result = await addMemberToBusiness(sessionUser.id, businessId, memberId, role);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleAddBusinessMember:', error);
    if (error.message === 'Business not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle unlinking a member from a business
 */
export async function handleDeleteBusinessMember(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const businessId = parseInt(c.req.param('businessId') || '', 10);
    const memberId = parseInt(c.req.param('memberId') || '', 10);

    if (isNaN(businessId) || isNaN(memberId)) {
      return c.json({ error: 'Invalid business or member ID' }, 400);
    }

    const result = await removeMemberFromBusiness(sessionUser.id, businessId, memberId);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleDeleteBusinessMember:', error);
    if (error.message === 'Business not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle listing all approved community members with search and filter
 */
export async function handleGetMembers(c: Context) {
  try {
    const q = c.req.query('q') || '';
    const villageIdStr = c.req.query('villageId') || '';
    const villageId = villageIdStr ? parseInt(villageIdStr, 10) : undefined;

    const members = await getMembersList(q, villageId);
    return c.json({ members });
  } catch (error: any) {
    console.error('Error in handleGetMembers:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle listing all approved community business profiles with search and category filter
 */
export async function handleGetBusinesses(c: Context) {
  try {
    const q = c.req.query('q') || '';
    const category = c.req.query('category') || '';

    const businesses = await getBusinessProfilesList(q, category);
    return c.json({ businesses });
  } catch (error: any) {
    console.error('Error in handleGetBusinesses:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle listing all pending business profiles for approval
 */
export async function handleGetPendingBusinesses(c: Context) {
  try {
    const list = await getPendingBusinessProfiles();
    return c.json({ pendingBusinesses: list });
  } catch (error: any) {
    console.error('Error in handleGetPendingBusinesses:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle approving a business profile
 */
export async function handleApproveBusiness(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const id = parseInt(c.req.param('id') || '', 10);
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400);

    const result = await approveBusinessProfile(id, sessionUser.id);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleApproveBusiness:', error);
    if (error.message === 'Business profile not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

/**
 * Handle rejecting a business profile
 */
export async function handleRejectBusiness(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const id = parseInt(c.req.param('id') || '', 10);
    if (isNaN(id)) return c.json({ error: 'Invalid ID' }, 400);

    const result = await rejectBusinessProfile(id, sessionUser.id);
    return c.json(result);
  } catch (error: any) {
    console.error('Error in handleRejectBusiness:', error);
    if (error.message === 'Business profile not found') return c.json({ error: error.message }, 404);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

