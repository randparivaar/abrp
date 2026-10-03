import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import { 
  handleGetMyProfile, 
  handleUpdateMyProfile, 
  handleChangeRole, 
  handleChangeUserStatus,
  handleListUsers,
  handleDeleteMyAccount,
  handleDeleteUserByAdmin 
} from '../controllers/users.controller.js';

const usersRouter = new Hono();

// All routes require JWT authentication
usersRouter.use('*', authMiddleware);

usersRouter.get('/me', handleGetMyProfile);
usersRouter.patch('/me', handleUpdateMyProfile);
usersRouter.delete('/me', handleDeleteMyAccount);

// Admin & Moderator routes
usersRouter.get('/', roleGuard(['admin', 'moderator']), handleListUsers);

// Admin only routes
usersRouter.patch('/change-role', roleGuard(['admin']), handleChangeRole);
usersRouter.patch('/change-status', roleGuard(['admin']), handleChangeUserStatus);
usersRouter.delete('/:id', roleGuard(['admin']), handleDeleteUserByAdmin);

export { usersRouter };
