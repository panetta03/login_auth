# Authentication Microservice

Secure OAuth authentication microservice built with Node.js/TypeScript, Express.js, and PostgreSQL. Designed for microservice architectures with AWS ECS and API Gateway.

## Quick Links

- **[Integration Guide](docs/INTEGRATION.md)** - Quick reference for integrating this auth service into other microservices (start here for integration)
- **[Technical Plan](TECHNICAL_PLAN.md)** - Complete architecture and implementation details
- **[AI State](docs/ai-state.md)** - Current implementation status and decisions
- **[Architecture Diagrams](docs/diagrams/architecture.mmd)** - System architecture visualizations

## Features

- ✅ OAuth 2.0 / OpenID Connect (Google, extensible to other providers)
- ✅ JWT access tokens (RS256, 15-minute expiration)
- ✅ Refresh tokens (30-day expiration, activity-based)
- ✅ Token blacklisting and revocation
- ✅ Activity tracking and session management
- ✅ API-first design with OpenAPI 3.0
- ✅ AWS ECS + API Gateway deployment ready
- ✅ SOC2, GDPR, and financial compliance considerations

## Quick Integration

For microservices integrating with this auth service, see the **[Integration Guide](docs/INTEGRATION.md)**.

**5-Minute Integration:**
1. Fetch public key from `/.well-known/jwks.json`
2. Validate JWT tokens locally using `jwks-rsa`
3. Extract user info from validated token claims

See `docs/INTEGRATION.md` for complete examples and patterns.

## Development Status

✅ **Implementation Complete** - All core features implemented. Ready for testing and deployment.

## Local Development Setup

### Prerequisites

- **Node.js 20.x** or higher ([Download](https://nodejs.org/))
- **PostgreSQL 15+** (or use Docker Compose)
- **Redis** (or use Docker Compose)
- **Docker & Docker Compose** (optional, for containerized local development)

### Quick Start

1. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   # Copy example environment file
   cp .env.example .env
   
   # Edit .env and add your Google OAuth credentials:
   # GOOGLE_CLIENT_ID=your-client-id
   # GOOGLE_CLIENT_SECRET=your-client-secret
   ```

3. **Set up git hooks (optional but recommended):**
   ```bash
   # Windows PowerShell
   .\scripts\setup-git-hooks.ps1
   
   # Linux/Mac
   chmod +x scripts/setup-git-hooks.sh
   ./scripts/setup-git-hooks.sh
   ```
   This installs a pre-commit hook that runs CI checks before each commit, ensuring code quality matches CI requirements.

4. **Start PostgreSQL and Redis (using Docker Compose):**
   ```bash
   docker-compose up -d postgres redis
   ```

5. **Run database migrations:**
   ```bash
   npm run migrate:up
   ```

6. **Start the development server:**
   ```bash
   npm run dev
   ```

   The service will be available at `http://localhost:3000`

### Using Docker Compose (All-in-One)

```bash
# Start all services (PostgreSQL, Redis, Auth Service)
docker-compose up

# Or run in background
docker-compose up -d
```

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_service
REDIS_URL=redis://localhost:6379
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/api/v1/auth/callback/google
JWT_ISSUER=auth-service
CORS_ORIGIN=http://localhost:3000
```

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:3000/api/v1/auth/callback/google`
6. Copy Client ID and Client Secret to `.env` file

#### GitHub Secrets (for CI/CD)

For CI/CD to work, you must add the Google OAuth credentials as GitHub Secrets:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:
   - **Name**: `GOOGLE_CLIENT_ID`
     - **Value**: Your Google OAuth Client ID (same as in `.env`)
   - **Name**: `GOOGLE_CLIENT_SECRET`
     - **Value**: Your Google OAuth Client Secret (same as in `.env`)

These secrets are required for integration tests to run in CI. The tests use real Google OAuth credentials to verify the authentication flow works correctly.

### Testing the API

Once running, test the health endpoint:
```bash
curl http://localhost:3000/health
```

Test OAuth login:
```bash
# This will redirect to Google OAuth
curl http://localhost:3000/api/v1/auth/login/google
```

## Technology Stack

- **Runtime**: Node.js 20.x LTS
- **Language**: TypeScript 5.x
- **Framework**: Express.js
- **Database**: PostgreSQL 15+ (Kysely for queries)
- **Caching**: Redis (ElastiCache)
- **Infrastructure**: AWS ECS Fargate + API Gateway
- **IaC**: Terraform

## Infrastructure (Terraform)

### Local Development

For local Terraform development, see the [Terraform README](infrastructure/terraform/README.md).

**Quick Start:**
```bash
# 1. Set up backend configuration
cd infrastructure/terraform
cp backend.local.hcl.example backend.local.hcl
# Edit backend.local.hcl with your values

# 2. Set environment variables
export TF_VAR_db_username="your_db_user"
export TF_VAR_db_password="your_db_password"

# 3. Initialize and plan
terraform init -backend-config=backend.local.hcl
terraform plan -var-file=environments/dev/terraform.tfvars
```

**Using Helper Scripts:**
```bash
# Windows PowerShell
.\infrastructure\terraform\scripts\terraform-local.ps1 plan dev

# Linux/Mac
chmod +x infrastructure/terraform/scripts/terraform-local.sh
./infrastructure/terraform/scripts/terraform-local.sh plan dev
```

### GitHub Actions Deployment

For GitHub Actions setup, see the [GitHub Setup Guide](docs/GITHUB_SETUP.md).

**Required GitHub Secrets:**
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - AWS credentials
- `DB_USERNAME` / `DB_PASSWORD` - Database credentials for RDS
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` - OAuth credentials (for tests)

**Repository Variables:**
- `TERRAFORM_AUTO_APPLY` - Set to `"true"` for auto-apply on push (optional)

## Documentation

- `docs/INTEGRATION.md` - Integration guide for other microservices
- `docs/GITHUB_SETUP.md` - GitHub Actions and secrets configuration
- `docs/TERRAFORM_LOCAL_VS_GITHUB.md` - Terraform local vs GitHub Actions best practices
- `infrastructure/README.md` - Infrastructure setup overview
- `infrastructure/terraform/README.md` - Terraform local development guide
- `TECHNICAL_PLAN.md` - Complete technical specification
- `docs/ai-state.md` - AI agent context and decisions
- `docs/diagrams/architecture.mmd` - Architecture diagrams
- `.cursorrules` - Development guidelines and patterns
