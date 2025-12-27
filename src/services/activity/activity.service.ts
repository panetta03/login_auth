import { redis } from '../../config/redis';
import { SessionRepository } from '../../database/repositories/session.repository';
import { logger } from '../../utils/logger';

const INACTIVITY_THRESHOLD = 15 * 60 * 1000; // 15 minutes
const GRACE_PERIOD = 30 * 60 * 1000; // 30 minutes
// MAX_INACTIVITY = 7 days - used for refresh token cleanup (future scheduled job)

const sessionRepository = new SessionRepository();

export class ActivityService {
  /**
   * Update activity for a session (session-scoped using sid)
   * Updates Redis immediately, PostgreSQL periodically
   */
  async updateActivity(sessionId: string): Promise<void> {
    try {
      // Update Redis (real-time)
      await redis.setex(
        `activity:${sessionId}`,
        Math.floor(GRACE_PERIOD / 1000), // TTL in seconds
        Date.now().toString()
      );

      // Update PostgreSQL periodically (not every request)
      // In production, batch these updates or update on token refresh/logout
      // For now, update every 5 minutes per session
      const lastUpdate = await redis.get(`activity:pg:${sessionId}`);
      const now = Date.now();

      if (!lastUpdate || now - parseInt(lastUpdate) > 5 * 60 * 1000) {
        await sessionRepository.updateActivity(sessionId);
        await redis.setex(`activity:pg:${sessionId}`, 300, now.toString());
      }
    } catch (error) {
      logger.error('Failed to update activity', { error, sessionId });
      // Don't throw - activity tracking is non-critical
    }
  }

  /**
   * Check if session is active based on last activity
   */
  async isSessionActive(sessionId: string): Promise<boolean> {
    try {
      const lastActivity = await redis.get(`activity:${sessionId}`);

      if (!lastActivity) {
        // Check database as fallback
        const session = await sessionRepository.findById(sessionId);
        if (!session) return false;

        const timeSinceActivity = Date.now() - session.last_activity_at.getTime();
        return timeSinceActivity < GRACE_PERIOD;
      }

      const timeSinceActivity = Date.now() - parseInt(lastActivity);
      return timeSinceActivity < GRACE_PERIOD;
    } catch (error) {
      logger.error('Failed to check session activity', { error, sessionId });
      // Fail-open: assume active if check fails
      return true;
    }
  }

  /**
   * Check if token should be considered inactive
   */
  async isTokenInactive(sessionId: string): Promise<boolean> {
    try {
      const lastActivity = await redis.get(`activity:${sessionId}`);

      if (!lastActivity) {
        return false; // No activity data, assume active
      }

      const timeSinceActivity = Date.now() - parseInt(lastActivity);
      return timeSinceActivity > INACTIVITY_THRESHOLD;
    } catch (error) {
      logger.error('Failed to check token inactivity', { error, sessionId });
      return false; // Fail-open
    }
  }

  /**
   * Clean up inactive sessions
   */
  async cleanupInactiveSessions(): Promise<void> {
    try {
      // Cleans up inactive sessions (to be implemented as scheduled job)
      logger.info('Cleanup inactive sessions - to be implemented as scheduled job');
    } catch (error) {
      logger.error('Failed to cleanup inactive sessions', { error });
    }
  }
}

export const activityService = new ActivityService();
