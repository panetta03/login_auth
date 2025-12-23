import { db } from '../client';
import type { RefreshTokenTable } from '../schema';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

export class RefreshTokenRepository {
  async createRefreshToken(token: {
    session_id: string;
    user_id: string;
    expires_at: Date;
  }): Promise<RefreshTokenTable> {
    // Generate secure random token
    const tokenValue = crypto.randomBytes(32).toString('hex');

    return db
      .insertInto('refresh_tokens')
      .values({
        id: uuidv4(),
        ...token,
        token: tokenValue,
        created_at: new Date(),
      })
      .returningAll()
      .executeTakeFirstOrThrow();
  }

  async findByToken(token: string): Promise<RefreshTokenTable | undefined> {
    return db
      .selectFrom('refresh_tokens')
      .selectAll()
      .where('token', '=', token)
      .where('revoked_at', 'is', null)
      .where('expires_at', '>', new Date())
      .executeTakeFirst();
  }

  async revokeToken(id: string): Promise<void> {
    await db
      .updateTable('refresh_tokens')
      .set({ revoked_at: new Date() })
      .where('id', '=', id)
      .execute();
  }

  async revokeBySessionId(sessionId: string): Promise<void> {
    await db
      .updateTable('refresh_tokens')
      .set({ revoked_at: new Date() })
      .where('session_id', '=', sessionId)
      .where('revoked_at', 'is', null)
      .execute();
  }

  async updateLastUsed(id: string): Promise<void> {
    await db
      .updateTable('refresh_tokens')
      .set({ last_used_at: new Date() })
      .where('id', '=', id)
      .execute();
  }
}

