# GitHub Actions Setup Guide

This guide explains how to configure GitHub Actions for CI/CD and infrastructure deployment.

## Required GitHub Secrets

Configure these in your repository settings: **Settings → Secrets and variables → Actions → Secrets**

### Secrets (Encrypted)

These are encrypted and never visible in logs or code:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key for Terraform and deployment operations | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for Terraform and deployment operations | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `DB_USERNAME` | PostgreSQL master username (used by Terraform to create RDS) | `postgres` |
| `DB_PASSWORD` | PostgreSQL master password (used by Terraform to create RDS) | `SecurePassword123!` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID (for application tests) | `123456789-abc.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret (for application tests) | `GOCSPX-abc123def456` |
| `ECS_CLUSTER` | ECS cluster name (optional, defaults to `dev-auth-service-cluster`) | `dev-auth-service-cluster` or `prod-auth-service-cluster` |
| `ECS_SERVICE` | ECS service name (optional, defaults to `dev-auth-service`) | `dev-auth-service` or `prod-auth-service` |

### Repository Variables (Optional)

Configure these in: **Settings → Secrets and variables → Actions → Variables**

| Variable Name | Description | Default | Recommended |
|--------------|-------------|---------|-------------|
| `TERRAFORM_AUTO_APPLY` | Auto-apply Terraform changes on push to `main` | Not set (manual) | `"true"` for dev, `"false"` for prod |

**Note**: Repository variables are visible in workflow logs (not encrypted). Use them for configuration, not secrets.

## Setting Up Secrets

### Step 1: Access Repository Settings

1. Go to your GitHub repository
2. Click **Settings** (top navigation)
3. Click **Secrets and variables** → **Actions** (left sidebar)

### Step 2: Add Secrets

1. Click **New repository secret**
2. Enter the secret name (exactly as listed above)
3. Enter the secret value
4. Click **Add secret**

### Step 3: Verify Secrets

After adding secrets, you can verify they exist (but not their values) in the secrets list.

## AWS Credentials Setup

### Option 1: IAM User (Recommended for CI/CD)

1. **Create IAM User**:
   ```bash
   aws iam create-user --user-name github-actions-terraform
   ```

2. **Attach Policies**:
   ```bash
   # Terraform needs broad permissions for infrastructure management
   aws iam attach-user-policy \
     --user-name github-actions-terraform \
     --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   
   # Or create a custom policy with minimal required permissions
   ```

3. **Create Access Key**:
   ```bash
   aws iam create-access-key --user-name github-actions-terraform
   ```

4. **Add to GitHub Secrets**:
   - Copy `AccessKeyId` → `AWS_ACCESS_KEY_ID`
   - Copy `SecretAccessKey` → `AWS_SECRET_ACCESS_KEY`

### Option 2: OIDC (More Secure, Advanced)

For production, consider using OIDC to avoid storing long-lived credentials:

1. Configure OIDC provider in AWS
2. Create IAM role with trust policy for GitHub
3. Update workflow to use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`

See [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) for details.

## Database Credentials

### For Terraform (RDS Creation)

The `DB_USERNAME` and `DB_PASSWORD` secrets are used by Terraform to:
- Create the RDS PostgreSQL instance
- Set the master username and password
- Store credentials securely (Terraform will not log password values)

**Security Note**: These are the master database credentials. In production, consider:
- Using AWS Secrets Manager to rotate passwords
- Creating separate application users with limited permissions
- Never committing these values to code

### For Application Tests

The `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are used by:
- Integration tests that require real OAuth credentials
- Local development (via `.env` file)

## Workflow Behavior

### CI/CD Pipeline (`.github/workflows/ci-cd.yml`)

**Triggers**:
- Push to `main` → Runs tests, builds, and deploys
- Pull requests → Runs tests only

**Uses Secrets**:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` → Deploy to ECR/ECS
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` → Run integration tests
- `ECS_CLUSTER` / `ECS_SERVICE` → **Required if using Terraform** - Must match Terraform environment:
  - If Terraform deployed to `dev`: `dev-auth-service-cluster` / `dev-auth-service`
  - If Terraform deployed to `prod`: `prod-auth-service-cluster` / `prod-auth-service`

### Infrastructure Pipeline (`.github/workflows/infrastructure.yml`)

**Triggers**:
- Manual (`workflow_dispatch`) → Choose environment and action
- Push to `main` with `infrastructure/**` changes → Auto-plan (or auto-apply if enabled)

**Uses Secrets**:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` → Terraform operations
- `DB_USERNAME` / `DB_PASSWORD` → RDS creation

**Uses Variables**:
- `TERRAFORM_AUTO_APPLY` → Controls auto-apply behavior

## Testing Secrets Configuration

### Test AWS Credentials

Create a test workflow or run locally:

```bash
# Test AWS credentials
aws sts get-caller-identity

# Should return your AWS account ID and user ARN
```

### Test GitHub Secrets (in Workflow)

Add a test step to verify secrets are accessible:

```yaml
- name: Verify Secrets
  run: |
    if [ -z "${{ secrets.AWS_ACCESS_KEY_ID }}" ]; then
      echo "❌ AWS_ACCESS_KEY_ID not set"
      exit 1
    fi
    echo "✅ Secrets configured"
```

## Security Best Practices

1. ✅ **Use IAM roles with OIDC** (production) instead of access keys when possible
2. ✅ **Rotate credentials regularly** (every 90 days for access keys)
3. ✅ **Use separate AWS accounts** for dev/prod environments
4. ✅ **Limit IAM permissions** to minimum required (principle of least privilege)
5. ✅ **Never commit secrets** to code or logs
6. ✅ **Use environment-specific secrets** when possible
7. ✅ **Enable secret scanning** in GitHub (Settings → Security → Secret scanning)

## Troubleshooting

### "AWS credentials not found"

- Verify secrets are set in repository settings
- Check secret names match exactly (case-sensitive)
- Ensure workflow has access to secrets (not in forked PRs)

### "Invalid credentials"

- Verify AWS credentials are valid: `aws sts get-caller-identity`
- Check IAM user has required permissions
- Ensure credentials haven't expired

### "Secret not accessible in workflow"

- Secrets are not available in pull requests from forks (security)
- Use repository variables for non-sensitive configuration
- Check workflow trigger (some events don't have secret access)

### "Terraform state locked"

- Another Terraform operation is in progress
- Check DynamoDB table for stuck locks
- Force-unlock only if safe: `terraform force-unlock <LOCK_ID>`

## Next Steps

After configuring secrets:

1. ✅ Test CI pipeline: Push a commit to trigger tests
2. ✅ Test infrastructure pipeline: Run manual `plan` action
3. ✅ Review workflow logs: Verify secrets are working
4. ✅ Set up monitoring: Alerts for failed deployments

See [Terraform README](../infrastructure/terraform/README.md) for local development setup.

