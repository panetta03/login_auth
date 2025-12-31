# API Gateway Module

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_service_arn" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "rest_api_id" {
  type        = string
  description = "The REST API ID (created in root module to break circular dependency)"
}

variable "root_resource_id" {
  type        = string
  description = "The root resource ID of the REST API (obtained from data source in root module)"
}

# No data source needed - root_resource_id is passed as variable from root module

# API Gateway Resource - Proxy
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = var.rest_api_id
  parent_id   = var.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method - Proxy
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# API Gateway Integration - Proxy to ALB
# HTTP_PROXY with passthrough_behavior = "WHEN_NO_MATCH" automatically passes all query parameters
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/{proxy}"
  passthrough_behavior    = "WHEN_NO_MATCH"
  timeout_milliseconds    = 29000 # API Gateway max timeout (29 seconds)

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# API Gateway Root Method
resource "aws_api_gateway_method" "root" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Root Integration
resource "aws_api_gateway_integration" "root" {
  rest_api_id = var.rest_api_id
  resource_id = var.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/"
  passthrough_behavior    = "WHEN_NO_MATCH"
  timeout_milliseconds    = 29000 # API Gateway max timeout (29 seconds)
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_method.root,
    aws_api_gateway_integration.root,
  ]

  rest_api_id = var.rest_api_id
  # stage_name is deprecated - use aws_api_gateway_stage resource instead

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = var.rest_api_id
  stage_name    = var.environment

  lifecycle {
    # Stage may already exist from previous deployments
    # Use create_before_destroy to handle updates gracefully
    create_before_destroy = true
    ignore_changes = [deployment_id]
  }

  tags = {
    Name        = "${var.environment}-auth-service-api-stage"
    Environment = var.environment
  }
}

output "api_gateway_url" {
  description = "API Gateway endpoint URL (includes environment as stage)"
  value       = "https://${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
}

output "oauth_callback_url" {
  description = "OAuth callback URL for Google OAuth configuration (includes environment)"
  value       = "https://${var.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}/api/v1/auth/callback/google"
}

data "aws_region" "current" {}


