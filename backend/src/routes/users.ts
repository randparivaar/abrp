import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '@/middleware/auth';
import { 
  handleGetMyProfile, 
  handleUpdateMyProfile, 
  handleChangeRole, 
  handleListUsers 
} from '@/controllers/users.controller';

const usersRouter = new Hono();

// All routes require JWT authentication
usersRouter.use('*', authMiddleware);

usersRouter.get('/me', handleGetMyProfile);
usersRouter.patch('/me', handleUpdateMyProfile);

// Admin only routes
usersRouter.patch('/change-role', roleGuard(['admin']), handleChangeRole);
usersRouter.get('/', roleGuard(['admin']), handleListUsers);

export { usersRouter };
