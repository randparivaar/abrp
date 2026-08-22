import { defineConfig } from 'drizzle-kit';
import dotenv from 'dotenv';

dotenv.config({ override: true });

let dbUrl = process.env.DATABASE_URL || '';
if (dbUrl.includes('sslmode=require')) {
  dbUrl = dbUrl.replace('sslmode=require', 'sslmode=verify-full');
} else if (!dbUrl.includes('sslmode=')) {
  dbUrl += (dbUrl.includes('?') ? '&' : '?') + 'sslmode=verify-full';
}

export default defineConfig({
  out: './src/db/migrations',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    url: dbUrl,
    ssl: true,
  },
});
