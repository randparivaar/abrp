import { db, dbRetry } from '../db/index.js';
import { events } from '../db/schema.js';
import { eq, desc, asc, and, or, isNull } from 'drizzle-orm';

export interface CreateEventInput {
  title: string;
  description?: string;
  imageUrl?: string;
  galleryUrls?: string[];
  externalAlbumUrl?: string;
  eventDate: Date;
  endDate?: Date;
  venue?: string;
  category?: string;
  isActive?: boolean;
}

export interface UpdateEventInput {
  title?: string;
  description?: string;
  imageUrl?: string;
  galleryUrls?: string[];
  externalAlbumUrl?: string;
  eventDate?: Date;
  endDate?: Date;
  venue?: string;
  category?: string;
  isActive?: boolean;
}

/**
 * Get active community events for public/member feed
 */
export async function getActiveEvents() {
  return await dbRetry(() =>
    db
      .select()
      .from(events)
      .where(or(eq(events.isActive, true), isNull(events.isActive)))
      .orderBy(asc(events.eventDate), desc(events.createdAt))
  );
}

/**
 * Admin: Get all events (active + inactive)
 */
export async function getAdminAllEvents() {
  return await dbRetry(() =>
    db
      .select()
      .from(events)
      .orderBy(desc(events.createdAt))
  );
}

/**
 * Admin: Create a new event
 */
export async function createEvent(adminId: string, data: CreateEventInput) {
  const [newEvent] = await dbRetry(() =>
    db
      .insert(events)
      .values({
        title: data.title,
        description: data.description || null,
        imageUrl: data.imageUrl || null,
        galleryUrls: data.galleryUrls || [],
        externalAlbumUrl: data.externalAlbumUrl || null,
        eventDate: data.eventDate,
        endDate: data.endDate || null,
        venue: data.venue || null,
        category: data.category || 'general',
        isActive: data.isActive !== undefined ? data.isActive : true,
        createdBy: adminId,
      })
      .returning()
  );
  return newEvent;
}

/**
 * Admin: Update an event by ID
 */
export async function updateEvent(eventId: number, data: UpdateEventInput) {
  const updatePayload: Record<string, any> = {
    updatedAt: new Date(),
  };

  if (data.title !== undefined) updatePayload.title = data.title;
  if (data.description !== undefined) updatePayload.description = data.description;
  if (data.imageUrl !== undefined) updatePayload.imageUrl = data.imageUrl;
  if (data.galleryUrls !== undefined) updatePayload.galleryUrls = data.galleryUrls;
  if (data.externalAlbumUrl !== undefined) updatePayload.externalAlbumUrl = data.externalAlbumUrl;
  if (data.eventDate !== undefined) updatePayload.eventDate = data.eventDate;
  if (data.endDate !== undefined) updatePayload.endDate = data.endDate;
  if (data.venue !== undefined) updatePayload.venue = data.venue;
  if (data.category !== undefined) updatePayload.category = data.category;
  if (data.isActive !== undefined) updatePayload.isActive = data.isActive;

  const [updated] = await dbRetry(() =>
    db
      .update(events)
      .set(updatePayload)
      .where(eq(events.id, eventId))
      .returning()
  );
  return updated;
}

/**
 * Admin: Delete an event by ID
 */
export async function deleteEvent(eventId: number) {
  const [deleted] = await dbRetry(() =>
    db
      .delete(events)
      .where(eq(events.id, eventId))
      .returning()
  );
  return deleted;
}
