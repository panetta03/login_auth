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

  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  allowed_security_groups = [module.ecs.security_group_id]
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.redis_node_type
  allowed_security_groups = [module.ecs.security_group_id]
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecr_repository_url      = var.ecr_repository_url
  database_url            = module.rds.database_url
  redis_url               = module.redis.redis_url
  aws_region              = var.aws_region
  secrets_manager_secret_name = var.secrets_manager_secret_name
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  ecs_service_arn = module.ecs.service_arn
  alb_dns_name    = module.ecs.alb_dns_name
}

