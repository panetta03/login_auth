import { Request, Response, NextFunction } from 'express';
import { tokenService } from '../../services/token/token.service';
import { activityService } from '../../services/activity/activity.service';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    provider: string;
    sid?: string;
  };
}

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authReq = req as AuthRequest;
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      res
        .status(401)
        .json({ error: 'Unauthorized', message: 'Missing or invalid authorization header' });
      return;
    }

    const token = authHeader.substring(7);
    const user = await tokenService.validateToken(token);

    // Update activity tracking (session-scoped)
    if (user.sid) {
      await activityService.updateActivity(user.sid);
    }

    authReq.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized', message: 'Invalid or expired token' });
  }
}
