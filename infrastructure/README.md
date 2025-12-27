# Infrastructure Setup Guide

This directory contains Terraform configuration for deploying the auth service infrastructure to AWS.

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (>= 1.0)
   - Windows: `winget install HashiCorp.Terraform`
   - Mac: `brew install terraform`
   - Linux: See [Terraform downloads](https://www.terraform.io/downloads)
3. **AWS Account** with permissions to create:
   - VPC, Subnets, Internet Gateway, NAT Gateway
   - ECS Cluster, Service, Task Definitions
   - RDS PostgreSQL database
   - ElastiCache Redis
   - Application Load Balancer
   - Security Groups
   - IAM Roles and Policies
   - CloudWatch Log Groups
   - S3 buckets and DynamoDB tables (for Terraform state)

## Quick Start

For detailed Terraform setup instructions, see [terraform/README.md](terraform/README.md).

### 1. Configure Terraform Backend

**Recommended**: Use a backend config file for local development:

```bash
cd infrastructure/terraform
cp backend.local.hcl.example backend.local.hcl
# Edit backend.local.hcl with your S3 bucket details
```

**Alternative**: Use command-line flags (matches GitHub Actions pattern):

```bash
terraform init \
  -backend-config="bucket=auth-service-terraform-state-dev-us-east-2" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=auth-service-terraform-state-dev-us-east-2-lock"
```

### 2. Set Up Environment Variables

Choose an environment (dev or prod) and configure variables:

```bash
cd infrastructure/terraform/environments/dev
```

Edit `terraform.tfvars` with your values. Note that `db_username` and `db_password` are required but can be provided via:
- Environment variables: `TF_VAR_db_username` and `TF_VAR_db_password`
- Command-line flags: `-var="db_username=..." -var="db_password=..."`

### 3. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init -backend-config=backend.local.hcl
```

### 4. Plan the Infrastructure

```bash
# Set required variables
export TF_VAR_db_username="your_db_user"
export TF_VAR_db_password="your_db_password"

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars
```

### 5. Apply the Infrastructure

```bash
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Note**: We use separate state files per environment (not Terraform workspaces). Each environment has its own state file: `dev/terraform.tfstate`, `prod/terraform.tfstate`.

This will create:
- **VPC** with public and private subnets (2 AZs)
- **Internet Gateway** and **NAT Gateway**
- **ECS Cluster** (`dev-auth-service-cluster`)
- **ECS Service** (`dev-auth-service`)
- **RDS PostgreSQL** database
- **ElastiCache Redis** cluster
- **Application Load Balancer** (ALB)
- **Security Groups** for ECS, ALB, RDS, Redis
- **IAM Roles** for ECS execution and tasks
- **CloudWatch Log Groups**

### 6. Get Outputs

After successful deployment, get important values:

```bash
terraform output
```

Key outputs:
- `alb_dns_name` - ALB endpoint URL
- `cluster_name` - ECS cluster name
- `service_name` - ECS service name

### 7. Configure GitHub Secrets

After Terraform creates the infrastructure, configure GitHub Secrets for CI/CD:

**Required Secrets** (see [GitHub Setup Guide](../docs/GITHUB_SETUP.md) for details):
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - AWS credentials
- `DB_USERNAME` / `DB_PASSWORD` - Database credentials for RDS
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` - OAuth credentials (for tests)

**Optional Secrets** (with defaults):
- `ECS_CLUSTER` - ECS cluster name (defaults to `auth-service-cluster`)
- `ECS_SERVICE` - ECS service name (defaults to `auth-service`)

**Important**: Terraform creates environment-prefixed names:
- Dev: `dev-auth-service-cluster` / `dev-auth-service`
- Prod: `prod-auth-service-cluster` / `prod-auth-service`

You must set `ECS_CLUSTER` and `ECS_SERVICE` secrets to match your Terraform outputs, or the CI/CD workflow will fail. Get the values from Terraform:

```bash
terraform output ecs_cluster_name
terraform output ecs_service_name
```

## Infrastructure Components

### VPC Module
- Creates VPC with CIDR block (default: `10.0.0.0/16`)
- Public subnets (2 AZs) for ALB
- Private subnets (2 AZs) for ECS tasks, RDS, Redis
- Internet Gateway for public subnets
- NAT Gateway for private subnet internet access

### ECS Module
- ECS Fargate cluster
- ECS service with auto-scaling
- Application Load Balancer
- Task definition with container configuration
- Security groups for ECS and ALB

### RDS Module
- PostgreSQL database (Multi-AZ for prod)
- Automated backups
- Security group allowing access from ECS

### Redis Module
- ElastiCache Redis cluster
- Security group allowing access from ECS

## Important Notes

1. **First-time Setup**: The infrastructure pipeline (`.github/workflows/infrastructure.yml`) can create the S3 bucket and DynamoDB table automatically, but you must run Terraform to create the actual infrastructure before deploying applications.

2. **Subnets**: The infrastructure creates properly configured subnets across 2 availability zones. The CD pipeline (`.github/workflows/ci-cd.yml`) expects the ECS service to already exist - it will update the service but won't create new infrastructure.

3. **State Management**: 
   - We use separate state files per environment (`dev/terraform.tfstate`, `prod/terraform.tfstate`)
   - State is stored in S3 with DynamoDB locking
   - Backend configuration is done via config files (local) or command-line flags (GitHub Actions)

4. **Security**: 
   - Database passwords should be stored in AWS Secrets Manager in production
   - Use different credentials for dev/prod environments
   - Enable encryption at rest for RDS and ElastiCache
   - Never commit `backend.local.hcl` or other sensitive config files

5. **Costs**: 
   - NAT Gateway incurs hourly charges (~$0.045/hour)
   - RDS and ElastiCache have instance costs
   - Consider using smaller instance types for dev (see `environments/dev/terraform.tfvars`)

6. **Workflows**: 
   - **Infrastructure**: `.github/workflows/infrastructure.yml` - Manages Terraform (plan/apply/destroy)
   - **CI/CD**: `.github/workflows/ci-cd.yml` - Tests, builds, and deploys application code

## Troubleshooting

### ECS Service Not Found
If the CD pipeline fails with "ServiceNotFoundException", ensure Terraform has been applied and the service exists:

```bash
aws ecs describe-services \
  --cluster dev-auth-service-cluster \
  --services dev-auth-service \
  --region us-east-2
```

### Subnet Issues
If you see subnet-related errors, verify the VPC and subnets were created:

```bash
aws ec2 describe-vpcs --region us-east-2
aws ec2 describe-subnets --region us-east-2
```

## Helper Scripts

For easier local development, use the helper scripts:

**Windows PowerShell:**
```powershell
.\infrastructure\terraform\scripts\terraform-local.ps1 plan dev
.\infrastructure\terraform\scripts\terraform-local.ps1 apply dev
```

**Linux/Mac:**
```bash
chmod +x infrastructure/terraform/scripts/terraform-local.sh
./infrastructure/terraform/scripts/terraform-local.sh plan dev
./infrastructure/terraform/scripts/terraform-local.sh apply dev
```

## Next Steps

After infrastructure is created:
1. Store OAuth credentials in AWS Secrets Manager (secret name: `googleoauth`)
2. Run database migrations (via application or manually)
3. The CI/CD pipeline (`.github/workflows/ci-cd.yml`) will deploy new Docker images automatically
4. Monitor infrastructure via CloudWatch and Terraform outputs

## Documentation

- **[Terraform README](terraform/README.md)** - Detailed Terraform setup and usage
- **[GitHub Setup Guide](../docs/GITHUB_SETUP.md)** - GitHub Actions and secrets configuration
- **[Terraform Local vs GitHub](../docs/TERRAFORM_LOCAL_VS_GITHUB.md)** - Best practices for local vs CI/CD


