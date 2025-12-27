# Deployment Secrets Management

## Overview

Different credentials are stored in different places depending on their purpose:

## 1. GitHub Actions Deployment Credentials

**Location:** GitHub Repository Secrets (Settings → Secrets and variables → Actions)

**Required Secrets:**
- `AWS_ACCESS_KEY_ID` - For GitHub Actions to authenticate with AWS
- `AWS_SECRET_ACCESS_KEY` - For GitHub Actions to authenticate with AWS

**Purpose:** These credentials allow GitHub Actions to:
- Push Docker images to ECR
- Update ECS services
- Deploy infrastructure (if using Terraform in CI/CD)

**⚠️ Important:** These are **NOT** stored in AWS Secrets Manager. They're GitHub Secrets used only during deployment.

## 2. ECS Service Runtime Credentials

**Location:** IAM Roles (attached to ECS Task Definition)

**How it works:**
- ECS tasks use an **IAM role** (not access keys)
- The IAM role grants permissions to:
  - Read from AWS Secrets Manager
  - Write to CloudWatch Logs
  - Access RDS (if using IAM authentication)
  - Access ElastiCache

**Configuration:** Set in Terraform ECS module:
```hcl
task_execution_role_arn = aws_iam_role.ecs_task_execution.arn
task_role_arn = aws_iam_role.ecs_task.arn
```

**✅ Best Practice:** Never put AWS access keys in Secrets Manager or environment variables for ECS tasks. Use IAM roles.

## 3. Application Secrets (OAuth, JWT Keys, etc.)

**Location:** AWS Secrets Manager

**Required Secrets:**
- `googleoauth` - Contains:
  ```json
  {
    "GOOGLE_CLIENT_ID": "your-client-id",
    "GOOGLE_CLIENT_SECRET": "your-client-secret"
  }
  ```
- `auth-service/jwt-keys` (optional) - JWT signing keys if not generating locally

**How it works:**
- Application fetches secrets from Secrets Manager at startup
- Secrets are cached in memory
- ECS task IAM role must have `secretsmanager:GetSecretValue` permission

## Summary Table

| Credential Type | Storage Location | Used By | Purpose |
|----------------|------------------|---------|---------|
| AWS Access Keys | GitHub Secrets | GitHub Actions | Deploy to AWS |
| AWS Access Keys | **NOT in Secrets Manager** | - | ECS uses IAM roles instead |
| IAM Role | ECS Task Definition | ECS Tasks | Runtime AWS permissions |
| Google OAuth | AWS Secrets Manager | Application | OAuth authentication |
| JWT Keys | AWS Secrets Manager (optional) | Application | JWT signing |

## Setup Steps

### 1. GitHub Secrets (for deployment)
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Add:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. These credentials should have permissions for:
   - ECR (push images)
   - ECS (update services)
   - Secrets Manager (read - if needed for deployment)

### 2. IAM Role for ECS (for runtime)
1. Create IAM role in Terraform
2. Attach policies:
   - `AmazonECSTaskExecutionRolePolicy`
   - Custom policy for Secrets Manager access
3. Attach role to ECS task definition

### 3. Application Secrets in Secrets Manager
1. Create secret `googleoauth` in AWS Secrets Manager
2. Format:
   ```json
   {
     "GOOGLE_CLIENT_ID": "your-client-id",
     "GOOGLE_CLIENT_SECRET": "your-client-secret"
   }
   ```
3. Ensure ECS task IAM role can access it

## Security Best Practices

✅ **DO:**
- Use IAM roles for ECS tasks (not access keys)
- Store application secrets in Secrets Manager
- Use GitHub Secrets for CI/CD credentials
- Rotate secrets regularly

❌ **DON'T:**
- Put AWS access keys in Secrets Manager for ECS
- Commit secrets to git
- Use long-lived access keys for ECS tasks
- Store secrets in environment variables in ECS

