output "api_gateway_url" {
  description = "API Gateway endpoint URL (includes environment as stage)"
  value       = module.api_gateway.api_gateway_url
}

output "oauth_callback_url" {
  description = "OAuth callback URL for Google OAuth configuration (includes environment)"
  value       = module.api_gateway.oauth_callback_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "database_url" {
  description = "Database connection URL"
  value       = module.rds.database_url
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.redis.endpoint
  sensitive   = true
}

