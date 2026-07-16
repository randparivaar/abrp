import { Context, Next } from 'hono';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || 'abrp_local_development_jwt_secret_key_change_me_in_production';

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
