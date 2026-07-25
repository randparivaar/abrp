import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema.js';
import dotenv from 'dotenv';

dotenv.config();

function createDbClient() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL environment variable is missing on server.');
  }
  const sql = neon(databaseUrl);
  return drizzle(sql, { schema });
}

let dbInstance: ReturnType<typeof createDbClient> | null = null;

export const db = new Proxy({} as ReturnType<typeof createDbClient>, {
  get(_target, prop, receiver) {
    if (!dbInstance) {
      dbInstance = createDbClient();
    }
    return Reflect.get(dbInstance, prop, receiver);
  },
});



