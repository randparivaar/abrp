import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import { 
  handleGetMyProfile, 
  handleUpdateMyProfile, 
  handleChangeRole, 
  handleListUsers 
} from '../controllers/users.controller.js';

const usersRouter = new Hono();

// All routes require JWT authentication
usersRouter.use('*', authMiddleware);

usersRouter.get('/me', handleGetMyProfile);
usersRouter.patch('/me', handleUpdateMyProfile);

// Admin & Moderator routes
usersRouter.get('/', roleGuard(['admin', 'moderator']), handleListUsers);

// Admin only routes
usersRouter.patch('/change-role', roleGuard(['admin']), handleChangeRole);

export { usersRouter };
