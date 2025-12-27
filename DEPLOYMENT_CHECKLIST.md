# AWS Deployment Checklist

## ✅ Completed
- [x] Code committed and pushed to main branch
- [x] CD pipeline configured (`.github/workflows/cd.yml`)
- [x] Dockerfile configured for production
- [x] Terraform infrastructure code ready

## 🔧 Pre-Deployment Requirements

### 1. GitHub Secrets Configuration
Ensure these secrets are set in your GitHub repository settings:
- `AWS_ACCESS_KEY_ID` - AWS access key with deployment permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key

**To set secrets:**
1. Go to: `https://github.com/panetta03/login_auth/settings/secrets/actions`
2. Add the two secrets above

### 2. AWS Infrastructure Setup

#### Option A: Deploy Infrastructure with Terraform (Recommended)

**Prerequisites:**
- Terraform installed (`terraform --version`)
- AWS CLI configured
- S3 bucket for Terraform state (or configure backend)

**Steps:**
```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# For dev environment:
terraform workspace select dev
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# For prod environment:
terraform workspace select prod
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

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
   - Name: `auth-service-cluster`
   - Region: `us-east-2`

3. **ECS Service**
   - Name: `auth-service`
   - Cluster: `auth-service-cluster`
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

### 3. Verify CD Pipeline

After pushing to main, check:
1. GitHub Actions tab: `https://github.com/panetta03/login_auth/actions`
2. The CD workflow should:
   - Build Docker image
   - Push to ECR
   - Update ECS service
   - Run smoke tests

### 4. Post-Deployment Verification

Once deployed, verify:
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster auth-service-cluster \
  --services auth-service \
  --region us-east-2

# Check running tasks
aws ecs list-tasks \
  --cluster auth-service-cluster \
  --service-name auth-service \
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
# View ECS service logs
aws logs tail /ecs/auth-service --follow --region us-east-2

# Force new deployment
aws ecs update-service \
  --cluster auth-service-cluster \
  --service auth-service \
  --force-new-deployment \
  --region us-east-2

# Check task definition
aws ecs describe-task-definition \
  --task-definition auth-service \
  --region us-east-2
```

