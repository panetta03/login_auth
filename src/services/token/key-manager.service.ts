import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { config } from '../../config';
import { logger } from '../../utils/logger';
import crypto from 'crypto';

interface KeyPair {
  privateKey: string;
  publicKey: string;
  kid: string;
  createdAt: Date;
}

class KeyManagerService {
  private keys: Map<string, KeyPair> = new Map();
  private currentKid: string | null = null;

  /**
   * Initialize keys from AWS Secrets Manager or generate new ones
   */
  async initializeKeys(): Promise<void> {
    try {
      // Try to load from Secrets Manager
      if (config.nodeEnv === 'production') {
        await this.loadKeysFromSecretsManager();
      } else {
        // In development, generate keys
        this.generateAndStoreKeys();
      }
    } catch (error) {
      logger.warn('Failed to load keys from Secrets Manager, generating new keys', { error });
      this.generateAndStoreKeys();
    }
  }

  /**
   * Load keys from AWS Secrets Manager
   */
  private async loadKeysFromSecretsManager(): Promise<void> {
    const client = new SecretsManagerClient({
      region: config.aws.region,
    });

    const command = new GetSecretValueCommand({
      SecretId: 'jwt-signing-keys',
    });

    const response = await client.send(command);
    
    if (!response.SecretString) {
      throw new Error('JWT signing keys not found in Secrets Manager');
    }

    const keysData = JSON.parse(response.SecretString);
    
    // Load all key versions
    for (const [kid, keyData] of Object.entries(keysData as Record<string, { privateKey: string; publicKey: string; createdAt: string }>)) {
      this.keys.set(kid, {
        privateKey: keyData.privateKey,
        publicKey: keyData.publicKey,
        kid,
        createdAt: new Date(keyData.createdAt),
      });
    }

    // Set current key (latest)
    const latestKey = Array.from(this.keys.values()).sort((a, b) => 
      b.createdAt.getTime() - a.createdAt.getTime()
    )[0];
    this.currentKid = latestKey.kid;

    logger.info('JWT signing keys loaded from Secrets Manager', { keyCount: this.keys.size });
  }

  /**
   * Generate new key pair
   */
  private generateAndStoreKeys(): void {
    const { publicKey: pubKey, privateKey: privKey } = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: {
        type: 'spki',
        format: 'pem',
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem',
      },
    });

    const kid = 'key-1';
    const keyPair: KeyPair = {
      privateKey: privKey,
      publicKey: pubKey,
      kid,
      createdAt: new Date(),
    };

    this.keys.set(kid, keyPair);
    this.currentKid = kid;

    logger.warn('Generated new JWT signing keys (in production, load from AWS Secrets Manager)');
  }

  /**
   * Get current private key for signing
   */
  getPrivateKey(): string {
    if (!this.currentKid) {
      throw new Error('Keys not initialized');
    }
    const key = this.keys.get(this.currentKid);
    if (!key) {
      throw new Error('Current key not found');
    }
    return key.privateKey;
  }

  /**
   * Get public key by kid (for validation)
   */
  getPublicKey(kid?: string): string {
    const keyId = kid || this.currentKid;
    if (!keyId) {
      throw new Error('Key ID not specified and no current key');
    }
    const key = this.keys.get(keyId);
    if (!key) {
      throw new Error(`Key not found: ${keyId}`);
    }
    return key.publicKey;
  }

  /**
   * Get all public keys for JWKS endpoint
   */
  getJWKS(): Array<{ kty: string; kid: string; use: string; alg: string; n: string; e: string }> {
    const jwks: Array<{ kty: string; kid: string; use: string; alg: string; n: string; e: string }> = [];

    for (const key of this.keys.values()) {
      const keyObject = crypto.createPublicKey(key.publicKey);
      const jwk = keyObject.export({ format: 'jwk' });

      jwks.push({
        kty: jwk.kty!,
        kid: key.kid,
        use: 'sig',
        alg: 'RS256',
        n: jwk.n!,
        e: jwk.e!,
      });
    }

    return jwks;
  }

  /**
   * Get current key ID
   */
  getCurrentKid(): string {
    if (!this.currentKid) {
      throw new Error('Keys not initialized');
    }
    return this.currentKid;
  }
}

export const keyManager = new KeyManagerService();




