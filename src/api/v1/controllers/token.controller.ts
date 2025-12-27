import { Request, Response, NextFunction } from 'express';
import { tokenService } from '../../../services/token/token.service';
import { RefreshTokenRepository } from '../../../database/repositories/refresh-token.repository';
import { SessionRepository } from '../../../database/repositories/session.repository';
import { UserRepository } from '../../../database/repositories/user.repository';
import { auditService } from '../../../services/audit/audit.service';
import { config } from '../../../config';
import { v4 as uuidv4 } from 'uuid';
import { ValidationError } from '../../../utils/errors';
import { refreshTokenSchema, validateTokenSchema, validateRequest } from '../validators/schemas';

const refreshTokenRepository = new RefreshTokenRepository();
const sessionRepository = new SessionRepository();
const userRepository = new UserRepository();

class TokenController {
  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const body = validateRequest(refreshTokenSchema, req.body);
      const { refreshToken } = body;

      // Find refresh token
      const refreshTokenRecord = await refreshTokenRepository.findByToken(refreshToken);
      if (!refreshTokenRecord) {
        await auditService.logTokenRefresh(
          'unknown',
          req.ip || null,
          req.get('user-agent') || null,
          false,
          'Invalid or expired refresh token'
        );
        throw new ValidationError('Invalid or expired refresh token');
      }

      // Update last used
      await refreshTokenRepository.updateLastUsed(refreshTokenRecord.id);

      // Get session
      const session = await sessionRepository.findById(refreshTokenRecord.session_id);
      if (!session || session.revoked_at) {
        throw new ValidationError('Session not found or revoked');
      }

      // Revoke old refresh token (rotation)
      await refreshTokenRepository.revokeToken(refreshTokenRecord.id);

      // Get user info
      const user = await userRepository.findById(session.user_id);
      if (!user) {
        throw new ValidationError('User not found');
      }

      // Generate new access token
      const jti = uuidv4();
      const accessToken = await tokenService.generateAccessToken(
        {
          id: user.id,
          email: user.email,
          provider: user.provider,
          sid: session.id,
        },
        jti
      );

      // Create new session with rotated access token (security best practice: session rotation)
      const expiresAt = new Date(Date.now() + config.jwt.accessTokenExpiry * 1000);
      await sessionRepository.revokeSession(session.id);
      const newSession = await sessionRepository.createSession({
        user_id: session.user_id,
        access_token_jti: jti,
        expires_at: expiresAt,
        ip_address: req.ip || null,
        user_agent: req.get('user-agent') || null,
      });

      // Create new refresh token
      const refreshTokenExpiresAt = new Date(Date.now() + config.jwt.refreshTokenExpiry * 1000);
      const newRefreshToken = await refreshTokenRepository.createRefreshToken({
        session_id: newSession.id,
        user_id: session.user_id,
        expires_at: refreshTokenExpiresAt,
      });

      // Log token refresh
      await auditService.logTokenRefresh(
        user.id,
        req.ip || null,
        req.get('user-agent') || null,
        true
      );

      res.json({
        accessToken,
        refreshToken: newRefreshToken.token,
        expiresIn: config.jwt.accessTokenExpiry,
      });
    } catch (error) {
      next(error);
    }
  }

  async validate(req: Request, res: Response, _next: NextFunction): Promise<void> {
    try {
      const body = validateRequest(validateTokenSchema, req.body);
      const { token } = body;

      const user = await tokenService.validateToken(token);

      res.json({
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          provider: user.provider,
        },
      });
    } catch (error) {
      res.status(401).json({
        valid: false,
        error: error instanceof Error ? error.message : 'Invalid token',
      });
    }
  }
}

export const tokenController = new TokenController();
