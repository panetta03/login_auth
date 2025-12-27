# Auth Service Integration Guide

**Quick Reference for Microservice Integration**

This guide helps AI agents and developers quickly integrate the Auth Service into other microservices. The Auth Service issues JWT access tokens that downstream services validate independently.

---

## Quick Start (5-Minute Integration)

### 1. Fetch Public Key (JWKS)

```typescript
// Fetch and cache the public key from Auth Service
const JWKS_URL = 'https://api.example.com/.well-known/jwks.json';

async function getPublicKey(): Promise<string> {
  const response = await fetch(JWKS_URL, {
    headers: { 'Cache-Control': 'max-age=600' } // Cache for 10 minutes
  });
  const jwks = await response.json();
  // Use jwks-rsa library to convert JWKS to PEM format
  return convertJWKSToPEM(jwks.keys[0]);
}
```

### 2. Validate JWT in Middleware

```typescript
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

// Initialize JWKS client (handles caching automatically)
const client = jwksClient({
  jwksUri: 'https://api.example.com/.well-known/jwks.json',
  cache: true,
  cacheMaxAge: 600000, // 10 minutes
});

// Middleware to validate JWT
export async function validateAuthToken(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  try {
    // Get signing key from JWKS
    const key = await client.getSigningKey();
    const publicKey = key.getPublicKey();
    
    // Verify JWT
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
      issuer: 'auth-service', // Optional: verify issuer
    });

    // Attach user info to request
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      provider: decoded.provider,
    };

    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

### 3. Use in Routes

```typescript
app.get('/api/protected', validateAuthToken, (req, res) => {
  // req.user is available here
  res.json({ message: `Hello ${req.user.email}` });
});
```

---

## Integration Patterns

### Pattern 1: Local JWT Validation (Recommended)

**When to use:** Standard microservice authentication (99% of cases)

**Benefits:**
- ✅ No network calls (validates locally)
- ✅ Low latency (< 5ms)
- ✅ Scales independently
- ✅ Works offline (once key is cached)

**Implementation:**

```typescript
// middleware/auth.middleware.ts
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const jwksClient = jwksClient({
  jwksUri: process.env.AUTH_JWKS_URL || 'https://api.example.com/.well-known/jwks.json',
  cache: true,
  cacheMaxAge: 600000, // 10 minutes
  rateLimit: true,
  jwksRequestsPerMinute: 5, // Limit JWKS requests
});

export interface AuthUser {
  id: string;
  email: string;
  provider: string;
  sid?: string; // Session ID
}

export async function validateToken(token: string): Promise<AuthUser> {
  // Get signing key
  const key = await jwksClient.getSigningKey();
  const publicKey = key.getPublicKey();
  
  // Verify JWT
  const decoded = jwt.verify(token, publicKey, {
    algorithms: ['RS256'],
  }) as jwt.JwtPayload;

  return {
    id: decoded.sub!,
    email: decoded.email!,
    provider: decoded.provider!,
    sid: decoded.sid,
  };
}

// Express middleware
export function authMiddleware() {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const token = extractToken(req);
      const user = await validateToken(token);
      req.user = user;
      next();
    } catch (error) {
      res.status(401).json({ error: 'Unauthorized' });
    }
  };
}

function extractToken(req: Request): string {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing or invalid authorization header');
  }
  return authHeader.substring(7);
}
```

### Pattern 2: Introspection Endpoint (Optional)

**When to use:**
- Critical operations requiring immediate revocation checks
- Services that cannot manage public keys
- Debugging/admin workflows

**Tradeoffs:**
- ❌ Network latency (~50-100ms)
- ❌ Additional load on auth service
- ✅ Immediate revocation validation

**Implementation:**

```typescript
// Only use for critical operations
async function validateTokenWithIntrospection(token: string): Promise<AuthUser> {
  const response = await fetch('https://api.example.com/api/v1/auth/token/validate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': process.env.AUTH_SERVICE_API_KEY!, // Required for introspection
    },
    body: JSON.stringify({ token }),
  });

  if (!response.ok) {
    throw new Error('Token validation failed');
  }

  const result = await response.json();
  if (!result.valid) {
    throw new Error('Invalid token');
  }

  return result.user;
}
```

---

## Framework-Specific Examples

### Express.js

```typescript
import express from 'express';
import { authMiddleware } from './middleware/auth.middleware';

const app = express();

