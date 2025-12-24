import { OAuthProvider } from './base.provider';
import { Request } from 'express';
import { getSecrets } from '../../../utils/aws-secrets';
import { logger } from '../../../utils/logger';
import { config } from '../../../config';
import { redis } from '../../../config/redis';
import { userService } from '../../user/user.service';
import { SessionRepository } from '../../../database/repositories/session.repository';
import { RefreshTokenRepository } from '../../../database/repositories/refresh-token.repository';
import { tokenService } from '../../token/token.service';
import { auditService } from '../../audit/audit.service';
import { verifyGoogleIdToken } from './google-jwks.service';
import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';

const sessionRepository = new SessionRepository();
const refreshTokenRepository = new RefreshTokenRepository();

export const googleProvider: OAuthProvider = {
  async getAuthorizationUrl(_req: Request): Promise<string> {
    const secrets = await getSecrets();
    const state = crypto.randomBytes(16).toString('hex');
    const nonce = crypto.randomBytes(16).toString('hex');

    // Store state with nonce in Redis (TTL: 10 minutes)
    const stateData = JSON.stringify({ nonce, createdAt: new Date().toISOString() });
    await redis.setex(`oauth:state:${state}`, 10 * 60, stateData);

    const params = new URLSearchParams({
      client_id: secrets.GOOGLE_CLIENT_ID,
      redirect_uri: config.oauth.google.redirectUri,
      response_type: 'code',
      scope: 'openid email profile',
      state,
      nonce,
    });

    return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
  },

  async handleCallback(
    code: string,
    state: string,
    req: Request
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    user: { id: string; email: string; name: string | null; picture: string | null };
  }> {
    // Validate state from Redis
    const stateData = await redis.get(`oauth:state:${state}`);
    if (!stateData) {
      await auditService.logLoginFailure(
        'google',
        req.ip || null,
        req.get('user-agent') || null,
        'Invalid or expired OAuth state'
      );
      throw new Error('Invalid or expired OAuth state');
    }
    const storedState = JSON.parse(stateData);
    await redis.del(`oauth:state:${state}`); // Delete after use

    const secrets = await getSecrets();

    // Exchange code for tokens
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        code,
        client_id: secrets.GOOGLE_CLIENT_ID,
        client_secret: secrets.GOOGLE_CLIENT_SECRET,
        redirect_uri: config.oauth.google.redirectUri,
        grant_type: 'authorization_code',
      }),
    });

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      logger.error('Google OAuth token exchange failed', { error });
      throw new Error('Failed to exchange OAuth code for tokens');
    }

    const tokens = (await tokenResponse.json()) as { id_token: string; access_token?: string };
    const { id_token } = tokens;

    // Verify ID token signature using Google's JWKS
    let payload;
    try {
      // Full signature verification with Google's public keys
      payload = await verifyGoogleIdToken(id_token);

      // Verify nonce
      if (payload.nonce !== storedState.nonce) {
        await auditService.logLoginFailure(
          'google',
          req.ip || null,
          req.get('user-agent') || null,
          'Invalid nonce in ID token'
        );
        throw new Error('Invalid nonce in ID token');
      }

      // Verify audience
      const secrets = await getSecrets();
      if (payload.aud !== secrets.GOOGLE_CLIENT_ID) {
        await auditService.logLoginFailure(
          'google',
          req.ip || null,
          req.get('user-agent') || null,
          'Invalid ID token audience'
        );
        throw new Error('Invalid ID token audience');
      }
    } catch (error) {
      await auditService.logLoginFailure(
        'google',
        req.ip || null,
        req.get('user-agent') || null,
        error instanceof Error ? error.message : 'ID token verification failed'
      );
      throw error;
    }

    // Extract user info
    if (!payload.sub) {
      throw new Error('Missing sub claim in ID token');
    }

    const userInfo = {
      email: payload.email,
      name: payload.name || null,
      picture: payload.picture || null,
      provider: 'google',
      provider_id: payload.sub,
    };

    // Upsert user
    const user = await userService.upsertUser(userInfo);

    // Generate JWT access token
    const jti = uuidv4();

    // Create session
    const expiresAt = new Date(Date.now() + config.jwt.accessTokenExpiry * 1000);
    const session = await sessionRepository.createSession({
      user_id: user.id,
      access_token_jti: jti,
      expires_at: expiresAt,
      ip_address: req.ip || null,
      user_agent: req.get('user-agent') || null,
    });

    // Generate token with session ID
    const accessToken = await tokenService.generateAccessToken(
      {
        id: user.id,
        email: user.email,
        provider: user.provider,
        sid: session.id,
      },
      jti
    );

    // Create refresh token
    const refreshTokenExpiresAt = new Date(Date.now() + config.jwt.refreshTokenExpiry * 1000);
    const refreshTokenRecord = await refreshTokenRepository.createRefreshToken({
      session_id: session.id,
      user_id: user.id,
      expires_at: refreshTokenExpiresAt,
    });

    // Log successful login
    await auditService.logLogin(user.id, 'google', req.ip || null, req.get('user-agent') || null);

    return {
      accessToken,
      refreshToken: refreshTokenRecord.token,
      expiresIn: config.jwt.accessTokenExpiry,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
      },
    };
  },
};
