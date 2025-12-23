# Local Development Setup Guide

## Prerequisites

Before running the auth service locally, you need:

1. **Node.js 20.x or higher**
   - Download from [nodejs.org](https://nodejs.org/)
   - Verify installation: `node --version` (should show v20.x.x or higher)
   - Verify npm: `npm --version`

2. **PostgreSQL 15+** (or use Docker)
   - Download from [postgresql.org](https://www.postgresql.org/download/)
   - Or use Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15-alpine`

3. **Redis** (or use Docker)
   - Download from [redis.io](https://redis.io/download)
   - Or use Docker: `docker run -d -p 6379:6379 redis:7-alpine`

4. **Docker & Docker Compose** (optional, recommended)
   - Download from [docker.com](https://www.docker.com/products/docker-desktop)

## Installation Steps

### Step 1: Install Node.js Dependencies

```bash
npm install
```

This will install all required packages listed in `package.json`.

### Step 2: Set Up Environment Variables

Create a `.env` file in the root directory:

```env
# Environment
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_service
DB_POOL_MAX=20
DB_POOL_MIN=5

# Redis
REDIS_URL=redis://localhost:6379

# AWS (not needed for local dev, but required for production)
AWS_REGION=us-east-1
AWS_SECRETS_MANAGER_SECRET_NAME=googleoauth

# JWT Configuration
JWT_ISSUER=auth-service
JWT_ACCESS_TOKEN_EXPIRY=900
JWT_REFRESH_TOKEN_EXPIRY=2592000

# Google OAuth (REQUIRED - get from Google Cloud Console)
GOOGLE_CLIENT_ID=your-google-client-id-here
GOOGLE_CLIENT_SECRET=your-google-client-secret-here
GOOGLE_REDIRECT_URI=http://localhost:3000/api/v1/auth/callback/google

# Security
SESSION_SECRET=change-me-in-production-use-random-string

# CORS
CORS_ORIGIN=http://localhost:3000

# Logging
LOG_LEVEL=info
```

### Step 3: Set Up Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **Web application**
6. Add authorized redirect URI: `http://localhost:3000/api/v1/auth/callback/google`
7. Copy the **Client ID** and **Client Secret** to your `.env` file

### Step 4: Start PostgreSQL and Redis

**Option A: Using Docker Compose (Recommended)**

```bash
# Start only database services
docker-compose up -d postgres redis

# Verify they're running
docker ps
```

**Option B: Using Local Installations**

Make sure PostgreSQL and Redis are running on your system:
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

### Step 5: Run Database Migrations

```bash
# Set DATABASE_URL if not in .env
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_service

# Run migrations
npm run migrate:up
```

This will create all required database tables.

### Step 6: Start the Development Server

```bash
npm run dev
```

The service will start on `http://localhost:3000`

You should see:
```
Auth service started on port 3000
```

## Verify Installation

### Test Health Endpoint

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Test Readiness Endpoint

```bash
curl http://localhost:3000/ready
```

Expected response:
```json
{
  "status": "ready",
  "checks": {
    "database": "ok",
    "redis": "ok"
  }
}
```

### Test OAuth Login

Open in browser:
```
http://localhost:3000/api/v1/auth/login/google
```

This will redirect you to Google OAuth consent screen.

## Using Docker Compose (All Services)

To run everything in Docker:

```bash
# Start all services
docker-compose up

# Or in background
docker-compose up -d

# View logs
docker-compose logs -f auth-service

# Stop all services
docker-compose down
```

## Troubleshooting

### "Cannot find module 'express'"
- Run `npm install` to install dependencies

### "Connection refused" to PostgreSQL
- Verify PostgreSQL is running: `docker ps` or check local service
- Check DATABASE_URL in `.env` matches your setup

### "Connection refused" to Redis
- Verify Redis is running: `docker ps` or check local service
- Check REDIS_URL in `.env` matches your setup

### "Failed to load OAuth secrets"
- Make sure GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are set in `.env`
- In development, these are read from environment variables (not AWS Secrets Manager)

### Database migration errors
- Make sure PostgreSQL is running and accessible
- Check DATABASE_URL is correct
- Verify database `auth_service` exists (created automatically by docker-compose)

## Next Steps

Once the service is running:

1. **Test OAuth flow**: Visit `http://localhost:3000/api/v1/auth/login/google`
2. **Check API documentation**: See `docs/api/openapi.yaml`
3. **Review integration guide**: See `docs/INTEGRATION.md` for integrating with other services




