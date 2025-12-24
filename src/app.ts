import express from 'express';
import cors from 'cors';
import { config } from './config';
import { errorHandler } from './api/middleware/errorHandler.middleware';
import { requestLogger } from './api/middleware/logger.middleware';
import { rateLimiter } from './api/middleware/rateLimit.middleware';
import healthRoutes from './api/routes/health.routes';
import authRoutes from './api/v1/routes/auth.routes';
import tokenRoutes from './api/v1/routes/token.routes';
import userRoutes from './api/v1/routes/user.routes';
import jwksRoutes from './api/v1/routes/jwks.routes';

const app = express();

// Trust proxy (for API Gateway)
app.set('trust proxy', true);

// Middleware
app.use(
  cors({
    origin: config.corsOrigin,
    credentials: true,
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use(requestLogger);

// Rate limiting
app.use(rateLimiter);

// Health check (no rate limiting)
app.use('/health', healthRoutes);
app.use('/ready', healthRoutes);

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/auth/token', tokenRoutes);
app.use('/api/v1/auth', userRoutes);

// JWKS endpoint
app.use('/api/v1/.well-known', jwksRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Error handler (must be last)
app.use(errorHandler);

export default app;
