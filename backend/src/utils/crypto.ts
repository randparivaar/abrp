import { scrypt, randomBytes, timingSafeEqual } from 'crypto';
import { promisify } from 'util';

const scryptAsync = promisify(scrypt);

/**
 * Hash a password using scrypt with a unique 16-byte salt.
 * Returns the hash formatted as `salt:hex_hash`
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const hash = (await scryptAsync(password, salt, 64, { N: 16384, r: 8, p: 1 })) as Buffer;
  return `${salt}:${hash.toString('hex')}`;
}

/**
 * Verify a plain text password against a stored `salt:hex_hash` string.
 */
export async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  try {
    const [salt, hash] = storedHash.split(':');
    if (!salt || !hash) return false;

    const targetHash = (await scryptAsync(password, salt, 64, { N: 16384, r: 8, p: 1 })) as Buffer;
    const originalHashBuffer = Buffer.from(hash, 'hex');

    return timingSafeEqual(originalHashBuffer, targetHash);
  } catch (error) {
    console.error('Password verification error:', error);
    return false;
  }
}
