import { S3Client, PutObjectCommand, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import dotenv from 'dotenv';

dotenv.config();

const s3Client = new S3Client({
  region: 'auto',
  endpoint: process.env.CLOUDFLARE_R2_ENDPOINT,
  credentials: {
    accessKeyId: process.env.CLOUDFLARE_R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY || '',
  },
});

export const r2Service = {
  /**
   * Generates a pre-signed PUT URL for direct uploading to Cloudflare R2 from the mobile client.
   * @param key Unique path in bucket (e.g. 'avatars/user-123.jpg')
   * @param contentType MIME type of the file (e.g. 'image/jpeg')
   * @param expiresIn Time in seconds until the link expires (default 1 hour)
   */
  async getPresignedUploadUrl(key: string, contentType: string, expiresIn = 3600) {
    const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('CLOUDFLARE_R2_BUCKET_NAME is not configured.');
    }

    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn });
    
    const publicUrl = process.env.CLOUDFLARE_R2_PUBLIC_URL 
      ? `${process.env.CLOUDFLARE_R2_PUBLIC_URL}/${key}`
      : `${process.env.CLOUDFLARE_R2_ENDPOINT}/${bucketName}/${key}`;

    return {
      uploadUrl,
      publicUrl,
    };
  },

  /**
   * Lists available poster images from Cloudflare R2 bucket with optional keyword filter.
   */
  async listPosters(search?: string, prefix?: string) {
    const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('CLOUDFLARE_R2_BUCKET_NAME is not configured.');
    }

    const command = new ListObjectsV2Command({
      Bucket: bucketName,
      Prefix: prefix || '',
      MaxKeys: 300,
    });

    const response = await s3Client.send(command);
    const baseUrl = process.env.CLOUDFLARE_R2_PUBLIC_URL 
      ? process.env.CLOUDFLARE_R2_PUBLIC_URL 
      : `${process.env.CLOUDFLARE_R2_ENDPOINT}/${bucketName}`;

    const items = (response.Contents || [])
      .filter((obj) => {
        if (!obj.Key) return false;
        // Keep image files
        const isImage = /\.(jpg|jpeg|png|webp|gif|svg)$/i.test(obj.Key);
        if (!isImage) return false;
        if (search && search.trim()) {
          const s = search.trim().toLowerCase();
          return obj.Key.toLowerCase().includes(s);
        }
        return true;
      })
      .map((obj) => {
        const key = obj.Key!;
        const filename = key.split('/').pop() || key;
        const publicUrl = `${baseUrl}/${key}`;
        return {
          key,
          filename,
          publicUrl,
          size: obj.Size,
          lastModified: obj.LastModified,
        };
      });

    return items;
  },
};
