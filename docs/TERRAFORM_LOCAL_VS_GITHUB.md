# Terraform: Local Development vs GitHub Actions

This document explains how Terraform works locally versus in GitHub Actions, and establishes best practices for both.

## Key Question: Can I Run Terraform Plan Locally Without Changing main.tf?

**Answer: Yes!** You can use backend configuration files without modifying `main.tf`.

## How It Works

### The Backend Configuration Pattern

Terraform supports **three ways** to configure the backend:

1. **Backend block in `main.tf`** (what we have - empty/commented)
2. **Backend config file** (`.hcl` file - for local development)
3. **Command-line flags** (what GitHub Actions uses)

The key insight: **You can override the backend block with command-line flags or config files**, so `main.tf` stays unchanged.

### Local Development (Recommended Pattern)

```bash
# 1. Create backend config file (gitignored)
cp backend.local.hcl.example backend.local.hcl
# Edit backend.local.hcl with your S3 bucket details

# 2. Initialize with backend config file
terraform init -backend-config=backend.local.hcl

# 3. Run commands normally
terraform plan -var-file=environments/dev/terraform.tfvars \
  -var="db_username=testuser" \
  -var="db_password=testpass"
```

**Benefits:**
- ✅ No changes to `main.tf`
- ✅ Backend config is gitignored (won't be committed)
- ✅ Easy to switch between environments
- ✅ Matches production pattern (S3 backend)

### GitHub Actions (Current Pattern)

The workflow uses **command-line flags** to configure the backend:

```yaml
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=${ENV}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=${BUCKET_NAME}-lock" \
  -reconfigure
```

**Benefits:**
- ✅ No config files needed
- ✅ Dynamic bucket names per environment
- ✅ Works in CI/CD environment

## Best Practices

### ✅ DO: Use Backend Config Files for Local Development

```bash
# Create environment-specific backend configs
backend.dev.hcl    # For dev environment
backend.prod.hcl   # For prod environment (if needed)

# Initialize with specific config
terraform init -backend-config=backend.dev.hcl
```

### ✅ DO: Keep main.tf Backend Block Empty

The empty backend block in `main.tf` is intentional:
- It declares we use S3 backend
- Configuration comes from files/flags
- Allows flexibility for different environments

### ✅ DO: Gitignore Backend Config Files

```gitignore
backend.local.hcl
backend.*.hcl
!backend.*.hcl.example
```

### ❌ DON'T: Modify main.tf for Local Testing

Don't change the backend block in `main.tf` to use `backend "local"`:
- Requires changing committed code
- Easy to forget to revert
- Causes merge conflicts

### ❌ DON'T: Commit Backend Config Files

Never commit `backend.local.hcl` or similar files:
- May contain sensitive information
- Environment-specific (not shareable)
- Use `.example` files instead

## Complete Workflow Comparison

### Local Development Workflow

```bash
# 1. Set up (one time)
cp backend.local.hcl.example backend.local.hcl
# Edit backend.local.hcl

# 2. Initialize (one time, or when backend changes)
terraform init -backend-config=backend.local.hcl

# 3. Set environment variables
export TF_VAR_db_username="your_user"
export TF_VAR_db_password="your_pass"

# 4. Plan
terraform plan -var-file=environments/dev/terraform.tfvars

# 5. Apply (when ready)
terraform apply -var-file=environments/dev/terraform.tfvars
```

### GitHub Actions Workflow

```yaml
# 1. Workflow automatically determines bucket name
BUCKET_NAME="auth-service-terraform-state-${ENV}-${REGION}"

# 2. Creates bucket/table if needed (idempotent)
aws s3api create-bucket --bucket "${BUCKET_NAME}" || echo "Exists"

# 3. Initializes with command-line flags
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=${ENV}/terraform.tfstate" \
  ...

# 4. Plans with secrets from GitHub
terraform plan \
  -var-file="environments/${ENV}/terraform.tfvars" \
  -var="db_username=${{ secrets.DB_USERNAME }}" \
  -var="db_password=${{ secrets.DB_PASSWORD }}"
```

## Required GitHub Secrets

For GitHub Actions to work, configure these secrets:

### Required Secrets

| Secret | Used By | Purpose |
|--------|---------|---------|
| `AWS_ACCESS_KEY_ID` | Infrastructure workflow | Terraform AWS operations |
| `AWS_SECRET_ACCESS_KEY` | Infrastructure workflow | Terraform AWS operations |
| `DB_USERNAME` | Infrastructure workflow | RDS master username |
| `DB_PASSWORD` | Infrastructure workflow | RDS master password |
| `GOOGLE_CLIENT_ID` | CI/CD workflow | Integration tests |
| `GOOGLE_CLIENT_SECRET` | CI/CD workflow | Integration tests |

### Optional Repository Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `TERRAFORM_AUTO_APPLY` | Not set | Auto-apply on push to main |

See [GitHub Setup Guide](GITHUB_SETUP.md) for detailed setup instructions.

## Helper Scripts

We provide helper scripts to simplify local development:

### Windows PowerShell

```powershell
# Initialize
.\infrastructure\terraform\scripts\terraform-local.ps1 init dev

# Plan
.\infrastructure\terraform\scripts\terraform-local.ps1 plan dev

# Apply
.\infrastructure\terraform\scripts\terraform-local.ps1 apply dev
```

### Linux/Mac

```bash
# Make executable (one time)
chmod +x infrastructure/terraform/scripts/terraform-local.sh

# Initialize
./infrastructure/terraform/scripts/terraform-local.sh init dev

# Plan
./infrastructure/terraform/scripts/terraform-local.sh plan dev

# Apply
./infrastructure/terraform/scripts/terraform-local.sh apply dev
```

The scripts:
- ✅ Check for backend config file
- ✅ Create from example if missing
- ✅ Handle environment variables
- ✅ Provide helpful error messages

## State Management

### State File Locations

- **Local**: `backend.local.hcl` specifies S3 bucket and key
- **GitHub Actions**: Auto-generated bucket: `auth-service-terraform-state-{env}-{region}`
- **State Key**: `{environment}/terraform.tfstate` (e.g., `dev/terraform.tfstate`)

### State Locking

- **Local**: Uses DynamoDB table specified in `backend.local.hcl`
- **GitHub Actions**: Auto-created DynamoDB table: `{bucket-name}-lock`

### Separate State Per Environment

Each environment has its own state file:
- `dev/terraform.tfstate` - Development environment
- `prod/terraform.tfstate` - Production environment

This prevents accidental cross-environment changes.

## Troubleshooting

### "Backend initialization required"

**Solution**: Run `terraform init -backend-config=backend.local.hcl`

### "State locked"

**Cause**: Another Terraform operation is in progress

**Solution**: 
- Wait for the other operation to complete
- Or force-unlock if safe: `terraform force-unlock <LOCK_ID>`

### "Bucket does not exist"

**Local**: Create the S3 bucket manually, or let GitHub Actions create it first

**GitHub Actions**: The workflow automatically creates the bucket if it doesn't exist

### "Invalid credentials"

**Solution**: 
- Verify AWS credentials: `aws sts get-caller-identity`
- Check `backend.local.hcl` has correct region
- Ensure credentials have S3/DynamoDB permissions

## Summary

✅ **Local Development**: Use `backend.local.hcl` config file (gitignored)  
✅ **GitHub Actions**: Uses command-line flags (no config file needed)  
✅ **main.tf**: Stays unchanged (empty backend block is intentional)  
✅ **Best Practice**: Backend config files for local, command-line flags for CI/CD

This pattern gives you:
- Flexibility for local development
- Consistency with production
- No code changes needed
- Environment-specific configurations


