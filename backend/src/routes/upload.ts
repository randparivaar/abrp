import { Hono } from 'hono';
import { authMiddleware } from '../middleware/auth';
import { handleGetPresignedUrl } from '../controllers/upload.controller';

const uploadRouter = new Hono();

// All upload routes require JWT validation
uploadRouter.use('*', authMiddleware);

uploadRouter.post('/presigned-url', handleGetPresignedUrl);

export { uploadRouter };
