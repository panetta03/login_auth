# Infrastructure Setup Guide

This directory contains Terraform configuration for deploying the auth service infrastructure to AWS.

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (>= 1.0)
3. **AWS Account** with permissions to create:
   - VPC, Subnets, Internet Gateway, NAT Gateway
   - ECS Cluster, Service, Task Definitions
   - RDS PostgreSQL database
   - ElastiCache Redis
   - Application Load Balancer
   - Security Groups
   - IAM Roles and Policies
   - CloudWatch Log Groups

## Quick Start

### 1. Configure Terraform Backend (Optional but Recommended)

Edit `main.tf` to configure S3 backend for state management:

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "auth-service/terraform.tfstate"
  region = "us-east-2"
}
```

### 2. Set Up Environment Variables

Choose an environment (dev or prod) and configure variables:

```bash
cd infrastructure/terraform/environments/dev
```

Edit `terraform.tfvars` with your values:

```hcl
environment = "dev"
aws_region  = "us-east-2"

# Database credentials
db_username = "your_db_username"
db_password = "your_secure_password"  # Store securely, use secrets manager in production

# ECR repository URL (format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>)
ecr_repository_url = "881490096356.dkr.ecr.us-east-2.amazonaws.com/auth-service"

# Secrets Manager secret name for OAuth credentials
secrets_manager_secret_name = "googleoauth"
```

### 3. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

### 4. Plan the Infrastructure

```bash
# For dev environment
terraform workspace select dev || terraform workspace new dev
terraform plan -var-file=environments/dev/terraform.tfvars
```

### 5. Apply the Infrastructure

```bash
terraform apply -var-file=environments/dev/terraform.tfvars
```

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

After Terraform creates the infrastructure, update GitHub Secrets:

- `ECS_CLUSTER` - ECS cluster name (e.g., `dev-auth-service-cluster`)
- `ECS_SERVICE` - ECS service name (e.g., `dev-auth-service`)

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

1. **First-time Setup**: The CD pipeline expects infrastructure to exist. Run Terraform first before deploying via GitHub Actions.

2. **Subnets**: The infrastructure creates properly configured subnets. The CD pipeline will use the existing ECS service - it won't create new subnets.

3. **Security**: 
   - Database passwords should be stored in AWS Secrets Manager in production
   - Use different credentials for dev/prod environments
   - Enable encryption at rest for RDS and ElastiCache

4. **Costs**: 
   - NAT Gateway incurs hourly charges (~$0.045/hour)
   - RDS and ElastiCache have instance costs
   - Consider using smaller instance types for dev

5. **State Management**: Use S3 backend for Terraform state to enable team collaboration and state locking.

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

## Next Steps

After infrastructure is created:
1. Store OAuth credentials in AWS Secrets Manager
2. Run database migrations
3. The CD pipeline will deploy new Docker images automatically

