import app from './app';
import { logger } from './utils/logger';
import { config } from './config';
import { keyManager } from './services/token/key-manager.service';

const PORT = config.port || 3000;

// Initialize JWT keys before starting server
keyManager.initializeKeys().then(() => {
  const server = app.listen(PORT, () => {
    logger.info(`Auth service started on port ${PORT}`, {
      env: config.nodeEnv,
      port: PORT,
    });
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
      logger.info('Process terminated');
      process.exit(0);
    });
  });

  process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    server.close(() => {
      logger.info('Process terminated');
      process.exit(0);
    });
  });
}).catch((error) => {
  logger.error('Failed to initialize service', { error });
  process.exit(1);
});

