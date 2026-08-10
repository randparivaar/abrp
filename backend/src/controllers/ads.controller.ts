import { Context } from 'hono';
import * as adsService from '../services/ads.service.js';
import type { UserSession } from '../middleware/auth.js';

export async function handleGetAdsByPlacement(c: Context) {
  try {
    const placement = c.req.param('placementKey');
    if (!placement) {
      return c.json({ success: false, error: 'placementKey is required' }, 400);
    }
    const ads = await adsService.getActiveAdsForPlacement(placement);
    return c.json({ success: true, ads });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleGetAllActiveAds(c: Context) {
  try {
    const ads = await adsService.getAllActiveAds();
    return c.json({ success: true, ads });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminGetAllAds(c: Context) {
  try {
    const ads = await adsService.getAdminAllAds();
    return c.json({ success: true, ads });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminCreateAd(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const body = await c.req.json();

    if (!body.title || !body.category || !body.placements || !Array.isArray(body.placements)) {
      return c.json({ success: false, error: 'Title, category, and placements array are required.' }, 400);
    }

    const newAd = await adsService.createAd(user.id, {
      title: body.title,
      tagline: body.tagline,
      imageUrl: body.imageUrl,
      category: body.category,
      placements: body.placements,
      displayStyle: body.displayStyle,
      businessId: body.businessId ? Number(body.businessId) : undefined,
      targetUrl: body.targetUrl,
      contactMobile: body.contactMobile,
      whatsappMobile: body.whatsappMobile,
      location: body.location,
      isActive: body.isActive,
      priority: body.priority ? Number(body.priority) : 0,
      startDate: body.startDate ? new Date(body.startDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
    });

    return c.json({ success: true, ad: newAd }, 201);
  } catch (error: any) {
    return c.json({ success: false, error: error?.message || 'Internal server error' }, 500);
  }
}

export async function handleAdminUpdateAd(c: Context) {
  try {
    const adId = Number(c.req.param('id'));
    const body = await c.req.json();

    const updateData: any = { ...body };
    if (body.startDate) updateData.startDate = new Date(body.startDate);
    if (body.endDate) updateData.endDate = new Date(body.endDate);
    if (body.businessId) updateData.businessId = Number(body.businessId);
    if (body.priority !== undefined) updateData.priority = Number(body.priority);

    const updatedAd = await adsService.updateAd(adId, updateData);
    return c.json({ success: true, ad: updatedAd });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminDeleteAd(c: Context) {
  try {
    const adId = Number(c.req.param('id'));
    await adsService.deleteAd(adId);
    return c.json({ success: true, message: 'Advertisement deleted successfully' });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}
