# Development Environment Variables

aws_region = "us-east-1"
environment = "dev"
project_name = "auth-service"

# Database
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_multi_az = false

# Redis
redis_node_type = "cache.t3.micro"
redis_num_cache_nodes = 1

# ECS
ecs_min_capacity = 1
ecs_max_capacity = 3
ecs_cpu = 256
ecs_memory = 512

# API Gateway
api_gateway_stage_name = "dev"
api_gateway_throttle_rate_limit = 100
api_gateway_throttle_burst_limit = 200




