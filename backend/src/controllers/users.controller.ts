import { Context } from 'hono';
import { UserSession } from '../middleware/auth.js';
import { 
  getUserById, 
  updateUserProfile, 
  updateUserRole, 
  listAllUsers,
  deleteUserAccount 
} from '../services/users.service.js';
import { UpdateUserProfileRequest, ChangeRoleRequest } from '../types/users.types.js';

export async function handleGetMyProfile(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;

    const user = await getUserById(sessionUser.id);

    if (!user) {
      return c.json({ error: 'User profile not found.' }, 404);
    }

    return c.json({ user });
  } catch (error: any) {
    console.error('Error fetching current user profile:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleUpdateMyProfile(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;
    const { fullName, preferredLanguage, avatarUrl } = await c.req.json<UpdateUserProfileRequest>();

    if (preferredLanguage && preferredLanguage !== 'en' && preferredLanguage !== 'hi') {
      return c.json({ error: 'Invalid language preference. Supported: en, hi' }, 400);
    }

    const updatedUser = await updateUserProfile(sessionUser.id, {
      fullName,
      preferredLanguage,
      avatarUrl,
    });

    return c.json({ user: updatedUser });
  } catch (error: any) {
    console.error('Error updating user profile:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleChangeRole(c: Context) {
  try {
    const { userId, newRole, regionIds } = await c.req.json<ChangeRoleRequest>();

    if (!userId || !newRole) {
      return c.json({ error: 'Missing required parameters: userId or newRole' }, 400);
    }

    if (!['admin', 'member', 'moderator'].includes(newRole)) {
      return c.json({ error: 'Invalid role. Choose from: admin, member, moderator' }, 400);
    }

    const updatedUser = await updateUserRole(userId, newRole, regionIds);


    if (!updatedUser) {
      return c.json({ error: 'Target user not found.' }, 404);
    }

    return c.json({ user: updatedUser });
  } catch (error: any) {
    console.error('Error updating user role:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleListUsers(c: Context) {
  try {
    const search = c.req.query('search') || c.req.query('q');
    const page = parseInt(c.req.query('page') || '1', 10);
    const limit = parseInt(c.req.query('limit') || '10', 10);

    const result = await listAllUsers(search, isNaN(page) ? 1 : page, isNaN(limit) ? 10 : limit);
    return c.json(result);
  } catch (error: any) {
    console.error('Error listing users:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}

export async function handleDeleteMyAccount(c: Context) {
  try {
    const sessionUser = c.get('user') as UserSession;

    const result = await deleteUserAccount(sessionUser.id);
    if (!result) {
      return c.json({ error: 'User account not found or already deleted.' }, 404);
    }

    return c.json({ 
      success: true, 
      message: 'Your account has been deleted successfully. You can re-register anytime with your email or mobile.' 
    });
  } catch (error: any) {
    console.error('Error deleting user account:', error);
    return c.json({ error: 'Internal Server Error while deleting account.' }, 500);
  }
}

export async function handleDeleteUserByAdmin(c: Context) {
  try {
    const targetUserId = c.req.param('id');
    if (!targetUserId) {
      return c.json({ error: 'Missing target user ID' }, 400);
    }

    const sessionUser = c.get('user') as UserSession;
    if (sessionUser.id === targetUserId) {
      return c.json({ error: 'Cannot delete yourself through admin management. Use delete my account instead.' }, 400);
    }

    const result = await deleteUserAccount(targetUserId);
    if (!result) {
      return c.json({ error: 'Target user not found or already deleted.' }, 404);
    }

    return c.json({ 
      success: true, 
      message: 'User account deleted successfully by administrator.' 
    });
  } catch (error: any) {
    console.error('Error deleting user by admin:', error);
    return c.json({ error: 'Internal Server Error while deleting user account.' }, 500);
  }
}


