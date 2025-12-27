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

