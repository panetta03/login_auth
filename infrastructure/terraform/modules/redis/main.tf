# ElastiCache Redis Module

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "allowed_security_groups" {
  type = list(string)
}

# Subnet Group for ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-auth-service-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  name        = "${var.environment}-auth-service-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-auth-service-redis-sg"
    Environment = var.environment
  }
}

# ElastiCache Replication Group (Multi-AZ)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.environment}-auth-service-redis"
  description                = "Redis cluster for auth service"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = var.node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-05:00"

  tags = {
    Name        = "${var.environment}-auth-service-redis"
    Environment = var.environment
  }
}

output "endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
  sensitive   = true
}

output "redis_url" {
  description = "Redis connection URL"
  value       = "redis://${aws_elasticache_replication_group.main.configuration_endpoint_address}:6379"
  sensitive   = true
}


