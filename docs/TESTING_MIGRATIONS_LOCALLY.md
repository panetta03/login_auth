# Testing Migrations Locally

Before pushing to GitHub Actions, you can test that migrations work correctly in the Docker image locally.

## Quick Test (Windows)

```powershell
.\scripts\test-migrations-local.ps1
```

## Quick Test (Linux/Mac)

```bash
./scripts/test-migrations-local.sh
```

## What the Script Tests

1. **Docker is running** - Verifies Docker Desktop/Engine is available
2. **Environment variables** - Checks that `.env` file exists with `DATABASE_URL`
3. **Docker image builds** - Builds the Docker image to ensure it compiles correctly
4. **node-pg-migrate is installed** - Verifies the migration tool is in the production image
5. **Migration files are present** - Confirms migration SQL files are copied to the image
6. **Migration command works** - Tests that the migration command can be executed
7. **Actual migration run** (optional) - Runs migrations against your local database

## Prerequisites

1. **Docker Desktop** (or Docker Engine) must be running
2. **`.env` file** with `DATABASE_URL` set:
   ```
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_service
   ```

## Using Docker Compose (Alternative)

If you prefer to use docker-compose:

```bash
# Start database
docker-compose up -d postgres

# Build the image
docker build -t auth-service:test .

# Test migrations
docker run --rm \
  -e DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/auth_service \
  auth-service:test \
  sh -c "npm run migrate:up"
```

## Manual Testing Steps

If you want to test manually:

1. **Build the image:**
   ```bash
   docker build -t auth-service:test .
   ```

2. **Check node-pg-migrate is installed:**
   ```bash
   docker run --rm auth-service:test npm list node-pg-migrate
   ```

3. **Check migration files exist:**
   ```bash
   docker run --rm auth-service:test ls -la src/database/migrations/
   ```

4. **Test migration command (dry run):**
   ```bash
   docker run --rm \
     -e DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/auth_service \
     auth-service:test \
     sh -c "npm run migrate:up"
   ```

## Troubleshooting

### "Docker is not running"
- Start Docker Desktop (Windows/Mac) or Docker Engine (Linux)

### "DATABASE_URL not found"
- Create a `.env` file in the project root
- Add: `DATABASE_URL=postgresql://user:password@host:port/database`

### "Migration files are NOT present"
- Check that `Dockerfile` includes: `COPY --from=builder /app/src/database/migrations ./src/database/migrations`
- Rebuild the image

### "node-pg-migrate is NOT installed"
- Check that `node-pg-migrate` is in `dependencies` (not `devDependencies`) in `package.json`
- Rebuild the image

### "Migrations failed"
- Ensure your database is running
- Check `DATABASE_URL` is correct
- For Docker Compose, use `host.docker.internal` as the hostname (Windows/Mac) or the container name (Linux)

## Next Steps

Once local tests pass:
1. Commit your changes
2. Push to GitHub
3. The CI/CD pipeline will use the same Docker image and migration process

