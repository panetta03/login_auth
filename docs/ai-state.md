# AI State Documentation

**Quick Reference**: For integrating this auth service into other microservices, see **[INTEGRATION.md](INTEGRATION.md)**.

---

This document tracks the current state of the auth-service repository to help AI agents understand context and progress.

## Project Status

**Status**: Planning Phase → Implementation Ready
**Last Updated**: 2024-12-19
**Current Phase**: Technical planning complete, ready for implementation

## Architecture Decisions

### Technology Stack
- **Runtime**: Node.js 20.x LTS
- **Language**: TypeScript 5.x
- **Framework**: Express.js
- **Database**: PostgreSQL 15+ (RDS)
- **Database Access**: Kysely (SQL-first, type-safe query builder)
- **Caching**: Redis (ElastiCache)
- **OAuth**: Passport.js
- **JWT**: jsonwebtoken with RS256

### Why Kysely over Prisma?
- **Performance**: No ORM runtime overhead, predictable query performance
- **Visibility**: Full SQL visibility for auditing and debugging
- **Security**: Explicit SQL queries make security auditing easier
- **Type Safety**: TypeScript types without abstraction complexity
- **Microservice Best Practice**: Services own their databases, expose APIs (not shared ORM schemas)

### Why Node.js/TypeScript?
- Industry standard for auth services (Auth0, Okta patterns)
- Excellent async performance for high throughput
- Strong OAuth ecosystem
- TypeScript for type safety and better AI agent interaction
- Fast development iteration

### Why Express.js over Nest.js?
- Lighter weight, more flexible
- Simpler for single developer
- Less opinionated structure
- Faster to get started

### API Design
- REST API with OpenAPI 3.0 specification
- MCP not needed (MCP is for AI-to-tool communication, not HTTP APIs)
- OpenAPI specs enable AI agent understanding

## Current Implementation Status

### Completed
- ✅ Technical plan created (comprehensive, production-ready)
- ✅ Architecture diagrams (Mermaid)
- ✅ Database schema design (Kysely, SQL-first)
- ✅ API endpoint design
- ✅ Cursor rules established
- ✅ CI/CD pipeline design
- ✅ Production readiness documentation:
  - ✅ Scaling & High Availability strategy
  - ✅ Token revocation model (detailed)
  - ✅ Audit logging & compliance (retention, failure behavior)
  - ✅ Observability & monitoring (metrics, tracing)
  - ✅ Error handling & resilience (retry strategies, timeouts)
  - ✅ Testing strategy (load testing, fault injection)
  - ✅ Secrets & key management (rotation strategy)
  - ✅ Migration & versioning strategy
  - ✅ Cross-service integration (token validation, rate limiting)

### In Progress
- ⏳ Project structure setup
- ⏳ Initial code implementation

### Pending
- ⬜ Phase 1: Foundation setup
- ⬜ Phase 2: OAuth & JWT implementation
- ⬜ Phase 3: API endpoints
- ⬜ Phase 4: Database & caching
- ⬜ Phase 5: Testing (including load testing)
- ⬜ Phase 6: Infrastructure (Terraform)
- ⬜ Phase 7: CI/CD
- ⬜ Phase 8: Documentation

## Key Features

### Implemented
- None yet (planning phase)

### Planned
1. **OAuth Authentication**
   - Google OAuth (first provider)
   - Extensible provider factory pattern
   - State management in Redis

2. **JWT Token Management**
   - RS256 signing (asymmetric keys)
   - Access tokens (15 min expiration)
   - Refresh tokens (30 days, stored in DB)
   - Token blacklisting in Redis
   - Activity-based invalidation

3. **Activity Tracking**
   - Track last_activity_at in Redis + PostgreSQL
   - Invalidate tokens if inactive > 15 minutes
   - Grace period: 30 minutes
   - Refresh token max inactivity: 7 days

4. **API Endpoints**
   - `/api/v1/auth/login/{provider}` - Initiate OAuth
   - `/api/v1/auth/callback/{provider}` - OAuth callback
   - `/api/v1/auth/token/refresh` - Refresh token
   - `/api/v1/auth/token/validate` - Validate token
   - `/api/v1/auth/logout` - Revoke session
   - `/api/v1/auth/me` - Get current user
   - `/health` - Health check
   - `/ready` - Readiness check

5. **Database Schema**
   - SQL migration files (001_create_users.sql, etc.)
   - Kysely type definitions (schema.ts)
   - Repository pattern for data access
   - User, Session, RefreshToken, AuditLog tables

6. **Infrastructure**
   - AWS ECS Fargate
   - AWS API Gateway (REST API)
   - RDS PostgreSQL (Multi-AZ)
   - ElastiCache Redis
   - AWS Secrets Manager
   - Terraform for IaC

## Known Issues

None yet (pre-implementation)

## TODOs

### High Priority
1. Set up project structure
2. Initialize Prisma schema
3. Set up Express.js with middleware
4. Implement Google OAuth provider
5. Implement JWT token generation

### Medium Priority
1. Set up Redis integration
2. Implement activity tracking
3. Create API endpoints
4. Write tests

### Low Priority
1. Add additional OAuth providers
2. Implement advanced features (MFA, device management)
3. Performance optimization

## Compliance Considerations

### SOC2
- ✅ Audit logging designed (AuditLog model)
- ✅ Access controls (JWT validation)
- ✅ Encryption at rest (RDS, Secrets Manager)
- ✅ Encryption in transit (TLS, Redis)

### GDPR
- ✅ User data export capability (via user ID)
- ✅ User data deletion capability (cascade deletes)
- ✅ Data minimization (only OAuth data)
- ✅ Consent tracking (OAuth consent)

### Financial Compliance
- ✅ Complete audit trail
- ✅ Non-repudiation (JWT signatures)
- ✅ Token revocation
- ✅ Activity monitoring

## File Structure

```
auth-service/
├── .cursorrules              ✅ Created
├── docs/
│   ├── ai-state.md          ✅ Created (this file)
│   ├── architecture.md      ⬜ TODO
│   └── api/
│       └── openapi.yaml     ⬜ TODO
├── infrastructure/
│   └── terraform/           ⬜ TODO
├── src/                     ⬜ TODO
├── tests/                   ⬜ TODO
└── TECHNICAL_PLAN.md        ✅ Created
```

## Next Steps

1. Initialize Node.js/TypeScript project
2. Set up Prisma with schema
3. Create Express.js app structure
4. Implement Google OAuth
5. Implement JWT token management

## Notes for AI Agents

- Always check this file for current state before making changes
- Update this file when completing major milestones
- Follow patterns established in `.cursorrules`
- Use TypeScript strict mode
- Write tests for new features
- Update OpenAPI spec when adding/changing endpoints
- Use Kysely for all database operations (SQL-first approach)
- Write explicit SQL queries - Kysely provides type safety without hiding SQL
- Never log sensitive data

## Architecture Diagrams

See `TECHNICAL_PLAN.md` for Mermaid diagrams:
- System architecture
- Authentication flow
- Token lifecycle

## API Documentation

OpenAPI specification will be in `docs/api/openapi.yaml` (to be created).

## Infrastructure

Terraform configuration will be in `infrastructure/terraform/` (to be created).

