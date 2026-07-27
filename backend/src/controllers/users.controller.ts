import { Context } from 'hono';
import { UserSession } from '../middleware/auth.js';
import { 
  getUserById, 
  updateUserProfile, 
  updateUserRole, 
  listAllUsers 
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
    const allUsers = await listAllUsers();
    return c.json({ users: allUsers });
  } catch (error: any) {
    console.error('Error listing users:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}
