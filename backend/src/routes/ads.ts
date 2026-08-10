import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import {
  handleGetAdsByPlacement,
  handleGetAllActiveAds,
  handleAdminGetAllAds,
  handleAdminCreateAd,
  handleAdminUpdateAd,
  handleAdminDeleteAd,
} from '../controllers/ads.controller.js';

const adsRouter = new Hono();

// Public / Member authenticated routes
adsRouter.use('*', authMiddleware);

adsRouter.get('/active', handleGetAllActiveAds);
adsRouter.get('/placement/:placementKey', handleGetAdsByPlacement);

// Admin-only management routes
adsRouter.get('/admin/all', roleGuard(['admin']), handleAdminGetAllAds);
adsRouter.post('/admin/create', roleGuard(['admin']), handleAdminCreateAd);
adsRouter.put('/admin/:id', roleGuard(['admin']), handleAdminUpdateAd);
adsRouter.delete('/admin/:id', roleGuard(['admin']), handleAdminDeleteAd);

export default adsRouter;
