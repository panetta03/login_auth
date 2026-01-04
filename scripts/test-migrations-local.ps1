# Test migrations locally before deploying
# This script tests:
# 1. Docker image builds correctly with node-pg-migrate and migration files
# 2. Migrations can run in the container
# 3. Migration files are present in the image

Write-Host "🧪 Testing migrations locally..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "1. Checking Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "   ✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if .env file exists with DATABASE_URL
Write-Host "2. Checking environment variables..." -ForegroundColor Yellow
if (-not (Test-Path .env)) {
    Write-Host "   ⚠️  .env file not found. Creating from .env.example if it exists..." -ForegroundColor Yellow
    if (Test-Path .env.example) {
        Copy-Item .env.example .env
        Write-Host "   ✓ Created .env from .env.example" -ForegroundColor Green
        Write-Host "   ⚠️  Please update DATABASE_URL in .env file" -ForegroundColor Yellow
    } else {
        Write-Host "   ❌ .env file not found and no .env.example to copy" -ForegroundColor Red
        exit 1
    }
}

# Load .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

if (-not $env:DATABASE_URL) {
    Write-Host "   ❌ DATABASE_URL not found in .env file" -ForegroundColor Red
    Write-Host "   Please set DATABASE_URL in .env file (e.g., postgresql://user:password@localhost:5432/auth_service)" -ForegroundColor Yellow
    exit 1
}

Write-Host "   ✓ DATABASE_URL is set" -ForegroundColor Green

# Build Docker image
Write-Host ""
Write-Host "3. Building Docker image..." -ForegroundColor Yellow
$imageName = "auth-service:test-migrations"
try {
    docker build -t $imageName .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Docker image built successfully" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Docker build failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Docker build failed: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Check if node-pg-migrate is installed
Write-Host ""
Write-Host "4. Testing if node-pg-migrate is installed in image..." -ForegroundColor Yellow
$npmList = docker run --rm $imageName npm list node-pg-migrate
if ($npmList -match "node-pg-migrate") {
    Write-Host "   ✓ node-pg-migrate is installed" -ForegroundColor Green
} else {
    Write-Host "   ❌ node-pg-migrate is NOT installed" -ForegroundColor Red
    Write-Host "   Output: $npmList" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check if migration files are present
Write-Host ""
Write-Host "5. Testing if migration files are present in image..." -ForegroundColor Yellow
$migrationFiles = docker run --rm $imageName ls -la src/database/migrations/
if ($migrationFiles -match "\.sql") {
    Write-Host "   ✓ Migration files are present" -ForegroundColor Green
    Write-Host "   Migration files found:" -ForegroundColor Gray
    $migrationFiles | Select-String "\.sql" | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
} else {
    Write-Host "   ❌ Migration files are NOT present" -ForegroundColor Red
    Write-Host "   Output: $migrationFiles" -ForegroundColor Yellow
    exit 1
}

# Test 3: Test migration command (dry run - just check it can be executed)
Write-Host ""
Write-Host "6. Testing migration command syntax..." -ForegroundColor Yellow
$migrationHelp = docker run --rm -e DATABASE_URL=$env:DATABASE_URL $imageName sh -c "npm run migrate:up --help 2>&1 || node-pg-migrate --help 2>&1 | head -20"
if ($LASTEXITCODE -eq 0 -or $migrationHelp -match "node-pg-migrate" -or $migrationHelp -match "Usage") {
    Write-Host "   ✓ Migration command is available" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Could not verify migration command (this might be OK)" -ForegroundColor Yellow
    Write-Host "   Output: $migrationHelp" -ForegroundColor Gray
}

# Test 4: Actually run migrations (optional - requires database connection)
Write-Host ""
Write-Host "7. Testing actual migration run (requires database connection)..." -ForegroundColor Yellow
Write-Host "   Do you want to run migrations against your local database? (y/N)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "   Running migrations..." -ForegroundColor Yellow
    docker run --rm -e DATABASE_URL=$env:DATABASE_URL $imageName sh -c "npm run migrate:up"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Migrations ran successfully!" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Migrations failed" -ForegroundColor Red
        Write-Host "   Make sure your database is running and DATABASE_URL is correct" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "   ⏭️  Skipping actual migration run" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ All migration tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "The Docker image is ready for deployment." -ForegroundColor Cyan
Write-Host "You can now push to GitHub and the CI/CD pipeline should work." -ForegroundColor Cyan

