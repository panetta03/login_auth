terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure backend in terraform.tfvars or via environment variables
    # bucket = "your-terraform-state-bucket"
    # key    = "auth-service/terraform.tfstate"
    # region = "us-east-1"
    # test3
  }
}

provider "aws" {
  region = var.aws_region
}

# Local values for state bucket name
locals {
  state_bucket_name = var.terraform_state_bucket_name != "" ? var.terraform_state_bucket_name : "auth-service-terraform-state-${var.environment}-${var.aws_region}"
}

# State Backend Module (creates S3 bucket and DynamoDB table for Terraform state)
module "state_backend" {
  source = "./modules/state-backend"

  state_bucket_name = local.state_bucket_name
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_multi_az             = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  allowed_security_groups = [module.ecs.security_group_id]
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  allowed_security_groups    = [module.ecs.security_group_id]
}

# API Gateway REST API (created first to get the ID for redirect URI)
# We create just the REST API resource first, then the integration after ECS is created
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.environment}-auth-service-api"
  description = "Auth Service REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.environment}-auth-service-api"
    Environment = var.environment
  }
}

# Data source to get the root resource ID (needed for API Gateway resources)
# Use id instead of name to avoid multiple matches
data "aws_api_gateway_rest_api" "main" {
  id = aws_api_gateway_rest_api.main.id
}

# Local value for constructing redirect URI from API Gateway REST API ID
locals {
  google_redirect_uri = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/api/v1/auth/callback/google"
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnet_ids
  private_subnet_ids          = module.vpc.private_subnet_ids
  ecr_repository_url          = var.ecr_repository_url
  database_url                = module.rds.database_url
  redis_url                   = module.redis.redis_url
  aws_region                  = var.aws_region
  secrets_manager_secret_name = var.secrets_manager_secret_name
  ecs_min_capacity            = var.ecs_min_capacity
  ecs_max_capacity            = var.ecs_max_capacity
  ecs_cpu                     = var.ecs_cpu
  ecs_memory                  = var.ecs_memory
  # Redirect URI constructed from API Gateway REST API ID
  google_redirect_uri = local.google_redirect_uri
}

# API Gateway Module (integration and other resources)
module "api_gateway" {
  source = "./modules/api-gateway"

  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  ecs_service_arn  = module.ecs.service_arn
  alb_dns_name     = module.ecs.alb_dns_name
  rest_api_id      = aws_api_gateway_rest_api.main.id
  root_resource_id = data.aws_api_gateway_rest_api.main.root_resource_id
}
