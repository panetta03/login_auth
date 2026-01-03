import { Kysely, PostgresDialect } from 'kysely';
import { Pool } from 'pg';
import { config } from '../config';
import type { Database } from './schema';

// Determine if this is an RDS connection (requires SSL)
const isRdsConnection =
  config.database.url.includes('rds.amazonaws.com') ||
  config.database.url.includes('amazonaws.com');

const dialect = new PostgresDialect({
  pool: new Pool({
    connectionString: config.database.url,
    max: config.database.poolMax,
    min: config.database.poolMin,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    // RDS requires SSL connections with self-signed certificates
    // We must not reject unauthorized certificates for RDS
    ssl: isRdsConnection
      ? {
          rejectUnauthorized: false, // RDS uses self-signed certificates
        }
      : undefined,
  }),
});

export const db = new Kysely<Database>({
  dialect,
});
