import { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import { db } from '../db/index.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';

dotenv.config();

const isProd = process.env.NODE_ENV === 'production';
const JWT_SECRET = process.env.JWT_SECRET || (isProd ? '' : 'abrp_local_development_jwt_secret_key_change_me_in_production');

if (isProd && !process.env.JWT_SECRET) {
  console.error('CRITICAL SECURITY ERROR: JWT_SECRET environment variable is missing in production!');
}

export interface UserSession {
  id: string;
  email: string;
  role: string;
}

/**
 * Validates the Authorization Bearer JWT token in requests
 */
export async function authMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or malformed authorization token.' }, 401);
  }

  const token = authHeader.split(' ')[1];
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as UserSession;

    // Security Check: Verify user exists and is active (instant logout if suspended/blocked)
    const userRec = await db.query.users.findFirst({
      where: eq(users.id, decoded.id),
      columns: { id: true, status: true, role: true },
    });

    if (!userRec) {
      return c.json({ error: 'Unauthorized: User account not found.' }, 401);
    }

    if (userRec.status === 'suspended' || userRec.status === 'inactive') {
      return c.json({ error: 'Unauthorized: Your account has been suspended or blocked by admin.' }, 401);
    }

    decoded.role = userRec.role;
    c.set('user', decoded);
    await next();
  } catch (error) {
    return c.json({ error: 'Unauthorized: Token is expired or invalid.' }, 401);
  }
}

/**
 * Restricts access to specific roles (e.g. 'admin', 'moderator')
 */
export function roleGuard(allowedRoles: string[]) {
  return async (c: Context, next: Next) => {
    const user = c.get('user') as UserSession | undefined;
    
    if (!user || !allowedRoles.includes(user.role)) {
      return c.json({ error: 'Forbidden: You do not have sufficient permissions to access this resource.' }, 403);
    }
    
    await next();
  };
}
