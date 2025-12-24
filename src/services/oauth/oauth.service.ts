import { Request } from 'express';
import { googleProvider } from './providers/google.provider';
import { OAuthProvider } from './providers/base.provider';

class OAuthService {
  private providers: Map<string, OAuthProvider> = new Map();

  constructor() {
    // Register providers
    this.providers.set('google', googleProvider);
  }

  async initiateLogin(providerName: string, req: Request): Promise<string> {
    const provider = this.providers.get(providerName);
    if (!provider) {
      throw new Error(`Unsupported OAuth provider: ${providerName}`);
    }

    return provider.getAuthorizationUrl(req);
  }

  async handleCallback(
    providerName: string,
    code: string,
    state: string,
    req: Request
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    user: { id: string; email: string; name: string | null; picture: string | null };
  }> {
    const provider = this.providers.get(providerName);
    if (!provider) {
      throw new Error(`Unsupported OAuth provider: ${providerName}`);
    }

    return provider.handleCallback(code, state, req);
  }
}

export const oauthService = new OAuthService();
