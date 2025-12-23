import { Kysely, PostgresDialect } from 'kysely';
import { Pool } from 'pg';
import { config } from '../config';
import type { Database } from './schema';

const dialect = new PostgresDialect({
  pool: new Pool({
    connectionString: config.database.url,
    max: config.database.poolMax,
    min: config.database.poolMin,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  }),
});

export const db = new Kysely<Database>({
  dialect,
});

