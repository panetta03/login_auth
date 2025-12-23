import { Request, Response, NextFunction } from 'express';
import { logger } from '../../utils/logger';
import { v4 as uuidv4 } from 'uuid';

export interface RequestWithId extends Request {
  id?: string;
}

export function requestLogger(req: RequestWithId, res: Response, next: NextFunction): void {
  req.id = uuidv4();

  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      requestId: req.id,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });
  });

  next();
}

