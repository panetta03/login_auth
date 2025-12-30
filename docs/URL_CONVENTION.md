# URL Convention for Auth Service

## Standard URL Structure

The auth service follows a consistent URL convention that includes the environment:

### Current (API Gateway)
```
https://{api-id}.execute-api.{region}.amazonaws.com/{environment}/api/v1/auth/callback/{provider}
```

**Example:**
- Dev: `https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/callback/google`
- Prod: `https://{api-id}.execute-api.us-east-2.amazonaws.com/prod/api/v1/auth/callback/google`

### Future (Custom Domain - Recommended)
When using a custom domain, we recommend the **subdomain-based** approach:

```
https://{environment}.auth.omnipan.com/api/v1/auth/callback/{provider}
```

**Examples:**
- Dev: `https://dev.auth.omnipan.com/api/v1/auth/callback/google`
- Staging: `https://staging.auth.omnipan.com/api/v1/auth/callback/google`
- Prod: `https://auth.omnipan.com/api/v1/auth/callback/google` (or `prod.auth.omnipan.com`)

### Alternative (Custom Domain - Path-based)
If subdomain routing is not available:

```
https://auth.omnipan.com/{environment}/api/v1/auth/callback/{provider}
```

**Examples:**
- Dev: `https://auth.omnipan.com/dev/api/v1/auth/callback/google`
- Prod: `https://auth.omnipan.com/prod/api/v1/auth/callback/google`

## OAuth Redirect URI Configuration

### Google OAuth Console
Add the redirect URI for each environment:

**Development:**
```
https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/callback/google
```

**Production:**
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod/api/v1/auth/callback/google
```

Or with custom domain:
```
https://dev.auth.omnipan.com/api/v1/auth/callback/google
https://auth.omnipan.com/api/v1/auth/callback/google
```

## Environment Variables

The redirect URI is configured via the `GOOGLE_REDIRECT_URI` environment variable in the ECS task definition:

```bash
GOOGLE_REDIRECT_URI=https://{api-id}.execute-api.{region}.amazonaws.com/{environment}/api/v1/auth/callback/google
```

## API Endpoints

All API endpoints follow the same convention:

- Health: `/{environment}/health`
- OAuth Login: `/{environment}/api/v1/auth/login/{provider}`
- OAuth Callback: `/{environment}/api/v1/auth/callback/{provider}`
- JWKS: `/{environment}/.well-known/jwks.json`

