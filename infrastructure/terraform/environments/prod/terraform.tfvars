# Production Environment Variables

aws_region = "us-east-1"
environment = "prod"
project_name = "auth-service"

# Database
db_instance_class = "db.r6g.large"
db_allocated_storage = 100
db_multi_az = true

# Redis
redis_node_type = "cache.t3.medium"
redis_num_cache_nodes = 2

# ECS
ecs_min_capacity = 2
ecs_max_capacity = 10
ecs_cpu = 512
ecs_memory = 1024

# API Gateway
api_gateway_stage_name = "prod"
api_gateway_throttle_rate_limit = 1000
api_gateway_throttle_burst_limit = 2000


