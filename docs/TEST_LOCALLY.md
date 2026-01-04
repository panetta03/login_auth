# Testing Locally - Step by Step

Follow these steps to test migrations and the login endpoint locally before pushing to GitHub Actions.

## Prerequisites

1. **Start Docker Desktop**
2. **Ensure `.env` file exists** with `DATABASE_URL` set

## Step-by-Step Test

### 1. Start PostgreSQL and Redis

```powershell
docker-compose up -d postgres redis
```

Wait a few seconds for services to start.

### 2. Build Docker Image

```powershell
docker build -t auth-service:test .
```

### 3. Verify node-pg-migrate is Installed

```powershell
docker run --rm auth-service:test npm list node-pg-migrate
```

Should show `node-pg-migrate@6.2.2` or similar.

### 4. Verify Migration Files are Present

```powershell
docker run --rm auth-service:test ls src/database/migrations/
```

Should list `.sql` migration files.

### 5. Run Migrations

```powershell
docker run --rm -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/auth_service" auth-service:test sh -c "npm run migrate:up"
```

Should show migration output and complete successfully.

### 6. Start the Service

```powershell
docker run -d -p 3000:3000 -e NODE_ENV=development -e PORT=3000 -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/auth_service" -e REDIS_URL="redis://host.docker.internal:6379" -e CORS_ORIGIN="http://localhost:3000" --name auth-service-test auth-service:test
```

### 7. Test Health Endpoint

```powershell
Start-Sleep -Seconds 5
Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing
```

Should return `200 OK`.

### 8. Test Login Endpoint

```powershell
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/auth/login/google" -UseBasicParsing -MaximumRedirection 0
```

Should return `302 Found` with a `Location` header pointing to Google OAuth.

### 9. Check Logs (if needed)

```powershell
docker logs auth-service-test
```

### 10. Cleanup

```powershell
docker stop auth-service-test
docker rm auth-service-test
docker-compose down
```

## Quick Test Script

If you prefer, you can run these commands in sequence:

```powershell
# Start services
docker-compose up -d postgres redis
Start-Sleep -Seconds 5

# Build and test
docker build -t auth-service:test .
docker run --rm -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/auth_service" auth-service:test sh -c "npm run migrate:up"

# Start service
$containerId = docker run -d -p 3000:3000 -e NODE_ENV=development -e PORT=3000 -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/auth_service" -e REDIS_URL="redis://host.docker.internal:6379" -e CORS_ORIGIN="http://localhost:3000" auth-service:test

# Wait and test
Start-Sleep -Seconds 5
Invoke-WebRequest -Uri "http://localhost:3000/health"
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/auth/login/google" -MaximumRedirection 0

# Cleanup
docker stop $containerId
docker rm $containerId
```

## Expected Results

✅ **Migrations**: Should complete without errors  
✅ **Health endpoint**: Should return `200 OK`  
✅ **Login endpoint**: Should return `302 Found` with Google OAuth redirect URL

If all tests pass, your code is ready to push to GitHub Actions!

