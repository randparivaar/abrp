import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema.js';
import dotenv from 'dotenv';

dotenv.config();

// ─── Helpers ────────────────────────────────────────────────────────────────

function isFetchError(err: any): boolean {
  return (
    err?.message?.includes('fetch failed') ||
    err?.cause?.message?.includes('fetch failed') ||
    err?.sourceError?.message?.includes('fetch failed') ||
    err?.constructor?.name === 'AggregateError' ||
    (err?.cause != null && err.cause?.constructor?.name === 'AggregateError')
  );
}

/**
 * Wraps any async DB operation with automatic retry on Neon cold-start errors.
 *
 * Neon free-tier computes suspend after ~5 min of inactivity. The first
 * request after a suspend throws "fetch failed" / AggregateError while the
 * compute is waking up. Retrying with a delay succeeds once it's ready.
 *
 * Usage:
 *   const result = await dbRetry(() => db.query.families.findFirst(...));
 */
export async function dbRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 5,
  delayMs = 1500,
): Promise<T> {
  let lastErr: any;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err: any) {
      lastErr = err;
      if (isFetchError(err) && attempt < maxRetries) {
        const wait = delayMs * (attempt + 1); // exponential-ish back-off
        console.warn(
          `[db] Neon cold-start error on attempt ${attempt + 1}/${maxRetries + 1}, retrying in ${wait}ms…`,
        );
        await new Promise<void>((resolve) => setTimeout(resolve, wait));
        continue;
      }
      throw err;
    }
  }
  throw lastErr;
}

// ─── Client ─────────────────────────────────────────────────────────────────

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

// ─── Keep-alive ping ────────────────────────────────────────────────────────
// Neon suspends after ~5 min of inactivity. We ping every 4 min so the
// compute stays warm and the first real user request never hits a cold start.
// Only runs in long-lived server environments (not Vercel serverless).

const KEEP_ALIVE_INTERVAL_MS = 4 * 60 * 1000; // 4 minutes

if (process.env.NODE_ENV !== 'production' || process.env.ENABLE_DB_KEEPALIVE === 'true') {
  const ping = async () => {
    try {
      await dbRetry(() => db.execute('SELECT 1' as any), 2, 500);
      console.log('[db] Keep-alive ping OK');
    } catch (err) {
      console.warn('[db] Keep-alive ping failed:', (err as any)?.message ?? err);
    }
  };

  // First ping after 30 seconds (give server time to fully start)
  setTimeout(() => {
    ping();
    setInterval(ping, KEEP_ALIVE_INTERVAL_MS);
  }, 30_000);
}
