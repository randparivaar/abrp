import { scrypt, randomBytes, timingSafeEqual } from 'crypto';
import { promisify } from 'util';

function scryptPromise(password: string | Buffer, salt: string | Buffer, keylen: number, options: { N?: number; r?: number; p?: number }): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(password, salt, keylen, options, (err, derivedKey) => {
      if (err) reject(err);
      else resolve(derivedKey as Buffer);
    });
  });
}

/**
 * Hash a password using scrypt with a unique 16-byte salt.
 * Returns the hash formatted as `salt:hex_hash`
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const hash = await scryptPromise(password, salt, 64, { N: 16384, r: 8, p: 1 });
  return `${salt}:${hash.toString('hex')}`;
}

/**
 * Verify a plain text password against a stored `salt:hex_hash` string.
 */
export async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  try {
    const [salt, hash] = storedHash.split(':');
    if (!salt || !hash) return false;

    const targetHash = await scryptPromise(password, salt, 64, { N: 16384, r: 8, p: 1 });
    const originalHashBuffer = Buffer.from(hash, 'hex');

    return timingSafeEqual(originalHashBuffer, targetHash);
  } catch (error) {
    console.error('Password verification error:', error);
    return false;
  }
}
