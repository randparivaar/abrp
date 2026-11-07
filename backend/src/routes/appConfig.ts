import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';

export interface PlatformVersionConfig {
  latestVersion: string;
  latestBuild: number;
  minRequiredVersion: string;
  minRequiredBuild: number;
  updateUrl: string;
  title: {
    en: string;
    hi: string;
  };
  message: {
    en: string;
    hi: string;
  };
  releaseNotes: string;
}

export interface AppVersionState {
  android: PlatformVersionConfig;
  ios: PlatformVersionConfig;
}

// In-memory version state seeded from environment variables with sensible production defaults
export const appVersionConfig: AppVersionState = {
  android: {
    latestVersion: process.env.APP_LATEST_ANDROID_VERSION || '1.0.1',
    latestBuild: parseInt(process.env.APP_LATEST_ANDROID_BUILD || '2', 10),
    minRequiredVersion: process.env.APP_MIN_ANDROID_VERSION || '1.0.0',
    minRequiredBuild: parseInt(process.env.APP_MIN_ANDROID_BUILD || '1', 10),
    updateUrl:
      process.env.APP_UPDATE_URL_ANDROID ||
      'https://play.google.com/store/apps/details?id=com.abrp.mobile',
    title: {
      en: 'App Update Required',
      hi: 'ऐप अपडेट आवश्यक है',
    },
    message: {
      en: 'A critical update is required to continue using the ABRP app. Please update now to access new features and security fixes.',
      hi: 'ABRP ऐप का उपयोग जारी रखने के लिए ऐप अपडेट करना आवश्यक है। कृपया नए फीचर्स और सुरक्षा अपडेट हेतु तुरंत अपडेट करें।',
    },
    releaseNotes:
      '• Enhanced Member & Business Directory\n• Improved Performance & Offline Reliability\n• Critical Bug Fixes & UI Enhancements',
  },
  ios: {
    latestVersion: process.env.APP_LATEST_IOS_VERSION || '1.0.0',
    latestBuild: parseInt(process.env.APP_LATEST_IOS_BUILD || '1', 10),
    minRequiredVersion: process.env.APP_MIN_IOS_VERSION || '1.0.0',
    minRequiredBuild: parseInt(process.env.APP_MIN_IOS_BUILD || '1', 10),
    updateUrl:
      process.env.APP_UPDATE_URL_IOS ||
      'https://apps.apple.com/app/id6446700000',
    title: {
      en: 'App Update Required',
      hi: 'ऐप अपडेट आवश्यक है',
    },
    message: {
      en: 'A critical update is required to continue using the ABRP app. Please update now to access new features and security fixes.',
      hi: 'ABRP ऐप का उपयोग जारी रखने के लिए ऐप अपडेट करना आवश्यक है। कृपया नए फीचर्स और सुरक्षा अपडेट हेतु तुरंत अपडेट करें।',
    },
    releaseNotes:
      '• Enhanced Member & Business Directory\n• Improved Performance & Offline Reliability\n• Critical Bug Fixes & UI Enhancements',
  },
};

const appConfigRouter = new Hono();

/**
 * Public Endpoint: Check current version requirements and whether upgrade is required
 * GET /v1/app-config/version?platform=android&build=1&version=1.0.0
 */
appConfigRouter.get('/version', (c) => {
  const platformParam = (c.req.query('platform') || 'android').toLowerCase();
  const platform: 'android' | 'ios' = platformParam === 'ios' ? 'ios' : 'android';
  const clientBuild = parseInt(c.req.query('build') || '0', 10);
  const clientVersion = c.req.query('version') || '1.0.0';

  const cfg = appVersionConfig[platform];
  
  // Force update is required if client reports a build number lower than minRequiredBuild
  const forceUpdate = clientBuild > 0 && clientBuild < cfg.minRequiredBuild;
  
  // Soft update available if client build is less than latest build (and not forced)
  const updateAvailable = clientBuild > 0 && clientBuild < cfg.latestBuild;

  return c.json({
    platform,
    clientVersion,
    clientBuild,
    latestVersion: cfg.latestVersion,
    latestBuild: cfg.latestBuild,
    minRequiredVersion: cfg.minRequiredVersion,
    minRequiredBuild: cfg.minRequiredBuild,
    forceUpdate,
    updateAvailable,
    updateUrl: cfg.updateUrl,
    title: cfg.title,
    message: cfg.message,
    releaseNotes: cfg.releaseNotes,
    serverTimestamp: new Date().toISOString(),
  });
});

/**
 * Admin Endpoint: Dynamically update minimum required or latest version without redeploying
 * POST /v1/app-config/version
 */
appConfigRouter.post('/version', authMiddleware, roleGuard(['admin']), async (c) => {

  const body = await c.req.json();
  const platformParam = (body.platform || 'android').toLowerCase();
  const platform: 'android' | 'ios' = platformParam === 'ios' ? 'ios' : 'android';

  const cfg = appVersionConfig[platform];

  if (body.minRequiredBuild !== undefined) {
    cfg.minRequiredBuild = parseInt(body.minRequiredBuild, 10);
  }
  if (body.latestBuild !== undefined) {
    cfg.latestBuild = parseInt(body.latestBuild, 10);
  }
  if (body.minRequiredVersion) {
    cfg.minRequiredVersion = String(body.minRequiredVersion);
  }
  if (body.latestVersion) {
    cfg.latestVersion = String(body.latestVersion);
  }
  if (body.updateUrl) {
    cfg.updateUrl = String(body.updateUrl);
  }
  if (body.releaseNotes) {
    cfg.releaseNotes = String(body.releaseNotes);
  }
  if (body.title) {
    if (body.title.en) cfg.title.en = String(body.title.en);
    if (body.title.hi) cfg.title.hi = String(body.title.hi);
  }
  if (body.message) {
    if (body.message.en) cfg.message.en = String(body.message.en);
    if (body.message.hi) cfg.message.hi = String(body.message.hi);
  }

  return c.json({
    success: true,
    message: `App version config updated for platform: ${platform}`,
    config: cfg,
  });
});

export { appConfigRouter };