// Apply to all routes
app.use('/api', authMiddleware());

// Or apply to specific routes
app.get('/api/protected', authMiddleware(), (req, res) => {
  res.json({ user: req.user });
});
```

### Fastify

```typescript
import Fastify from 'fastify';
import { validateToken } from './middleware/auth.middleware';

const fastify = Fastify();

// Plugin for authentication
fastify.decorate('authenticate', async (request, reply) => {
  const token = request.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    reply.code(401).send({ error: 'Unauthorized' });
    return;
  }
  
  try {
    request.user = await validateToken(token);
  } catch (error) {
    reply.code(401).send({ error: 'Invalid token' });
  }
});

// Use in routes
fastify.get('/api/protected', {
  preHandler: [fastify.authenticate],
}, async (request, reply) => {
  return { user: request.user };
});
```

### Nest.js

```typescript
// auth.guard.ts
import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { validateToken } from './auth.utils';

@Injectable()
export class AuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new UnauthorizedException();
    }

    try {
      request.user = await validateToken(token);
      return true;
    } catch (error) {
      throw new UnauthorizedException();
    }
  }
}

// Use in controllers
@Controller('api')
@UseGuards(AuthGuard)
export class ProtectedController {
  @Get('protected')
  getProtected(@Request() req) {
    return { user: req.user };
  }
}
```

---

## Token Structure

### Access Token (JWT) Claims

```typescript
interface JWTPayload {
  sub: string;        // User ID
  email: string;       // User email
  provider: string;   // OAuth provider (e.g., "google")
  iat: number;        // Issued at (timestamp)
  exp: number;        // Expiration (timestamp)
  jti: string;        // JWT ID (for blacklisting)
  sid?: string;       // Session ID (optional, for session management)
}
```

### Token Expiration

- **Access Token**: 15 minutes
- **Refresh Token**: 30 days (opaque, stored in auth service)

**Handling Expired Tokens:**

```typescript
// Client-side: Refresh token flow
async function refreshAccessToken(refreshToken: string): Promise<string> {
  const response = await fetch('https://api.example.com/api/v1/auth/token/refresh', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });

  if (!response.ok) {
    throw new Error('Token refresh failed');
  }

  const { accessToken } = await response.json();
  return accessToken;
}
```

---

## Error Handling

### Standard Error Responses

```typescript
// 401 Unauthorized - Missing or invalid token
{
  "error": "Unauthorized",
  "message": "Missing or invalid authorization token"
}

// 401 Unauthorized - Expired token
{
  "error": "Unauthorized",
  "message": "Token expired"
}

// 403 Forbidden - Valid token but insufficient permissions
{
  "error": "Forbidden",
  "message": "Insufficient permissions"
}
```

### Error Handling Middleware

```typescript
export function handleAuthError(error: Error, req: Request, res: Response, next: NextFunction) {
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  if (error.name === 'TokenExpiredError') {
    return res.status(401).json({ 
      error: 'Token expired',
      code: 'TOKEN_EXPIRED' // Client can use this to trigger refresh
    });
  }

  next(error); // Pass to global error handler
}
```

---

## Environment Configuration

### Required Environment Variables

```bash
# Auth Service JWKS URL
AUTH_JWKS_URL=https://api.example.com/.well-known/jwks.json

# Optional: For introspection endpoint (if used)
AUTH_SERVICE_API_KEY=your-api-key-here
AUTH_SERVICE_URL=https://api.example.com/api/v1
```

### Configuration Example

```typescript
// config/auth.config.ts
export const authConfig = {
  jwksUrl: process.env.AUTH_JWKS_URL!,
  issuer: process.env.AUTH_ISSUER || 'auth-service',
  algorithms: ['RS256'] as const,
  cacheMaxAge: 600000, // 10 minutes
};
```

---

## Testing Integration

### Mock JWT for Testing

```typescript
// test/utils/auth.test-utils.ts
import jwt from 'jsonwebtoken';

export function createTestToken(user: { id: string; email: string; provider: string }): string {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      provider: user.provider,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 900, // 15 minutes
      jti: 'test-token-id',
    },
    'test-secret-key', // Use test key in test environment
    { algorithm: 'RS256' }
  );
}
```

### Integration Test Example

```typescript
import request from 'supertest';
import { createTestToken } from './test-utils';

