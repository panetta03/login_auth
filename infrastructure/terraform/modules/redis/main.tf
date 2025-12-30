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

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group. Use 1 for dev (faster), 2+ for prod (HA)"
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment (requires num_cache_clusters >= 2)"
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots (0-35). Use lower values for dev to save costs"
  type        = number
  default     = 7
}

variable "allowed_security_groups" {
  type = list(string)
}

variable "auth_token" {
  description = "Auth token for Redis (required when transit_encryption_enabled is true). Leave empty for new clusters (AWS will generate), provide existing token when modifying existing clusters."
  type        = string
  default     = null
  sensitive   = true
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
  num_cache_clusters = var.num_cache_clusters
  # Auto-failover requires at least 2 nodes. When reducing to 1 node, disable it first.
  # Note: If reducing from 2+ nodes to 1, AWS requires auto-failover to be disabled BEFORE reducing nodes.
  # The logic below ensures auto-failover is disabled when num_cache_clusters=1
  automatic_failover_enabled = var.num_cache_clusters >= 2 ? var.automatic_failover_enabled : false
  multi_az_enabled           = var.num_cache_clusters >= 2 ? var.multi_az_enabled : false
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = "03:00-05:00"

  lifecycle {
    ignore_changes = [
      # Ignore auth_token changes to avoid issues when modifying existing clusters
      # If you need to rotate the token, do it manually via AWS console/CLI first
      auth_token,
    ]
    
    # When reducing from 2+ nodes to 1 node, AWS requires auto-failover to be disabled first
    # This lifecycle rule ensures changes are applied in the correct order
    # If reducing nodes fails, disable auto-failover manually first, then re-run
    create_before_destroy = false
  }

  tags = {
    Name        = "${var.environment}-auth-service-redis"
    Environment = var.environment
  }
}

output "endpoint" {
  description = "Redis primary endpoint"
  # For single-node (num_cache_clusters=1), use primary_endpoint_address
  # For multi-node (num_cache_clusters>=2), use configuration_endpoint_address
  value     = var.num_cache_clusters == 1 ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address
  sensitive = true
}

output "redis_url" {
  description = "Redis connection URL (uses rediss:// for TLS when transit encryption is enabled)"
  # Use rediss:// (with double 's') for TLS when transit_encryption_enabled = true
  value       = var.num_cache_clusters == 1 ? "rediss://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379" : "rediss://${aws_elasticache_replication_group.main.configuration_endpoint_address}:6379"
  sensitive   = true
}


