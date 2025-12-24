import { config } from '../config';
import { logger } from './logger';

interface OAuthSecrets {
  GOOGLE_CLIENT_ID: string;
  GOOGLE_CLIENT_SECRET: string;
}

let cachedSecrets: OAuthSecrets | null = null;

export async function getSecrets(): Promise<OAuthSecrets> {
  // Return cached secrets if available
  if (cachedSecrets) {
    return cachedSecrets;
  }

  // In development or test, use environment variables
  if (config.nodeEnv === 'development' || config.nodeEnv === 'test') {
    const clientId = config.oauth.google.clientId?.trim();
    const clientSecret = config.oauth.google.clientSecret?.trim();

    if (clientId && clientSecret) {
      cachedSecrets = {
        GOOGLE_CLIENT_ID: clientId,
        GOOGLE_CLIENT_SECRET: clientSecret,
      };
      logger.info('OAuth secrets loaded from environment variables');
      return cachedSecrets;
    } else {
      throw new Error(
        'OAuth credentials not configured. Please set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables.'
      );
    }
  }

  // In production, fetch from AWS Secrets Manager
  // Lazy import to avoid issues in test environments
  const { SecretsManagerClient, GetSecretValueCommand } = await import(
    '@aws-sdk/client-secrets-manager'
  );

  // AWS SDK will automatically use credentials from:
  // 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  // 2. ~/.aws/credentials file
  // 3. IAM role (if running on EC2/ECS)
  try {
    const client = new SecretsManagerClient({
      region: config.aws.region,
      // Credentials will be automatically loaded from default credential chain
    });

    const command = new GetSecretValueCommand({
      SecretId: config.aws.secretsManagerSecretName,
    });

    const response = await client.send(command);

    if (!response.SecretString) {
      throw new Error('Secret string not found');
    }

    cachedSecrets = JSON.parse(response.SecretString) as OAuthSecrets;
    logger.info('Secrets loaded from AWS Secrets Manager');

    return cachedSecrets;
  } catch (error) {
    logger.error('Failed to fetch secrets from AWS Secrets Manager', { error });
    throw new Error('Failed to load OAuth secrets from AWS Secrets Manager');
  }
}
