import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { authRouter } from './routes/auth.js';
import { uploadRouter } from './routes/upload.js';
import { notificationsRouter } from './routes/notifications.js';
import { usersRouter } from './routes/users.js';
import { directoryRouter } from './routes/directory.js';
import dotenv from 'dotenv';

dotenv.config();

const app = new Hono();

// Global Middleware
app.use('*', logger());
app.use('*', cors({
  origin: '*', // Adjust to match client configurations in production
  allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['Content-Length'],
  maxAge: 600,
}));

// Root Health Check Route
app.get('/', (c) => {
  return c.json({
    app: 'Akhil Bhartiya Rander Parivar Samaj API',
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.route('/api/v1/auth', authRouter);
app.route('/api/v1/upload', uploadRouter);
app.route('/api/v1/notifications', notificationsRouter);
app.route('/api/v1/users', usersRouter);
app.route('/api/v1/directory', directoryRouter);

// Start native Node.js HTTP server if running locally (not in Vercel)
if (!process.env.VERCEL) {
  const port = process.env.PORT ? parseInt(process.env.PORT) : 8005;
  (async () => {
    const { serve } = await import('@hono/node-server');
    serve({ fetch: app.fetch, port });
    console.log(`Server is running on port ${port}`);
  })();
}

export default app;

