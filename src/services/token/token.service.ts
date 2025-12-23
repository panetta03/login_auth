import jwt from 'jsonwebtoken';
import { config } from '../../config';
import { logger } from '../../utils/logger';
import { redis } from '../../config/redis';
import { SessionRepository } from '../../database/repositories/session.repository';
import { keyManager } from './key-manager.service';

export interface AuthUser {
  id: string;
  email: string;
  provider: string;
  sid?: string;
}

// Initialize keys on module load
keyManager.initializeKeys().catch((error) => {
  logger.error('Failed to initialize JWT keys', { error });
});

const sessionRepository = new SessionRepository();

class TokenService {
  async generateAccessToken(user: AuthUser, jti: string): Promise<string> {
    const privateKey = keyManager.getPrivateKey();
    const kid = keyManager.getCurrentKid();

    const payload = {
      sub: user.id,
      email: user.email,
      provider: user.provider,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + config.jwt.accessTokenExpiry,
      jti,
      sid: user.sid,
      iss: config.jwt.issuer,
    };

    return jwt.sign(payload, privateKey, {
      algorithm: 'RS256',
      keyid: kid,
    });
  }

  async validateToken(token: string): Promise<AuthUser> {
    try {
      // Decode to get kid (key ID)
      const decodedHeader = jwt.decode(token, { complete: true });
      if (!decodedHeader || typeof decodedHeader === 'string') {
        throw new Error('Invalid token format');
      }

      const kid = decodedHeader.header.kid as string;
      const publicKey = keyManager.getPublicKey(kid);

      // Verify JWT signature and expiration
      const decoded = jwt.verify(token, publicKey, {
        algorithms: ['RS256'],
        issuer: config.jwt.issuer,
      }) as jwt.JwtPayload;

      // Check blacklist in Redis
      const blacklisted = await redis.exists(`blacklist:${decoded.jti}`);
      if (blacklisted) {
        throw new Error('Token has been revoked');
      }

      // Check session validity
      const session = await sessionRepository.findByAccessTokenJti(decoded.jti as string);
      if (!session) {
        throw new Error('Session not found or revoked');
      }

      // Check expiration
      if (session.expires_at < new Date()) {
        throw new Error('Token expired');
      }

      return {
        id: decoded.sub!,
        email: decoded.email as string,
        provider: decoded.provider as string,
        sid: decoded.sid as string | undefined,
      };
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw new Error('Invalid token');
      }
      if (error instanceof jwt.TokenExpiredError) {
        throw new Error('Token expired');
      }
      throw error;
    }
  }

  async revokeToken(jti: string, expiresAt: Date): Promise<void> {
    // Add to Redis blacklist (TTL = remaining token lifetime)
    const ttl = Math.max(0, Math.floor((expiresAt.getTime() - Date.now()) / 1000));
    if (ttl > 0) {
      await redis.setex(`blacklist:${jti}`, ttl, '1');
    }

    // Update database session
    const session = await sessionRepository.findByAccessTokenJti(jti);
    if (session) {
      await sessionRepository.revokeSession(session.id);
    }
  }

  getPublicKey(): string {
    return keyManager.getPublicKey();
  }

  getJWKS(): Array<{ kty: string; kid: string; use: string; alg: string; n: string; e: string }> {
    return keyManager.getJWKS();
  }
}

export const tokenService = new TokenService();
