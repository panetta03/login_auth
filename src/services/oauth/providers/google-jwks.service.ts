import { JwksClient } from 'jwks-rsa';
import jwt from 'jsonwebtoken';
import { logger } from '../../../utils/logger';

// Google's JWKS endpoint
const GOOGLE_JWKS_URI = 'https://www.googleapis.com/oauth2/v3/certs';

// Cache for Google's public keys
let jwksClient: JwksClient | null = null;
const CACHE_TTL = 60 * 60 * 1000; // 1 hour

/**
 * Initialize Google JWKS client
 */
function getJwksClient(): JwksClient {
  if (!jwksClient) {
    jwksClient = new JwksClient({
      jwksUri: GOOGLE_JWKS_URI,
      cache: true,
      cacheMaxAge: CACHE_TTL,
      rateLimit: true,
      jwksRequestsPerMinute: 10,
    });
  }
  return jwksClient;
}

/**
 * Get signing key for Google ID token verification
 */
export async function getGoogleSigningKey(kid: string): Promise<string> {
  try {
    const client = getJwksClient();
    const key = await client.getSigningKey(kid);
    return key.getPublicKey();
  } catch (error) {
    logger.error('Failed to get Google signing key', { error, kid });
    throw new Error('Failed to verify ID token signature');
  }
}

/**
 * Verify Google ID token signature
 */
export async function verifyGoogleIdToken(idToken: string): Promise<jwt.JwtPayload> {
  try {
    // Decode to get kid (key ID)
    const decoded = jwt.decode(idToken, { complete: true });
    if (!decoded || typeof decoded === 'string') {
      throw new Error('Invalid ID token format');
    }

    const kid = decoded.header.kid as string;
    if (!kid) {
      throw new Error('ID token missing key ID');
    }

    // Get public key from Google's JWKS
    const publicKey = await getGoogleSigningKey(kid);

    // Verify signature and claims
    const payload = jwt.verify(idToken, publicKey, {
      algorithms: ['RS256'],
      issuer: ['https://accounts.google.com', 'accounts.google.com'],
    }) as jwt.JwtPayload;

    return payload;
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      logger.error('ID token verification failed', { error: error.message });
      throw new Error(`Invalid ID token: ${error.message}`);
    }
    throw error;
  }
}

