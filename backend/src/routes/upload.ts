import { Hono } from 'hono';
import { authMiddleware } from '../middleware/auth.js';
import { handleGetPresignedUrl } from '../controllers/upload.controller.js';

const uploadRouter = new Hono();

// All upload routes require JWT validation
uploadRouter.use('*', authMiddleware);

uploadRouter.post('/presigned-url', handleGetPresignedUrl);

export { uploadRouter };
