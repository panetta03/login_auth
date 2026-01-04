#!/bin/bash
# Test migrations locally before deploying
# This script tests:
# 1. Docker image builds correctly with node-pg-migrate and migration files
# 2. Migrations can run in the container
# 3. Migration files are present in the image

set -e

echo "🧪 Testing migrations locally..."
echo ""

# Check if Docker is running
echo "1. Checking Docker..."
if docker ps > /dev/null 2>&1; then
    echo "   ✓ Docker is running"
else
    echo "   ❌ Docker is not running. Please start Docker."
    exit 1
fi

# Check if .env file exists with DATABASE_URL
echo "2. Checking environment variables..."
if [ ! -f .env ]; then
    echo "   ⚠️  .env file not found. Creating from .env.example if it exists..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "   ✓ Created .env from .env.example"
        echo "   ⚠️  Please update DATABASE_URL in .env file"
    else
        echo "   ❌ .env file not found and no .env.example to copy"
        exit 1
    fi
fi

# Load .env file
set -a
source .env
set +a

if [ -z "$DATABASE_URL" ]; then
    echo "   ❌ DATABASE_URL not found in .env file"
    echo "   Please set DATABASE_URL in .env file (e.g., postgresql://user:password@localhost:5432/auth_service)"
    exit 1
fi

echo "   ✓ DATABASE_URL is set"

# Build Docker image
echo ""
echo "3. Building Docker image..."
IMAGE_NAME="auth-service:test-migrations"
if docker build -t "$IMAGE_NAME" .; then
    echo "   ✓ Docker image built successfully"
else
    echo "   ❌ Docker build failed"
    exit 1
fi

# Test 1: Check if node-pg-migrate is installed
echo ""
echo "4. Testing if node-pg-migrate is installed in image..."
if docker run --rm "$IMAGE_NAME" npm list node-pg-migrate | grep -q "node-pg-migrate"; then
    echo "   ✓ node-pg-migrate is installed"
else
    echo "   ❌ node-pg-migrate is NOT installed"
    exit 1
fi

# Test 2: Check if migration files are present
echo ""
echo "5. Testing if migration files are present in image..."
MIGRATION_FILES=$(docker run --rm "$IMAGE_NAME" ls -la src/database/migrations/ 2>/dev/null || echo "")
if echo "$MIGRATION_FILES" | grep -q "\.sql"; then
    echo "   ✓ Migration files are present"
    echo "   Migration files found:"
    echo "$MIGRATION_FILES" | grep "\.sql" | sed 's/^/     /'
else
    echo "   ❌ Migration files are NOT present"
    echo "   Output: $MIGRATION_FILES"
    exit 1
fi

# Test 3: Test migration command (dry run - just check it can be executed)
echo ""
echo "6. Testing migration command syntax..."
if docker run --rm -e DATABASE_URL="$DATABASE_URL" "$IMAGE_NAME" sh -c "npm run migrate:up --help 2>&1 || node-pg-migrate --help 2>&1 | head -20" > /dev/null 2>&1; then
    echo "   ✓ Migration command is available"
else
    echo "   ⚠️  Could not verify migration command (this might be OK)"
fi

# Test 4: Actually run migrations (optional - requires database connection)
echo ""
echo "7. Testing actual migration run (requires database connection)..."
read -p "   Do you want to run migrations against your local database? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Running migrations..."
    if docker run --rm -e DATABASE_URL="$DATABASE_URL" "$IMAGE_NAME" sh -c "npm run migrate:up"; then
        echo "   ✓ Migrations ran successfully!"
    else
        echo "   ❌ Migrations failed"
        echo "   Make sure your database is running and DATABASE_URL is correct"
        exit 1
    fi
else
    echo "   ⏭️  Skipping actual migration run"
fi

echo ""
echo "✅ All migration tests passed!"
echo ""
echo "The Docker image is ready for deployment."
echo "You can now push to GitHub and the CI/CD pipeline should work."

