import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
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

  // In development, use environment variables
  if (config.nodeEnv === 'development' && config.oauth.google.clientId) {
    cachedSecrets = {
      GOOGLE_CLIENT_ID: config.oauth.google.clientId,
      GOOGLE_CLIENT_SECRET: config.oauth.google.clientSecret,
    };
    return cachedSecrets;
  }

  // In production, fetch from AWS Secrets Manager
  try {
    const client = new SecretsManagerClient({
      region: config.aws.region,
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
    throw new Error('Failed to load OAuth secrets');
  }
}

