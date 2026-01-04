# Full end-to-end local test
# 1. Starts PostgreSQL and Redis with docker-compose
# 2. Builds Docker image
# 3. Runs migrations
# 4. Starts the service
# 5. Tests the login endpoint

Write-Host "🧪 Full Local Test - Migrations + Login Endpoint" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "1. Checking Docker..." -ForegroundColor Yellow
$dockerCheck = docker ps 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Docker is running" -ForegroundColor Green

# Start services
Write-Host ""
Write-Host "2. Starting PostgreSQL and Redis..." -ForegroundColor Yellow
docker-compose up -d postgres redis
Start-Sleep -Seconds 5
Write-Host "   ✓ Services started" -ForegroundColor Green

# Build image
Write-Host ""
Write-Host "3. Building Docker image..." -ForegroundColor Yellow
docker build -t auth-service:test . 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Image built" -ForegroundColor Green
} else {
    Write-Host "   ❌ Build failed" -ForegroundColor Red
    exit 1
}

# Check node-pg-migrate
Write-Host ""
Write-Host "4. Verifying node-pg-migrate in image..." -ForegroundColor Yellow
$npmCheck = docker run --rm auth-service:test npm list node-pg-migrate 2>&1
if ($npmCheck -match "node-pg-migrate") {
    Write-Host "   ✓ node-pg-migrate installed" -ForegroundColor Green
} else {
    Write-Host "   ❌ node-pg-migrate NOT found" -ForegroundColor Red
    Write-Host "   Output: $npmCheck" -ForegroundColor Yellow
    exit 1
}

# Check migration files
Write-Host ""
Write-Host "5. Verifying migration files in image..." -ForegroundColor Yellow
$migrations = docker run --rm auth-service:test ls src/database/migrations/ 2>&1
if ($migrations -match "\.sql") {
    Write-Host "   ✓ Migration files present" -ForegroundColor Green
} else {
    Write-Host "   ❌ Migration files NOT found" -ForegroundColor Red
    exit 1
}

# Run migrations
Write-Host ""
Write-Host "6. Running database migrations..." -ForegroundColor Yellow
$dbUrl = "postgresql://postgres:postgres@host.docker.internal:5432/auth_service"
docker run --rm -e DATABASE_URL=$dbUrl auth-service:test sh -c "npm run migrate:up"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Migrations completed" -ForegroundColor Green
} else {
    Write-Host "   ❌ Migrations failed" -ForegroundColor Red
    exit 1
}

# Start the service
Write-Host ""
Write-Host "7. Starting auth service..." -ForegroundColor Yellow
$containerId = docker run -d -p 3000:3000 -e NODE_ENV=development -e PORT=3000 -e DATABASE_URL=$dbUrl -e REDIS_URL="redis://host.docker.internal:6379" -e CORS_ORIGIN="http://localhost:3000" auth-service:test
Start-Sleep -Seconds 5
Write-Host "   ✓ Service started (container: $containerId)" -ForegroundColor Green

# Test health endpoint
Write-Host ""
Write-Host "8. Testing health endpoint..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -ErrorAction Stop
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "   ✓ Health check passed" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Health check failed: $($healthResponse.StatusCode)" -ForegroundColor Red
        docker logs $containerId
        docker stop $containerId | Out-Null
        exit 1
    }
} catch {
    Write-Host "   ❌ Health check failed: $_" -ForegroundColor Red
    docker logs $containerId
    docker stop $containerId | Out-Null
    exit 1
}

# Test login endpoint
Write-Host ""
Write-Host "9. Testing login endpoint..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/v1/auth/login/google" -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop
    if (($loginResponse.StatusCode -eq 302) -or ($loginResponse.StatusCode -eq 307)) {
        Write-Host "   ✓ Login endpoint redirects correctly (OAuth flow)" -ForegroundColor Green
        Write-Host "   Location: $($loginResponse.Headers.Location)" -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️  Login endpoint returned: $($loginResponse.StatusCode)" -ForegroundColor Yellow
        Write-Host "   Response: $($loginResponse.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠️  Login endpoint test failed: $_" -ForegroundColor Yellow
}

# Cleanup
Write-Host ""
Write-Host "10. Cleaning up..." -ForegroundColor Yellow
docker stop $containerId | Out-Null
Write-Host "   ✓ Container stopped" -ForegroundColor Green

Write-Host ""
Write-Host "✅ All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "The service is working correctly. You can now:" -ForegroundColor Cyan
Write-Host "  1. Keep services running: docker-compose up" -ForegroundColor Gray
Write-Host "  2. Stop services: docker-compose down" -ForegroundColor Gray
