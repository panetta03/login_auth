#!/bin/bash
# Local CI script - runs the same checks as GitHub Actions CI
# Usage: ./scripts/ci-local.sh

set -e  # Exit on error

echo "🔍 Running local CI checks (matching GitHub Actions)..."
echo ""

# Step 1: Clean install (like npm ci in CI)
echo "📦 Step 1: Installing dependencies (npm ci)..."
npm ci

# Step 2: Lint
echo ""
echo "🔍 Step 2: Running linter..."
npm run lint

# Step 3: Type check
echo ""
echo "🔍 Step 3: Running type check..."
npm run type-check

# Step 4: Build
echo ""
echo "🔨 Step 4: Building TypeScript..."
npm run build

# Step 5: Tests (with same env vars as CI)
echo ""
echo "🧪 Step 5: Running tests with coverage..."
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/auth_service_test"
export REDIS_URL="redis://localhost:6379"
export NODE_ENV="test"
# Note: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET should be in .env file
npm run test:coverage

echo ""
echo "✅ All CI checks passed locally!"

