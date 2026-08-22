import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import {
  handleGetActiveEvents,
  handleAdminGetAllEvents,
  handleAdminCreateEvent,
  handleAdminUpdateEvent,
  handleAdminDeleteEvent,
} from '../controllers/events.controller.js';

const eventsRouter = new Hono();

// Public / Member authenticated routes
eventsRouter.use('*', authMiddleware);

eventsRouter.get('/active', handleGetActiveEvents);

// Admin-only management routes
eventsRouter.get('/admin/all', roleGuard(['admin']), handleAdminGetAllEvents);
eventsRouter.post('/admin/create', roleGuard(['admin']), handleAdminCreateEvent);
eventsRouter.put('/admin/:id', roleGuard(['admin']), handleAdminUpdateEvent);
eventsRouter.delete('/admin/:id', roleGuard(['admin']), handleAdminDeleteEvent);

export default eventsRouter;
