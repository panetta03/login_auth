import { Request } from 'express';

export interface OAuthProvider {
  getAuthorizationUrl(req: Request): Promise<string>;
  handleCallback(
    code: string,
    state: string,
    req: Request
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    user: { id: string; email: string; name: string | null; picture: string | null };
  }>;
}

