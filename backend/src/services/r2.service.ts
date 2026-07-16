import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
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
};
