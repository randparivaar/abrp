import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { authRouter } from './routes/auth.js';
import { uploadRouter } from './routes/upload.js';
import { notificationsRouter } from './routes/notifications.js';
import { usersRouter } from './routes/users.js';
import { directoryRouter } from './routes/directory.js';
import adsRouter from './routes/ads.js';
import eventsRouter from './routes/events.js';
import { legalRouter } from './routes/legal.js';
import { webRouter } from './routes/web.js';
import { dbHealthCheck } from './db/index.js';
import dotenv from 'dotenv';
import crypto from 'crypto';

dotenv.config({ override: true });

export type AppEnv = {
  Variables: {
    requestId: string;
    user?: any;
  };
};

const app = new Hono<AppEnv>();

// Request ID Middleware for observability
app.use('*', async (c, next) => {
  const requestId = c.req.header('x-request-id') || crypto.randomUUID();
  c.set('requestId', requestId);
  c.header('x-request-id', requestId);
  await next();
});

// Global Middleware
app.use('*', logger());
app.use('*', cors({
  origin: '*', // Adjust to match client configurations in production
  allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'x-request-id'],
  exposeHeaders: ['Content-Length', 'x-request-id'],
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

// Deep Health Check Route with Safe DB Verification
app.get('/health', async (c) => {
  const checkDb = c.req.query('db') !== '0';
  let dbResult = null;
  if (checkDb) {
    dbResult = await dbHealthCheck();
  }

  const isHealthy = !dbResult || dbResult.status === 'healthy';
  const statusCode = isHealthy ? 200 : 503;

  return c.json({
    app: 'Akhil Bhartiya Rander Parivar Samaj API',
    status: isHealthy ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    ...(dbResult ? { db: dbResult } : {}),
  }, statusCode);
});

// API Routes
app.route('/api/v1/auth', authRouter);
app.route('/api/v1/upload', uploadRouter);
app.route('/api/v1/notifications', notificationsRouter);
app.route('/api/v1/users', usersRouter);
app.route('/api/v1/directory', directoryRouter);
app.route('/api/v1/ads', adsRouter);
app.route('/api/v1/events', eventsRouter);
app.route('/api/v1/legal', legalRouter);

// Web Landing Pages & Deep Links
app.route('/', webRouter);

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

