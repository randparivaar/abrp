import { Context } from 'hono';
import { UserSession } from '@/middleware/auth';
import { r2Service } from '@/services/r2.service';
import { PresignedUrlRequest } from '@/types/upload.types';

export async function handleGetPresignedUrl(c: Context) {
  try {
    const user = c.get('user') as UserSession;
    const { filename, contentType } = await c.req.json<PresignedUrlRequest>();

    if (!filename || !contentType) {
      return c.json({ error: 'Missing required parameters: filename, contentType' }, 400);
    }

    // Sanitize filename to avoid folder path injection
    const cleanFilename = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    
    // Generate a unique object key (e.g. uploads/user_uuid/1678888888-image.png)
    const timestamp = Date.now();
    const objectKey = `uploads/${user.id}/${timestamp}-${cleanFilename}`;

    // Get pre-signed URL from R2
    const result = await r2Service.getPresignedUploadUrl(objectKey, contentType);

    return c.json({
      uploadUrl: result.uploadUrl,
      publicUrl: result.publicUrl,
      key: objectKey,
    });
  } catch (error: any) {
    console.error('Error generating pre-signed upload URL:', error);
    return c.json({ error: 'Internal Server Error' }, 500);
  }
}
