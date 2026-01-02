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
    // RDS requires SSL connections
    // If sslmode is in the connection string, pg will use it automatically
    // Otherwise, we can set it here explicitly
    ssl:
      config.database.url.includes('rds.amazonaws.com') ||
      config.database.url.includes('amazonaws.com')
        ? { rejectUnauthorized: false } // RDS uses self-signed certificates
        : undefined,
  }),
});

export const db = new Kysely<Database>({
  dialect,
});
