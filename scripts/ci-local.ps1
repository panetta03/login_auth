# Local CI script for Windows PowerShell - runs the same checks as GitHub Actions CI
# Usage: .\scripts\ci-local.ps1

$ErrorActionPreference = "Stop"

Write-Host "Running local CI checks (matching GitHub Actions)..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean install (like npm ci in CI)
Write-Host "Step 1: Installing dependencies (npm ci)..." -ForegroundColor Yellow
npm ci
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 2: Lint
Write-Host ""
Write-Host "Step 2: Running linter..." -ForegroundColor Yellow
npm run lint
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 3: Type check
Write-Host ""
Write-Host "Step 3: Running type check..." -ForegroundColor Yellow
npm run type-check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 4: Build
Write-Host ""
Write-Host "Step 4: Building TypeScript..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 5: Start Redis for tests
Write-Host ""
Write-Host "Step 5: Starting Redis for tests..." -ForegroundColor Yellow
$redisStarted = $false
try {
    # Check if Redis is already running
    $redisRunning = docker ps --filter "name=auth-service-redis" --filter "status=running" --format "{{.Names}}" | Select-String "auth-service-redis"
    
    if (-not $redisRunning) {
        # Start Redis using docker-compose
        docker-compose up -d redis
        Start-Sleep -Seconds 3
        $redisStarted = $true
        Write-Host "   ✓ Redis started" -ForegroundColor Green
    } else {
        Write-Host "   ✓ Redis already running" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  Warning: Could not start Redis: $_" -ForegroundColor Yellow
    Write-Host "   Tests may fail if Redis is not available" -ForegroundColor Yellow
}

# Step 6: Tests (with same env vars as CI)
Write-Host ""
Write-Host "Step 6: Running tests with coverage..." -ForegroundColor Yellow
$testExitCode = 0
try {
    $env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/auth_service_test"
    $env:REDIS_URL = "redis://localhost:6379"
    $env:NODE_ENV = "test"
    # Note: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET should be in .env file (loaded via dotenv)
    npm run test:coverage
    $testExitCode = $LASTEXITCODE
} finally {
    # Cleanup: Stop Redis if we started it
    if ($redisStarted) {
        Write-Host ""
        Write-Host "Cleaning up: Stopping Redis..." -ForegroundColor Yellow
        docker-compose stop redis 2>&1 | Out-Null
        Write-Host "   ✓ Redis stopped" -ForegroundColor Green
    }
    
    if ($testExitCode -ne 0) {
        exit $testExitCode
    }
}

Write-Host ""
Write-Host "All CI checks passed locally!" -ForegroundColor Green

