import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema.js';
import dotenv from 'dotenv';

dotenv.config();

// ─── Error Inspection & Observability Helpers ───────────────────────────────

export interface StructuredErrorDetails {
  name: string;
  message: string;
  code?: string;
  status?: number;
  causeChain: Array<{ name: string; message: string; code?: string }>;
  isTransient: boolean;
}

/**
 * Recursively extracts error details and unwraps cause chains (e.g. NeonDbError -> TypeError: fetch failed -> SocketError / ETIMEDOUT).
 * Sanitizes output so secrets or DATABASE_URL are never leaked.
 */
export function extractErrorDetails(err: any): StructuredErrorDetails {
  if (!err) {
    return {
      name: 'UnknownError',
      message: 'Unknown error object provided',
      causeChain: [],
      isTransient: false,
    };
  }

  const causeChain: Array<{ name: string; message: string; code?: string }> = [];
  let curr = err;
  let depth = 0;

  while (curr && depth < 5) {
    const errName = curr.name || curr.constructor?.name || 'Error';
    const errMsg = curr.message ? String(curr.message) : String(curr);
    const errCode = curr.code || curr.errno || curr.cause?.code;

    causeChain.push({
      name: errName,
      message: errMsg.replace(/postgresql:\/\/[^@]+@/g, 'postgresql://***:***@'),
      ...(errCode ? { code: String(errCode) } : {}),
    });

    curr = curr.cause || curr.sourceError;
    depth++;
  }

  const topName = err.name || err.constructor?.name || 'Error';
  const topMessage = (err.message || String(err)).replace(/postgresql:\/\/[^@]+@/g, 'postgresql://***:***@');
  const code = err.code || err.cause?.code || err.cause?.cause?.code || causeChain.find(c => c.code)?.code;
  const status = err.status || err.statusCode || err.response?.status;

  const isTransient = isTransientDbError(err, causeChain);

  return {
    name: topName,
    message: topMessage,
    ...(code ? { code: String(code) } : {}),
    ...(status ? { status: Number(status) } : {}),
    causeChain,
    isTransient,
  };
}

/**
 * Determines whether a database error is transient (network failure, cold start timeout, connection reset, 5xx gateway error).
 * Returns false for SQL syntax errors, constraint violations, and application logic errors.
 */
export function isTransientDbError(err: any, causeChain?: Array<{ name: string; message: string; code?: string }>): boolean {
  if (!err) return false;

  const fullMsg = [
    err?.message,
    err?.cause?.message,
    err?.sourceError?.message,
    ...(causeChain?.map(c => c.message) || []),
  ].filter(Boolean).join(' ').toLowerCase();

  const codeStr = [
    err?.code,
    err?.cause?.code,
    err?.cause?.cause?.code,
    ...(causeChain?.map(c => c.code) || []),
  ].filter(Boolean).join(' ').toUpperCase();

  // Known network error codes
  const networkCodes = [
    'ETIMEDOUT', 'ECONNRESET', 'ENOTFOUND', 'ECONNREFUSED',
    'EPIPE', 'EAI_AGAIN', 'UND_ERR_CONNECT_TIMEOUT', 'UND_ERR_SOCKET',
    'ENETUNREACH', 'EHOSTUNREACH', 'ABORT_ERR'
  ];
  if (networkCodes.some(c => codeStr.includes(c))) {
    return true;
  }

  // Known transient message patterns
  const transientPatterns = [
    'fetch failed',
    'error connecting to database',
    'socket hang up',
    'network error',
    'connection terminated',
    'gateway timeout',
    'bad gateway',
    'service unavailable',
    'rate limit',
    'too many requests',
    'neon compute',
  ];

  if (transientPatterns.some(pattern => fullMsg.includes(pattern))) {
    return true;
  }

  // HTTP status checks (502, 503, 504)
  const status = err?.status || err?.statusCode || err?.response?.status;
  if (status && [502, 503, 504, 429].includes(Number(status))) {
    return true;
  }

  return false;
}

/**
 * Wraps DB operations with exponential backoff & jitter on transient network/cold-start errors.
 * Bounded to maxRetries (default: 3) with full jitter to avoid retry storms.
 */
export async function dbRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  baseDelayMs = 300,
): Promise<T> {
  let lastErr: any;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err: any) {
      lastErr = err;
      const details = extractErrorDetails(err);

      if (details.isTransient && attempt < maxRetries) {
        // Exponential backoff with jitter: Math.min(3000, base * 2^attempt * (0.8 .. 1.2))
        const rawWait = baseDelayMs * Math.pow(2, attempt);
        const jitter = 0.8 + Math.random() * 0.4;
        const wait = Math.min(3000, Math.floor(rawWait * jitter));

        console.warn(
          `[dbRetry] Transient DB failure (attempt ${attempt + 1}/${maxRetries + 1}). Retrying in ${wait}ms. Error: ${details.name}: ${details.message} (code: ${details.code || 'N/A'})`
        );

        await new Promise<void>((resolve) => setTimeout(resolve, wait));
        continue;
      }

      // Non-transient error or retries exhausted — rethrow preserving full error structure
      throw err;
    }
  }

  throw lastErr;
}

// ─── Client Singleton ────────────────────────────────────────────────────────

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

// ─── Health Check Diagnostics ────────────────────────────────────────────────

export async function dbHealthCheck(): Promise<{
  status: 'healthy' | 'unhealthy';
  latencyMs: number;
  error?: string;
}> {
  const start = Date.now();
  try {
    await dbRetry(() => db.execute('SELECT 1' as any), 1, 200);
    return {
      status: 'healthy',
      latencyMs: Date.now() - start,
    };
  } catch (err: any) {
    const details = extractErrorDetails(err);
    return {
      status: 'unhealthy',
      latencyMs: Date.now() - start,
      error: `${details.name}: ${details.message}`,
    };
  }
}

// ─── Keep-alive ping (Long-lived server environments only, NOT Vercel) ───────

const KEEP_ALIVE_INTERVAL_MS = 4 * 60 * 1000; // 4 minutes

if (!process.env.VERCEL && (process.env.NODE_ENV !== 'production' || process.env.ENABLE_DB_KEEPALIVE === 'true')) {
  const ping = async () => {
    try {
      await dbRetry(() => db.execute('SELECT 1' as any), 1, 300);
      console.log('[db] Keep-alive ping OK');
    } catch (err) {
      const details = extractErrorDetails(err);
      console.warn(`[db] Keep-alive ping failed: ${details.name}: ${details.message}`);
    }
  };

  // First ping after 30 seconds
  setTimeout(() => {
    ping();
    setInterval(ping, KEEP_ALIVE_INTERVAL_MS);
  }, 30_000);
}

