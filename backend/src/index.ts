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
import { appConfigRouter, appVersionConfig } from './routes/appConfig.js';
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
app.use('*', async (c, next) => {
  await next();
  c.header('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  c.header('Pragma', 'no-cache');
  c.header('Expires', '0');
});
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

// API Routes (mounted under both /v1 and /api/v1 for custom domain & backward compatibility)
app.get('/v1', (c) => {
  return c.json({
    app: 'Akhil Bhartiya Rander Parivar Samaj API',
    version: 'v1',
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

// App Version Enforcement Middleware (Layer 2 API Guard)
// Blocks older deprecated client builds with HTTP 426 Upgrade Required
app.use('*', async (c, next) => {
  const path = c.req.path;
  if (
    (!path.startsWith('/v1') && !path.startsWith('/api/v1')) ||
    path.includes('/app-config') ||
    path.endsWith('/health') ||
    path === '/v1' ||
    path === '/api/v1'
  ) {
    return next();
  }

  const appBuildHeader = c.req.header('x-app-build');
  const appPlatform = (c.req.header('x-app-platform') || 'android').toLowerCase() === 'ios' ? 'ios' : 'android';

  if (appBuildHeader) {
    const clientBuild = parseInt(appBuildHeader, 10);
    const minRequired = appVersionConfig[appPlatform].minRequiredBuild;
    if (!isNaN(clientBuild) && clientBuild < minRequired) {
      return c.json(
        {
          error: 'UPGRADE_REQUIRED',
          code: 426,
          message: appVersionConfig[appPlatform].message.en,
          title: appVersionConfig[appPlatform].title.en,
          minRequiredBuild: minRequired,
          minRequiredVersion: appVersionConfig[appPlatform].minRequiredVersion,
          updateUrl: appVersionConfig[appPlatform].updateUrl,
        },
        426
      );
    }
  }

  return next();
});

const apiRouters = [
  ['/auth', authRouter],
  ['/app-config', appConfigRouter],
  ['/upload', uploadRouter],
  ['/notifications', notificationsRouter],
  ['/users', usersRouter],
  ['/directory', directoryRouter],
  ['/ads', adsRouter],
  ['/events', eventsRouter],
  ['/legal', legalRouter],
] as const;

for (const [routePath, router] of apiRouters) {
  app.route(`/v1${routePath}`, router as any);
  app.route(`/api/v1${routePath}`, router as any);
}

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