describe('Protected Endpoint', () => {
  it('should allow access with valid token', async () => {
    const token = createTestToken({
      id: 'user-123',
      email: 'test@example.com',
      provider: 'google',
    });

    const response = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body.user.email).toBe('test@example.com');
  });

  it('should reject request without token', async () => {
    await request(app)
      .get('/api/protected')
      .expect(401);
  });
});
```

---

## Best Practices

### ✅ DO

- **Cache JWKS keys** (10-minute cache recommended)
- **Validate tokens locally** (use JWKS endpoint)
- **Handle token expiration gracefully** (return 401 with clear error)
- **Log authentication failures** (for security monitoring)
- **Use HTTPS** (always, for token transmission)
- **Validate token structure** (check required claims)

### ❌ DON'T

- **Don't call introspection endpoint on every request** (use for critical operations only)
- **Don't store tokens in localStorage** (use httpOnly cookies or secure storage)
- **Don't log full tokens** (log only token IDs/jti)
- **Don't skip token validation** (always verify signature)
- **Don't trust client-provided user IDs** (use `sub` from validated token)

---

## Common Integration Scenarios

### Scenario 1: User Profile Service

```typescript
// Get user ID from validated token
app.get('/api/users/me', authMiddleware(), (req, res) => {
  // req.user.id is guaranteed to be valid (from validated JWT)
  return getUserProfile(req.user.id);
});
```

### Scenario 2: Resource Authorization

```typescript
// Check if user owns resource
app.get('/api/resources/:id', authMiddleware(), async (req, res) => {
  const resource = await getResource(req.params.id);
  
  if (resource.userId !== req.user.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  res.json(resource);
});
```

### Scenario 3: Multi-Service Request

```typescript
// Forward token to downstream service
app.get('/api/aggregated-data', authMiddleware(), async (req, res) => {
  const token = req.headers.authorization; // Extract from original request
  
  // Forward token to other microservices
  const data1 = await fetch('https://service1.example.com/api/data', {
    headers: { Authorization: token },
  });
  
  const data2 = await fetch('https://service2.example.com/api/data', {
    headers: { Authorization: token },
  });
  
  res.json({ data1, data2 });
});
```

---

## Troubleshooting

### Issue: "Invalid token" errors

**Possible causes:**
1. Token expired (check `exp` claim)
2. Wrong public key (verify JWKS URL)
3. Token not from auth service (check issuer)

**Solution:**
```typescript
// Add detailed error logging
try {
  const decoded = jwt.verify(token, publicKey, { algorithms: ['RS256'] });
} catch (error) {
  console.error('Token validation failed:', {
    error: error.message,
    tokenExpired: error.name === 'TokenExpiredError',
    tokenInvalid: error.name === 'JsonWebTokenError',
  });
  throw error;
}
```

### Issue: JWKS fetch failures

**Solution:**
```typescript
// Add retry logic for JWKS fetching
const jwksClient = jwksClient({
  jwksUri: process.env.AUTH_JWKS_URL!,
  cache: true,
  requestHeaders: {}, // Add custom headers if needed
  timeout: 30000, // 30 second timeout
  // Retry on failure
  getKeysInterceptor: async () => {
    // Custom retry logic if needed
  },
});
```

---

## API Reference

### Auth Service Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/.well-known/jwks.json` | GET | Get public keys for JWT validation |
| `/auth/token/validate` | POST | Introspect token (optional, for critical operations) |
| `/auth/token/refresh` | POST | Refresh access token (client-side) |
| `/auth/me` | GET | Get current user info (requires valid token) |

### JWKS Response Format

```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "key-1",
      "use": "sig",
      "n": "...",
      "e": "AQAB"
    }
  ]
}
```

---

## Additional Resources

- **Technical Plan**: See `TECHNICAL_PLAN.md` for detailed architecture
- **OpenAPI Spec**: See `docs/api/openapi.yaml` for complete API documentation
- **Architecture Diagrams**: See `docs/diagrams/architecture.mmd` for system diagrams

---

## Quick Checklist

Before deploying your microservice with auth integration:

- [ ] JWKS URL configured correctly
- [ ] Token validation middleware implemented
- [ ] Error handling for expired/invalid tokens
- [ ] Tests written for auth middleware
- [ ] HTTPS enabled (required for token transmission)
- [ ] Logging configured (without logging full tokens)
- [ ] Rate limiting considered (if using introspection endpoint)

---

**Last Updated**: See `docs/ai-state.md` for current implementation status.

