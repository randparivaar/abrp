import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import { 
  handleRegisterDevice, 
  handleUnregisterDevice, 
  handleSendTest,
  handleDailyWishesCron
} from '../controllers/notifications.controller.js';

const notificationsRouter = new Hono();

// Daily cron endpoint for automated wishes (accessible by cron runners without user JWT)
notificationsRouter.get('/cron/daily-wishes', handleDailyWishesCron);

// All other notification routes require JWT authentication
notificationsRouter.use('*', authMiddleware);

notificationsRouter.post('/register', handleRegisterDevice);
notificationsRouter.post('/unregister', handleUnregisterDevice);
// Admin and Moderator can send push notifications (both single and broadcast)
notificationsRouter.post('/send-test', roleGuard(['admin', 'moderator']), handleSendTest);

export { notificationsRouter };
