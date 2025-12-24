import { db } from '../client';
import type { UserTable } from '../schema';
import { v4 as uuidv4 } from 'uuid';

export class UserRepository {
  async findByEmail(email: string): Promise<UserTable | undefined> {
    return db.selectFrom('users').selectAll().where('email', '=', email).executeTakeFirst();
  }

  async findById(id: string): Promise<UserTable | undefined> {
    return db.selectFrom('users').selectAll().where('id', '=', id).executeTakeFirst();
  }

  async upsertUser(user: {
    email: string;
    name: string | null;
    picture: string | null;
    provider: string;
    provider_id: string;
  }): Promise<UserTable> {
    return db
      .insertInto('users')
      .values({
        id: uuidv4(),
        ...user,
        created_at: new Date(),
        updated_at: new Date(),
      })
      .onConflict((oc) =>
        oc.column('email').doUpdateSet({
          name: (eb) => eb.ref('excluded.name'),
          picture: (eb) => eb.ref('excluded.picture'),
          provider: (eb) => eb.ref('excluded.provider'),
          provider_id: (eb) => eb.ref('excluded.provider_id'),
          updated_at: new Date(),
        })
      )
      .returningAll()
      .executeTakeFirstOrThrow();
  }
}
