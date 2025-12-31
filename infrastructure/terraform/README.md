# Terraform Infrastructure

This directory contains Terraform configurations for managing the auth service infrastructure on AWS.

## Local Development

### Prerequisites

1. **Terraform installed** (>= 1.0)
   - Windows: `winget install HashiCorp.Terraform`
   - Mac: `brew install terraform`
   - Linux: See [Terraform downloads](https://www.terraform.io/downloads)

2. **AWS CLI configured** with credentials
   ```bash
   aws configure
   ```

3. **Backend configuration** (see below)

### Backend Configuration

Terraform uses an S3 backend for state management. For local development, you have two options:

#### Option 1: Use Backend Config File (Recommended)

1. Copy the example backend config:
   ```bash
   cp backend.local.hcl.example backend.local.hcl
   ```

2. Edit `backend.local.hcl` with your values:
   ```hcl
   bucket         = "your-terraform-state-bucket"
   key            = "dev/terraform.tfstate"
   region         = "us-east-2"
   encrypt        = true
   dynamodb_table = "your-dynamodb-lock-table"
   ```

3. Initialize Terraform with the backend config:
   ```bash
   terraform init -backend-config=backend.local.hcl
   ```

#### Option 2: Use Local Backend (Testing Only)

For quick testing without AWS credentials, you can use a local backend:

1. Create `backend.local.hcl`:
   ```hcl
   backend "local" {
     path = "terraform.tfstate"
   }
   ```

   **Note**: This requires modifying `main.tf` temporarily. Not recommended for production work.

### Running Terraform Commands

#### Initialize
```bash
# With backend config file
terraform init -backend-config=backend.local.hcl

# Or with command-line flags (matches GitHub Actions pattern)
terraform init \
  -backend-config="bucket=auth-service-terraform-state-dev-us-east-2" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=auth-service-terraform-state-dev-us-east-2-lock"
```

#### Plan
```bash
terraform plan \
  -var-file=environments/dev/terraform.tfvars \
  -var="db_username=your_db_user" \
  -var="db_password=your_db_password"
```

#### Apply
```bash
terraform apply \
  -var-file=environments/dev/terraform.tfvars \
  -var="db_username=your_db_user" \
  -var="db_password=your_db_password"
```

#### Validate
```bash
terraform validate
```

#### Format
```bash
terraform fmt -recursive
```

### Environment Variables

You can also set sensitive variables via environment variables:

```bash
export TF_VAR_db_username="your_db_user"
export TF_VAR_db_password="your_db_password"
```

Then run:
```bash
terraform plan -var-file=environments/dev/terraform.tfvars
```

## GitHub Actions Deployment

### Required GitHub Secrets

Configure these in your repository settings (Settings → Secrets and variables → Actions):

#### Secrets (encrypted, not visible in logs)
- `AWS_ACCESS_KEY_ID` - AWS access key for Terraform operations
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for Terraform operations
- `DB_USERNAME` - Database master username (used in Terraform plan/apply)
- `DB_PASSWORD` - Database master password (used in Terraform plan/apply)

#### Repository Variables (visible in logs, for configuration)
- `TERRAFORM_AUTO_APPLY` - Set to `"true"` to auto-apply on push to `main` (optional, defaults to manual)

### How It Works

1. **Workflow Trigger**: 
   - Manual via `workflow_dispatch` (choose environment and action)
   - Automatic on push to `main` when `infrastructure/**` changes

2. **Backend Setup**:
   - Workflow automatically creates S3 bucket and DynamoDB table if they don't exist
   - Uses auto-generated names: `auth-service-terraform-state-{env}-{region}`

3. **Terraform Init**:
   - Configures S3 backend via command-line flags (no config file needed)
   - Uses `-reconfigure` to handle backend changes

4. **State Management**:
   - State stored in S3: `{bucket}/{environment}/terraform.tfstate`
   - Locking via DynamoDB: `{bucket}-lock`

### Workflow Actions

- **plan**: Generate and show execution plan (no changes)
- **apply**: Apply the plan (creates/updates infrastructure)
- **destroy**: Destroy all infrastructure (use with caution!)

## Best Practices

### Local Development
1. ✅ Use `backend.local.hcl` for local backend configuration
2. ✅ Never commit `backend.local.hcl` (it's gitignored)
3. ✅ Use environment variables for sensitive values (`TF_VAR_*`)
4. ✅ Always run `terraform fmt` before committing
5. ✅ Run `terraform validate` before planning

### Production Deployment
1. ✅ Always run `terraform plan` first in GitHub Actions
2. ✅ Review the plan output before applying
3. ✅ Use separate state files per environment (`dev/terraform.tfstate`, `prod/terraform.tfstate`)
4. ✅ Enable `TERRAFORM_AUTO_APPLY` only for dev environment initially
5. ✅ Require manual approval for production applies

### State Management
1. ✅ Never commit `terraform.tfstate` files
2. ✅ Use S3 backend with versioning enabled
3. ✅ Use DynamoDB for state locking (prevents concurrent modifications)
4. ✅ Backup state files before major changes
5. ✅ Use separate state backends per environment

## Troubleshooting

### "Backend initialization required"
- Run `terraform init -backend-config=backend.local.hcl` (or with command-line flags)
- If switching backends, use `-reconfigure` flag

### "State locked"
- Another Terraform operation is in progress
- Check DynamoDB table for stuck locks
- Force-unlock only if you're certain: `terraform force-unlock <LOCK_ID>`

### "Invalid credentials"
- Verify AWS credentials: `aws sts get-caller-identity`
- Check AWS region matches your backend configuration

### "Bucket does not exist"
- Create the S3 bucket manually, or
- Let GitHub Actions workflow create it automatically


