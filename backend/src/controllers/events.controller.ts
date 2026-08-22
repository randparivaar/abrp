import { Context } from 'hono';
import * as eventsService from '../services/events.service.js';
import type { UserSession } from '../middleware/auth.js';

export async function handleGetActiveEvents(c: Context) {
  try {
    const eventsList = await eventsService.getActiveEvents();
    return c.json({ success: true, events: eventsList });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminGetAllEvents(c: Context) {
  try {
    const eventsList = await eventsService.getAdminAllEvents();
    return c.json({ success: true, events: eventsList });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminCreateEvent(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const body = await c.req.json();

    if (!body.title || !body.eventDate) {
      return c.json({ success: false, error: 'Title and eventDate are required.' }, 400);
    }

    const newEvent = await eventsService.createEvent(user.id, {
      title: body.title,
      description: body.description,
      imageUrl: body.imageUrl,
      galleryUrls: Array.isArray(body.galleryUrls) ? body.galleryUrls : [],
      externalAlbumUrl: body.externalAlbumUrl,
      eventDate: new Date(body.eventDate),
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      venue: body.venue,
      category: body.category || 'general',
      isActive: body.isActive !== undefined ? Boolean(body.isActive) : true,
    });

    return c.json({ success: true, event: newEvent }, 201);
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminUpdateEvent(c: Context) {
  try {
    const eventIdParam = c.req.param('id');
    const eventId = Number(eventIdParam);
    if (isNaN(eventId)) {
      return c.json({ success: false, error: 'Invalid event ID' }, 400);
    }

    const body = await c.req.json();

    const updated = await eventsService.updateEvent(eventId, {
      title: body.title,
      description: body.description,
      imageUrl: body.imageUrl,
      galleryUrls: Array.isArray(body.galleryUrls) ? body.galleryUrls : undefined,
      externalAlbumUrl: body.externalAlbumUrl,
      eventDate: body.eventDate ? new Date(body.eventDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      venue: body.venue,
      category: body.category,
      isActive: body.isActive !== undefined ? Boolean(body.isActive) : undefined,
    });

    if (!updated) {
      return c.json({ success: false, error: 'Event not found' }, 404);
    }

    return c.json({ success: true, event: updated });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}

export async function handleAdminDeleteEvent(c: Context) {
  try {
    const eventIdParam = c.req.param('id');
    const eventId = Number(eventIdParam);
    if (isNaN(eventId)) {
      return c.json({ success: false, error: 'Invalid event ID' }, 400);
    }

    const deleted = await eventsService.deleteEvent(eventId);
    if (!deleted) {
      return c.json({ success: false, error: 'Event not found' }, 404);
    }

    return c.json({ success: true, message: 'Event deleted successfully' });
  } catch (error: any) {
    return c.json({ success: false, error: error.message }, 500);
  }
}
