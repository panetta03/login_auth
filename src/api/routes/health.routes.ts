import { Router, Request, Response } from 'express';

const router = Router();

// Basic health check
router.get('/', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// Readiness check (database and Redis connectivity)
router.get('/ready', async (_req: Request, res: Response) => {
  const checks: Record<string, boolean> = {};

  try {
    // Check database
    const { db } = await import('../../database/client');
    await db.selectFrom('users').select(db.fn.count('id').as('count')).executeTakeFirst();
    checks.database = true;
  } catch (error) {
    checks.database = false;
  }

  try {
    // Check Redis
    const { redis } = await import('../../config/redis');
    await redis.ping();
    checks.redis = true;
  } catch (error) {
    checks.redis = false;
  }

  const allHealthy = Object.values(checks).every((check) => check === true);

  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ready' : 'not ready',
    checks,
    timestamp: new Date().toISOString(),
  });
});

export default router;
