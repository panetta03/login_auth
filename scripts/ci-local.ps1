# Local CI script for Windows PowerShell - runs the same checks as GitHub Actions CI
# Usage: .\scripts\ci-local.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔍 Running local CI checks (matching GitHub Actions)..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean install (like npm ci in CI)
Write-Host "📦 Step 1: Installing dependencies (npm ci)..." -ForegroundColor Yellow
npm ci
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 2: Lint
Write-Host ""
Write-Host "🔍 Step 2: Running linter..." -ForegroundColor Yellow
npm run lint
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 3: Type check
Write-Host ""
Write-Host "🔍 Step 3: Running type check..." -ForegroundColor Yellow
npm run type-check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 4: Build
Write-Host ""
Write-Host "🔨 Step 4: Building TypeScript..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 5: Tests (with same env vars as CI)
Write-Host ""
Write-Host "🧪 Step 5: Running tests with coverage..." -ForegroundColor Yellow
$env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/auth_service_test"
$env:REDIS_URL = "redis://localhost:6379"
$env:NODE_ENV = "test"
# Note: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET should be in .env file (loaded via dotenv)
npm run test:coverage
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "✅ All CI checks passed locally!" -ForegroundColor Green

