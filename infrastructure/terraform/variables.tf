variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "auth_service"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS (increases cost ~2x, use false for dev)"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups (0-35). Use lower values for dev to save costs"
  type        = number
  default     = 7
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.medium"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group. Use 1 for dev (faster, ~2-3 min), 2+ for prod (HA, ~7-15 min)"
  type        = number
  default     = 2
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)"
  type        = bool
  default     = true
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ deployment (requires num_cache_clusters >= 2)"
  type        = bool
  default     = true
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots (0-35). Use lower values for dev to save costs"
  type        = number
  default     = 7
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks (use 1 for dev to save costs)"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks (use 2 for dev, 10 for prod)"
  type        = number
  default     = 10
}

variable "ecs_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, etc.). Use 256 for dev to save costs"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Memory (MB) for ECS task. Use 512 for dev to save costs"
  type        = number
  default     = 512
}

variable "ecr_repository_url" {
  description = "ECR repository URL for Docker image"
  type        = string
}

variable "secrets_manager_secret_name" {
  description = "AWS Secrets Manager secret name for OAuth credentials"
  type        = string
  default     = "googleoauth"
}

variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique). If not provided, will be auto-generated based on environment and region."
  type        = string
  default     = ""
}

