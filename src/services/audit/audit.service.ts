import { db } from '../../database/client';
import { logger } from '../../utils/logger';
import { v4 as uuidv4 } from 'uuid';

export interface AuditEvent {
  user_id?: string | null;
  action: 'login' | 'logout' | 'logout_all' | 'token_refresh' | 'token_revoke' | 'token_validate';
  provider?: string | null;
  ip_address?: string | null;
  user_agent?: string | null;
  success: boolean;
  error_message?: string | null;
  metadata?: Record<string, unknown> | null;
}

class AuditService {
  /**
   * Log audit event (non-blocking, fail-open)
   * Authentication should not fail due to audit logging issues
   */
  async logEvent(event: AuditEvent): Promise<void> {
    try {
      // Non-blocking audit write
      await db
        .insertInto('audit_logs')
        .values({
          id: uuidv4(),
          ...event,
          created_at: new Date(),
        })
        .execute();
    } catch (error) {
      // Log failure but don't block authentication
      logger.error('Audit logging failed', { error, event });
      // In production, could queue for retry (SQS)
    }
  }

  /**
   * Log successful login
   */
  async logLogin(
    userId: string,
    provider: string,
    ipAddress: string | null,
    userAgent: string | null
  ): Promise<void> {
    await this.logEvent({
      user_id: userId,
      action: 'login',
      provider,
      ip_address: ipAddress,
      user_agent: userAgent,
      success: true,
    });
  }

  /**
   * Log failed login attempt
   */
  async logLoginFailure(
    provider: string,
    ipAddress: string | null,
    userAgent: string | null,
    errorMessage: string
  ): Promise<void> {
    await this.logEvent({
      action: 'login',
      provider,
      ip_address: ipAddress,
      user_agent: userAgent,
      success: false,
      error_message: errorMessage,
    });
  }

  /**
   * Log logout
   */
  async logLogout(
    userId: string,
    ipAddress: string | null,
    userAgent: string | null
  ): Promise<void> {
    await this.logEvent({
      user_id: userId,
      action: 'logout',
      ip_address: ipAddress,
      user_agent: userAgent,
      success: true,
    });
  }

  /**
   * Log logout all sessions
   */
  async logLogoutAll(
    userId: string,
    ipAddress: string | null,
    userAgent: string | null
  ): Promise<void> {
    await this.logEvent({
      user_id: userId,
      action: 'logout_all',
      ip_address: ipAddress,
      user_agent: userAgent,
      success: true,
    });
  }

  /**
   * Log token refresh
   */
  async logTokenRefresh(
    userId: string,
    ipAddress: string | null,
    userAgent: string | null,
    success: boolean,
    errorMessage?: string
  ): Promise<void> {
    await this.logEvent({
      user_id: userId,
      action: 'token_refresh',
      ip_address: ipAddress,
      user_agent: userAgent,
      success,
      error_message: errorMessage || null,
    });
  }

  /**
   * Log token revocation
   */
  async logTokenRevoke(
    userId: string,
    ipAddress: string | null,
    userAgent: string | null
  ): Promise<void> {
    await this.logEvent({
      user_id: userId,
      action: 'token_revoke',
      ip_address: ipAddress,
      user_agent: userAgent,
      success: true,
    });
  }
}

export const auditService = new AuditService();
