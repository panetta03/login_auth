import dotenv from 'dotenv';

dotenv.config();

interface Config {
  nodeEnv: string;
  port: number;
  database: {
    url: string;
    poolMax: number;
    poolMin: number;
  };
  redis: {
    url: string;
  };
  aws: {
    region: string;
    secretsManagerSecretName: string;
  };
  jwt: {
    issuer: string;
    accessTokenExpiry: number; // seconds
    refreshTokenExpiry: number; // seconds
  };
  oauth: {
    google: {
      clientId: string;
      clientSecret: string;
      redirectUri: string;
    };
  };
  security: {
    sessionSecret: string;
  };
  corsOrigin: string;
  logLevel: string;
}

export const config: Config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  database: {
    url: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/auth_service',
    poolMax: parseInt(process.env.DB_POOL_MAX || '20', 10),
    poolMin: parseInt(process.env.DB_POOL_MIN || '5', 10),
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },
  aws: {
    region: process.env.AWS_REGION || 'us-east-1',
    secretsManagerSecretName: process.env.AWS_SECRETS_MANAGER_SECRET_NAME || 'googleoauth',
  },
  jwt: {
    issuer: process.env.JWT_ISSUER || 'auth-service',
    accessTokenExpiry: parseInt(process.env.JWT_ACCESS_TOKEN_EXPIRY || '900', 10), // 15 minutes
    refreshTokenExpiry: parseInt(process.env.JWT_REFRESH_TOKEN_EXPIRY || '2592000', 10), // 30 days
  },
  oauth: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
      redirectUri: process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/api/v1/auth/callback/google',
    },
  },
  security: {
    sessionSecret: process.env.SESSION_SECRET || 'change-me-in-production',
  },
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  logLevel: process.env.LOG_LEVEL || 'info',
};

