import { drizzle } from 'drizzle-orm/neon-serverless';
import { Pool, neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import * as schema from './schema';
import dotenv from 'dotenv';

dotenv.config();

// Enable WebSockets in Node.js environment
neonConfig.webSocketConstructor = ws;

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error('DATABASE_URL environment variable is missing.');
}

const pool = new Pool({ connectionString: databaseUrl });
export const db = drizzle(pool, { schema });

