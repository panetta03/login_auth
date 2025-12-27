# Development Environment Variables

aws_region  = "us-east-2"
environment = "dev"

# Database
# NOTE: Set these via environment variables or terraform.tfvars (not committed to git)
# db_username = "your_db_username"
# db_password = "your_secure_password"  # Use AWS Secrets Manager in production

db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "auth_service"

# Redis
redis_node_type = "cache.t3.micro"

# ECR Repository URL
# Format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>
# Update with your actual ECR repository URL after it's created
ecr_repository_url = "881490096356.dkr.ecr.us-east-2.amazonaws.com/auth-service"

# Secrets Manager
secrets_manager_secret_name = "googleoauth"

