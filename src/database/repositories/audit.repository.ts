import { db } from '../client';
import type { AuditLogTable } from '../schema';
import { v4 as uuidv4 } from 'uuid';

export class AuditRepository {
  async create(auditLog: {
    user_id?: string | null;
    action: string;
    provider?: string | null;
    ip_address?: string | null;
    user_agent?: string | null;
    success: boolean;
    error_message?: string | null;
    metadata?: Record<string, unknown> | null;
  }): Promise<AuditLogTable> {
    return db
      .insertInto('audit_logs')
      .values({
        id: uuidv4(),
        ...auditLog,
        created_at: new Date(),
      })
      .returningAll()
      .executeTakeFirstOrThrow();
  }

  async findByUserId(userId: string, limit: number = 100): Promise<AuditLogTable[]> {
    return db
      .selectFrom('audit_logs')
      .selectAll()
      .where('user_id', '=', userId)
      .orderBy('created_at', 'desc')
      .limit(limit)
      .execute();
  }

  async findByAction(action: string, limit: number = 100): Promise<AuditLogTable[]> {
    return db
      .selectFrom('audit_logs')
      .selectAll()
      .where('action', '=', action)
      .orderBy('created_at', 'desc')
      .limit(limit)
      .execute();
  }
}



