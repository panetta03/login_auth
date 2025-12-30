import Redis, { RedisOptions } from 'ioredis';
import { config } from './index';
import { logger } from '../utils/logger';

// In test mode, use lazy connection to avoid immediate connection failures
const redisOptions: RedisOptions = {
  retryStrategy: (times: number) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
  maxRetriesPerRequest: 3,
  lazyConnect: config.nodeEnv === 'test', // Lazy connect in test mode
  connectTimeout: 10000, // 10 second connection timeout
  commandTimeout: 10000, // 10 second command timeout (increased from 5s for network latency)
  enableReadyCheck: true,
  keepAlive: 30000, // Keep connection alive
  // Enable TLS for ElastiCache with transit encryption
  // ioredis automatically detects rediss:// URLs and enables TLS
  tls: config.redis.url.startsWith('rediss://')
    ? {
        // ElastiCache uses self-signed certificates, so we need to reject unauthorized
        // In production, you might want to verify the certificate
        rejectUnauthorized: false, // ElastiCache uses self-signed certs
      }
    : undefined,
};

export const redis = new Redis(config.redis.url, redisOptions);

redis.on('connect', () => {
  logger.info('Redis connected');
});

redis.on('error', (error) => {
  logger.error('Redis connection error', { error: error.message });
});

redis.on('close', () => {
  logger.warn('Redis connection closed');
});

// Helper to ensure Redis is connected (for test mode)
export async function ensureRedisConnected(): Promise<void> {
  if (config.nodeEnv === 'test' && redis.status !== 'ready') {
    try {
      await redis.connect();
      logger.info('Redis connected for tests');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error('Redis connection failed in test mode', { error: errorMessage });
      throw new Error(
        `Redis is required for integration tests but is not available at ${config.redis.url}. ` +
          'Please ensure Redis is running (e.g., docker run -p 6379:6379 redis:7-alpine)'
      );
    }
  }
}
