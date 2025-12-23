# Quick Start Guide

## Prerequisites Installation

### 1. Install Node.js 20.x

**Windows:**
1. Download Node.js 20.x LTS from [nodejs.org](https://nodejs.org/)
2. Run the installer
3. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

**macOS (using Homebrew):**
```bash
brew install node@20
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Install Docker Desktop (Optional but Recommended)

Download from [docker.com](https://www.docker.com/products/docker-desktop)

Docker allows you to run PostgreSQL and Redis without installing them locally.

## Installation Steps

### Step 1: Install Dependencies

```bash
npm install
```

This installs all required packages from `package.json`.

### Step 2: Create Environment File

Create a `.env` file in the root directory:

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

**Important:** Replace `your-google-client-id` and `your-google-client-secret` with your actual Google OAuth credentials.

### Step 3: Start PostgreSQL and Redis

**Option A: Using Docker (Recommended)**

```bash
# Start database services
docker-compose up -d postgres redis

# Verify they're running
docker ps
```

**Option B: Local Installation**

Make sure PostgreSQL and Redis are installed and running on your system.

### Step 4: Run Database Migrations

```bash
npm run migrate:up
```

This creates all required database tables.

### Step 5: Start the Server

```bash
npm run dev
```

The service will start on `http://localhost:3000`

## Verify It's Working

### Test Health Endpoint

```bash
curl http://localhost:3000/health
```

Expected:
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

### Test Readiness

```bash
curl http://localhost:3000/ready
```

Expected:
```json
{
  "status": "ready",
  "checks": {
    "database": true,
    "redis": true
  }
}
```

### Test OAuth Login

Open in browser:
```
http://localhost:3000/api/v1/auth/login/google
```

This redirects to Google OAuth.

## Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable **Google+ API**
4. Go to **Credentials** → **Create Credentials** → **OAuth client ID**
5. Application type: **Web application**
6. Authorized redirect URI: `http://localhost:3000/api/v1/auth/callback/google`
7. Copy **Client ID** and **Client Secret** to your `.env` file

## Troubleshooting

### "npm: command not found"
- Node.js is not installed or not in PATH
- Install Node.js from [nodejs.org](https://nodejs.org/)

### "Cannot connect to PostgreSQL"
- Make sure PostgreSQL is running
- Check DATABASE_URL in `.env` matches your setup
- For Docker: `docker-compose up -d postgres`

### "Cannot connect to Redis"
- Make sure Redis is running
- Check REDIS_URL in `.env` matches your setup
- For Docker: `docker-compose up -d redis`

### "Failed to load OAuth secrets"
- Make sure GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are set in `.env`
- In development, these are read from environment variables

### Migration errors
- Ensure PostgreSQL is running
- Check DATABASE_URL is correct
- Database `auth_service` should exist (created automatically by docker-compose)

## Next Steps

- See `SETUP.md` for detailed setup instructions
- See `docs/INTEGRATION.md` for integrating with other services
- See `TECHNICAL_PLAN.md` for architecture details




