# Production Environment Variables

aws_region   = "us-east-1"
environment  = "prod"
project_name = "auth-service"

# Database
db_instance_class          = "db.r6g.large"
db_allocated_storage       = 100
db_multi_az                = true # Multi-AZ for prod (HA, but ~2x cost)
db_backup_retention_period = 7    # 7 days for prod

# Redis
redis_node_type                  = "cache.t3.medium"
redis_num_cache_clusters         = 2 # Multi-node for HA (slower creation, ~7-15 min)
redis_automatic_failover_enabled = true
redis_multi_az_enabled           = true
redis_snapshot_retention_limit   = 7 # 7 days for prod

# ECR Repository URL
# Format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>
ecr_repository_url = "881490096356.dkr.ecr.us-east-2.amazonaws.com/auth-service"

# Secrets Manager
secrets_manager_secret_name = "googleoauth"

# ECS
ecs_min_capacity = 2
ecs_max_capacity = 10
ecs_cpu          = 512
ecs_memory       = 1024

# API Gateway
api_gateway_stage_name           = "prod"
api_gateway_throttle_rate_limit  = 1000
api_gateway_throttle_burst_limit = 2000


