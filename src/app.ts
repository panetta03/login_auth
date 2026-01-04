// Express application setup
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

// Log all HTTP requests with method, path, IP, and response status
app.use(requestLogger);

// Rate limiting
app.use(rateLimiter);

// Health check routes (no rate limiting)
// Both /health and /ready are handled by the same router
app.use('/health', healthRoutes);
app.use('/ready', healthRoutes);

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/auth/token', tokenRoutes);
app.use('/api/v1/auth', userRoutes);

// JWKS endpoint (OAuth 2.0 standard path)
app.use('/.well-known/jwks.json', jwksRoutes);

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
