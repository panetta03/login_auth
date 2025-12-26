import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { oauthService } from '../../../services/oauth/oauth.service';
import { tokenService } from '../../../services/token/token.service';
import { SessionRepository } from '../../../database/repositories/session.repository';
import { auditService } from '../../../services/audit/audit.service';
import { AuthRequest } from '../../middleware/auth.middleware';
import { loginParamsSchema, callbackQuerySchema, validateRequest } from '../validators/schemas';
import { ValidationError } from '../../../utils/errors';

const sessionRepository = new SessionRepository();

class AuthController {
  async initiateLogin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const params = validateRequest(loginParamsSchema, req.params);
      const redirectUrl = await oauthService.initiateLogin(params.provider, req);
      res.redirect(redirectUrl);
    } catch (error) {
      if (error instanceof z.ZodError) {
        next(new ValidationError('Invalid provider'));
        return;
      }
      next(error);
    }
  }

  async handleCallback(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const params = validateRequest(loginParamsSchema, req.params);
      
      // Check for OAuth error first
      if (req.query.error) {
        res.status(401).json({ 
          error: 'OAuth error', 
          message: req.query.error as string 
        });
        return;
      }

      // Validate required OAuth parameters
      if (!req.query.code || !req.query.state) {
        res.status(400).json({ 
          error: 'Invalid OAuth callback', 
          message: 'Missing required OAuth parameters (code, state). Please initiate the OAuth flow by visiting /api/v1/auth/login/google'
        });
        return;
      }

      const query = validateRequest(callbackQuerySchema, req.query);

      const tokens = await oauthService.handleCallback(
        params.provider,
        query.code,
        query.state,
        req
      );

      res.json({
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn,
        user: tokens.user,
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authReq = req as AuthRequest;
      if (!authReq.user?.sid) {
        res.status(204).send();
        return;
      }

      // Get token for revocation
      const authHeader = req.headers.authorization;
      let jti: string | null = null;
      if (authHeader?.startsWith('Bearer ')) {
        const token = authHeader.substring(7);
        try {
          const decoded = jwt.decode(token, { complete: true });
          if (decoded && typeof decoded !== 'string' && typeof decoded.payload !== 'string') {
            jti = ((decoded.payload as jwt.JwtPayload).jti as string | undefined) || null;
          }
        } catch {
          // Token already invalid
        }
      }

      // Revoke session
      await sessionRepository.revokeSession(authReq.user.sid);

      // Revoke token (blacklist)
      if (jti) {
        const session = await sessionRepository.findByAccessTokenJti(jti);
        if (session) {
          await tokenService.revokeToken(jti, session.expires_at);
        }
      }

      // Log logout
      await auditService.logLogout(authReq.user.id, req.ip || null, req.get('user-agent') || null);

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  async logoutAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authReq = req as AuthRequest;
      if (!authReq.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      await sessionRepository.revokeAllUserSessions(authReq.user.id);

      // Log logout all
      await auditService.logLogoutAll(
        authReq.user.id,
        req.ip || null,
        req.get('user-agent') || null
      );

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
