import { db } from '../client';
import type { SessionTable } from '../schema';
import { v4 as uuidv4 } from 'uuid';

export class SessionRepository {
  async createSession(session: {
    user_id: string;
    access_token_jti: string;
    expires_at: Date;
    ip_address: string | null;
    user_agent: string | null;
  }): Promise<SessionTable> {
    return db
      .insertInto('sessions')
      .values({
        id: uuidv4(),
        ...session,
        last_activity_at: new Date(),
        created_at: new Date(),
      })
      .returningAll()
      .executeTakeFirstOrThrow();
  }

  async findById(id: string): Promise<SessionTable | undefined> {
    return db.selectFrom('sessions').selectAll().where('id', '=', id).executeTakeFirst();
  }

  async findByAccessTokenJti(jti: string): Promise<SessionTable | undefined> {
    return db
      .selectFrom('sessions')
      .selectAll()
      .where('access_token_jti', '=', jti)
      .where('revoked_at', 'is', null)
      .executeTakeFirst();
  }

  async revokeSession(id: string): Promise<void> {
    await db.updateTable('sessions').set({ revoked_at: new Date() }).where('id', '=', id).execute();
  }

  async revokeAllUserSessions(userId: string): Promise<void> {
    await db
      .updateTable('sessions')
      .set({ revoked_at: new Date() })
      .where('user_id', '=', userId)
      .where('revoked_at', 'is', null)
      .execute();
  }

  async updateActivity(sessionId: string): Promise<void> {
    await db
      .updateTable('sessions')
      .set({ last_activity_at: new Date() })
      .where('id', '=', sessionId)
      .execute();
  }

  async getUserSessions(userId: string): Promise<SessionTable[]> {
    return db
      .selectFrom('sessions')
      .selectAll()
      .where('user_id', '=', userId)
      .where('revoked_at', 'is', null)
      .where('expires_at', '>', new Date())
      .orderBy('created_at', 'desc')
      .execute();
  }
}
