import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth';
import { 
  handleRegisterDevice, 
  handleUnregisterDevice, 
  handleSendTest 
} from '../controllers/notifications.controller';

const notificationsRouter = new Hono();

// All routes require JWT authentication
notificationsRouter.use('*', authMiddleware);

notificationsRouter.post('/register', handleRegisterDevice);
notificationsRouter.post('/unregister', handleUnregisterDevice);
notificationsRouter.post('/send-test', roleGuard(['admin']), handleSendTest);

export { notificationsRouter };
