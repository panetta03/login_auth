# AWS Deployment Checklist

## ✅ Completed
- [x] Code committed and pushed to main branch
- [x] CI/CD pipeline configured (`.github/workflows/ci-cd.yml`)
- [x] Infrastructure pipeline configured (`.github/workflows/infrastructure.yml`)
- [x] Dockerfile configured for production
- [x] Terraform infrastructure code ready

## 🔧 Pre-Deployment Requirements

### 1. GitHub Secrets Configuration
Ensure these secrets are set in your GitHub repository settings (see [GitHub Setup Guide](docs/GITHUB_SETUP.md) for details):

**Required Secrets:**
- `AWS_ACCESS_KEY_ID` - AWS access key with deployment permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `DB_USERNAME` - Database master username (for Terraform)
- `DB_PASSWORD` - Database master password (for Terraform)
- `GOOGLE_CLIENT_ID` - Google OAuth client ID (for tests)
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret (for tests)

**Optional Secrets:**
- `ECS_CLUSTER` - ECS cluster name (defaults to `auth-service-cluster`, but Terraform creates `{env}-auth-service-cluster`)
- `ECS_SERVICE` - ECS service name (defaults to `auth-service`, but Terraform creates `{env}-auth-service`)

**To set secrets:**
1. Go to: Repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret listed above

### 2. AWS Infrastructure Setup

#### Option A: Deploy Infrastructure with Terraform (Recommended)

**Prerequisites:**
- Terraform installed (`terraform --version`)
- AWS CLI configured
- S3 bucket for Terraform state (or configure backend)

**Steps:**
```bash
cd infrastructure/terraform

# 1. Set up backend configuration
cp backend.local.hcl.example backend.local.hcl
# Edit backend.local.hcl with your S3 bucket details

# 2. Initialize Terraform
terraform init -backend-config=backend.local.hcl

# 3. Set required variables
export TF_VAR_db_username="your_db_user"
export TF_VAR_db_password="your_db_password"

# 4. For dev environment:
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# 5. For prod environment:
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

**Note**: We use separate state files per environment (not Terraform workspaces). Each environment has its own state file: `dev/terraform.tfstate`, `prod/terraform.tfstate`.

**Alternative**: Use GitHub Actions infrastructure workflow:
1. Go to Actions → Infrastructure Deployment
2. Select environment (dev/prod) and action (plan/apply)
3. Workflow will automatically create S3 bucket and DynamoDB table if needed

**Required Terraform Variables:**
- `environment` - "dev" or "prod"
- `db_username` - Database master username
- `db_password` - Database master password (sensitive)
- `ecr_repository_url` - ECR repository URL (e.g., `123456789012.dkr.ecr.us-east-2.amazonaws.com/auth-service`)

#### Option B: Manual AWS Resource Creation

If not using Terraform, ensure these resources exist:

1. **ECR Repository**
   - Name: `auth-service`
   - Region: `us-east-2` (or your preferred region)

2. **ECS Cluster**
   - Name: `{environment}-auth-service-cluster` (e.g., `dev-auth-service-cluster`)
   - Region: `us-east-2`

3. **ECS Service**
   - Name: `{environment}-auth-service` (e.g., `dev-auth-service`)
   - Cluster: `{environment}-auth-service-cluster`
   - Task definition with:
     - Container image from ECR
     - Environment variables:
       - `NODE_ENV=production`
       - `DATABASE_URL` (from RDS)
       - `REDIS_URL` (from ElastiCache)
       - `AWS_REGION=us-east-2`
       - `AWS_SECRETS_MANAGER_SECRET_NAME=googleoauth`
     - IAM role with permissions to:
       - Read from Secrets Manager
       - Write to CloudWatch Logs

4. **RDS PostgreSQL**
   - Database name: `auth_service`
   - Accessible from ECS service

5. **ElastiCache Redis**
   - Accessible from ECS service

6. **AWS Secrets Manager**
   - Secret name: `googleoauth`
   - Secret value (JSON):
     ```json
     {
       "GOOGLE_CLIENT_ID": "your-client-id",
       "GOOGLE_CLIENT_SECRET": "your-client-secret"
     }
     ```

7. **API Gateway** (optional, if using)
   - REST API configured
   - Integration with ECS/ALB

### 3. Verify CI/CD Pipeline

After pushing to main, check:
1. GitHub Actions tab: `https://github.com/panetta03/login_auth/actions`
2. The CI/CD workflow (`.github/workflows/ci-cd.yml`) should:
   - Run tests, linting, type checking
   - Build Docker image
   - Push to ECR
   - Update ECS service
   - Run smoke tests

**Note**: The workflow will automatically create ECR repository and ECS cluster if they don't exist, but the ECS service must be created via Terraform first.

### 4. Post-Deployment Verification

Once deployed, verify:
```bash
# Get cluster/service names from Terraform outputs
cd infrastructure/terraform
terraform output ecs_cluster_name
terraform output ecs_service_name

# Check ECS service status (replace with your actual cluster/service names)
aws ecs describe-services \
  --cluster dev-auth-service-cluster \
  --services dev-auth-service \
  --region us-east-2

# Check running tasks
aws ecs list-tasks \
  --cluster dev-auth-service-cluster \
  --service-name dev-auth-service \
  --region us-east-2

# Test health endpoint (replace with your API Gateway URL or ALB DNS)
curl https://your-api-url/health
```

## 🚨 Common Issues

### CD Pipeline Fails
- **ECR repository doesn't exist**: Create it manually or via Terraform
- **ECS cluster/service doesn't exist**: Deploy infrastructure first
- **AWS credentials invalid**: Check GitHub secrets
- **IAM permissions insufficient**: Ensure IAM user/role has:
  - `ecr:*` (or specific ECR permissions)
  - `ecs:UpdateService`
  - `ecs:DescribeServices`

### Application Fails to Start
- **Database connection error**: Check RDS security groups, database URL
- **Redis connection error**: Check ElastiCache security groups, Redis URL
- **Secrets Manager access denied**: Check IAM role permissions
- **Port binding issues**: Ensure container exposes port 3000

## 📝 Next Steps

1. **Set up GitHub secrets** (if not already done)
2. **Deploy infrastructure** using Terraform or manually
3. **Monitor CD pipeline** in GitHub Actions
4. **Verify deployment** by testing endpoints
5. **Set up monitoring** (CloudWatch alarms, logs)

## 🔗 Useful Commands

```bash
# View ECS service logs (replace with your actual service name)
aws logs tail /ecs/dev-auth-service --follow --region us-east-2

# Force new deployment (replace with your actual cluster/service names)
aws ecs update-service \
  --cluster dev-auth-service-cluster \
  --service dev-auth-service \
  --force-new-deployment \
  --region us-east-2

# Check task definition (replace with your actual task definition family)
aws ecs describe-task-definition \
  --task-definition dev-auth-service \
  --region us-east-2
```

