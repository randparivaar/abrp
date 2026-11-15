import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import { 
  handleRegisterDevice, 
  handleUnregisterDevice, 
  handleSendTest,
  handleDailyWishesCron,
  handleListPosters,
  handleSendWishNotification,
  handleGetNotifications,
  handleMarkAsRead,
  handleMarkAllAsRead
} from '../controllers/notifications.controller.js';

const notificationsRouter = new Hono();

// Daily cron endpoint for automated wishes (accessible by GitHub Actions cron runners without user JWT)
notificationsRouter.get('/cron/daily-wishes', handleDailyWishesCron);

// All other notification routes require JWT authentication
notificationsRouter.use('*', authMiddleware);

notificationsRouter.post('/register', handleRegisterDevice);
notificationsRouter.post('/unregister', handleUnregisterDevice);

// Notification Feed for all authenticated members
notificationsRouter.get('/', handleGetNotifications);
notificationsRouter.post('/read-all', handleMarkAllAsRead);
notificationsRouter.post('/:id/read', handleMarkAsRead);

// Admin & Moderator routes
notificationsRouter.get('/posters', roleGuard(['admin', 'moderator']), handleListPosters);
notificationsRouter.post('/send-wish', roleGuard(['admin', 'moderator']), handleSendWishNotification);
notificationsRouter.post('/send-test', roleGuard(['admin', 'moderator']), handleSendTest);

export { notificationsRouter };
