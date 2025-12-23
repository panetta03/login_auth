import { Request, Response, NextFunction } from 'express';
import { AuthRequest } from '../../middleware/auth.middleware';
import { userService } from '../../../services/user/user.service';

class UserController {
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authReq = req as AuthRequest;
      if (!authReq.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const user = await userService.getUserById(authReq.user.id);
      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
        provider: user.provider,
      });
    } catch (error) {
      next(error);
    }
  }

  async getSessions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authReq = req as AuthRequest;
      if (!authReq.user) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const sessions = await userService.getUserSessions(authReq.user.id);

      res.json(
        sessions.map((session) => ({
          id: session.id,
          ipAddress: session.ip_address,
          userAgent: session.user_agent,
          createdAt: session.created_at,
          lastActivityAt: session.last_activity_at,
          expiresAt: session.expires_at,
        }))
      );
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
