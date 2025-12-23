import { Request, Response, NextFunction } from 'express';
import { logger } from '../../utils/logger';
import { config } from '../../config';

export interface AppError extends Error {
  statusCode?: number;
  isOperational?: boolean;
}

export function errorHandler(
  err: AppError,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const statusCode = err.statusCode || 500;
  const isOperational = err.isOperational !== false;

  // Log error
  logger.error('Request Error', {
    requestId: (req as any).id,
    error: {
      message: err.message,
      stack: config.nodeEnv === 'development' ? err.stack : undefined,
      statusCode,
      isOperational,
    },
    path: req.path,
    method: req.method,
  });

  // Send error response
  res.status(statusCode).json({
    error: isOperational ? err.message : 'Internal Server Error',
    ...(config.nodeEnv === 'development' && { stack: err.stack }),
  });
}

