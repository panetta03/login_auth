variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  # Example: "your-org-terraform-state" or "auth-service-terraform-state"
}

