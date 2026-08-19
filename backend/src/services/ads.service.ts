import { db, dbRetry } from '../db/index.js';
import { advertisements, users } from '../db/schema.js';
import { eq, and, lte, gte, isNull, or, desc, sql } from 'drizzle-orm';

/**
 * Get active ads matching a specific placement key (e.g. 'home_carousel', 'directory_feed')
 */
export async function getActiveAdsForPlacement(placementKey: string) {
  const ads = await dbRetry(() =>
    db
      .select()
      .from(advertisements)
      .where(
        and(
          or(eq(advertisements.isActive, true), isNull(advertisements.isActive)),
          sql`${advertisements.placements} @> ${JSON.stringify([placementKey])}::jsonb`
        )
      )
      .orderBy(desc(advertisements.priority), desc(advertisements.createdAt))
  );

  return ads;
}

/**
 * Get all active ads across placements
 */
export async function getAllActiveAds() {
  const ads = await dbRetry(() =>
    db
      .select()
      .from(advertisements)
      .where(or(eq(advertisements.isActive, true), isNull(advertisements.isActive)))
      .orderBy(desc(advertisements.priority), desc(advertisements.createdAt))
  );

  return ads;
}

/**
 * Admin: Get all advertisements (including inactive/scheduled)
 */
export async function getAdminAllAds() {
  const ads = await dbRetry(() =>
    db
      .select()
      .from(advertisements)
      .orderBy(desc(advertisements.createdAt))
  );

  return ads;
}

/**
 * Admin: Create a new advertisement campaign
 */
export async function createAd(adminId: string, data: {
  title: string;
  tagline?: string;
  imageUrl?: string;
  category: string;
  placements: string[];
  displayStyle?: string;
  businessId?: number;
  targetUrl?: string;
  contactMobile?: string;
  whatsappMobile?: string;
  location?: string;
  isActive?: boolean;
  priority?: number;
  startDate?: Date;
  endDate?: Date;
}) {
  const [newAd] = await dbRetry(() =>
    db
      .insert(advertisements)
      .values({
        title: data.title,
        tagline: data.tagline,
        imageUrl: data.imageUrl,
        category: data.category,
        placements: data.placements,
        displayStyle: data.displayStyle || 'banner',
        businessId: data.businessId,
        targetUrl: data.targetUrl,
        contactMobile: data.contactMobile,
        whatsappMobile: data.whatsappMobile,
        location: data.location,
        isActive: data.isActive !== undefined ? data.isActive : true,
        priority: data.priority || 0,
        startDate: data.startDate || new Date(),
        endDate: data.endDate,
        createdBy: adminId,
      })
      .returning()
  );

  return newAd;
}

/**
 * Admin: Update an existing advertisement
 */
export async function updateAd(adId: number, data: Partial<{
  title: string;
  tagline: string;
  imageUrl: string;
  category: string;
  placements: string[];
  displayStyle: string;
  businessId: number;
  targetUrl: string;
  contactMobile: string;
  whatsappMobile: string;
  location: string;
  isActive: boolean;
  priority: number;
  startDate: Date;
  endDate: Date;
}>) {
  const [updatedAd] = await dbRetry(() =>
    db
      .update(advertisements)
      .set({
        ...data,
        updatedAt: new Date(),
      })
      .where(eq(advertisements.id, adId))
      .returning()
  );

  return updatedAd;
}

/**
 * Admin: Delete an advertisement
 */
export async function deleteAd(adId: number) {
  await dbRetry(() =>
    db
      .delete(advertisements)
      .where(eq(advertisements.id, adId))
  );

  return { success: true };
}
