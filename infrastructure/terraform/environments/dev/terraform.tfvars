# Development Environment Variables

aws_region  = "us-east-2"
environment = "dev"

# Database
# NOTE: Set these via environment variables or terraform.tfvars (not committed to git)
# db_username = "your_db_username"
# db_password = "your_secure_password"  # Use AWS Secrets Manager in production

db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_name                    = "auth_service"
db_multi_az                = false # Single-AZ for dev (saves ~50% cost)
db_backup_retention_period = 1     # 1 day for dev (saves storage costs)

# Redis
redis_node_type                  = "cache.t3.micro"
redis_num_cache_clusters         = 1     # Single node for dev (faster creation, ~2-3 min vs ~7-15 min)
redis_automatic_failover_enabled = false # Not needed for single node
redis_multi_az_enabled           = false # Not needed for single node
redis_snapshot_retention_limit   = 1     # 1 day for dev (saves storage costs)

# ECS
ecs_min_capacity = 1   # Single task for dev (saves costs)
ecs_max_capacity = 2   # Max 2 tasks for dev (sufficient for <10 users)
ecs_cpu          = 256 # Minimum CPU for dev (saves costs)
ecs_memory       = 512 # Minimum memory for dev (saves costs)

# ECR Repository URL
# Format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>
# Update with your actual ECR repository URL after it's created
ecr_repository_url = "881490096356.dkr.ecr.us-east-2.amazonaws.com/auth-service"

# Secrets Manager
secrets_manager_secret_name = "googleoauth"

