#!/bin/bash
# Terraform Local Development Helper Script
# Usage: ./scripts/terraform-local.sh [command] [environment]
# Example: ./scripts/terraform-local.sh plan dev

set -e

COMMAND="${1:-}"
ENVIRONMENT="${2:-dev}"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 [init|plan|apply|destroy|validate|fmt] [dev|prod]"
    exit 1
fi

if [[ ! "$COMMAND" =~ ^(init|plan|apply|destroy|validate|fmt)$ ]]; then
    echo "❌ Invalid command: $COMMAND"
    echo "Valid commands: init, plan, apply, destroy, validate, fmt"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, prod"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_CONFIG="$TERRAFORM_DIR/backend.local.hcl"
TFVARS_FILE="$TERRAFORM_DIR/environments/$ENVIRONMENT/terraform.tfvars"

# Check if backend config exists
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo "❌ Backend config not found: $BACKEND_CONFIG"
    echo "📝 Creating from example..."
    
    EXAMPLE_FILE="$TERRAFORM_DIR/backend.local.hcl.example"
    if [ -f "$EXAMPLE_FILE" ]; then
        cp "$EXAMPLE_FILE" "$BACKEND_CONFIG"
        echo "✅ Created $BACKEND_CONFIG"
        echo "⚠️  Please edit $BACKEND_CONFIG with your values before continuing"
        exit 1
    else
        echo "❌ Example file not found: $EXAMPLE_FILE"
        exit 1
    fi
fi

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Terraform vars file not found: $TFVARS_FILE"
    exit 1
fi

# Change to Terraform directory
cd "$TERRAFORM_DIR"

case "$COMMAND" in
    init)
        echo "🔧 Initializing Terraform with backend config..."
        terraform init -backend-config="$BACKEND_CONFIG" -reconfigure
        ;;
    
    plan)
        echo "📋 Running Terraform plan for $ENVIRONMENT..."
        
        # Check for required environment variables
        if [ -z "$TF_VAR_db_username" ] || [ -z "$TF_VAR_db_password" ]; then
            echo "⚠️  Warning: TF_VAR_db_username or TF_VAR_db_password not set"
            echo "   Using -var flags (you'll be prompted if missing)"
            
            VAR_FLAGS=""
            [ -n "$TF_VAR_db_username" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_username=$TF_VAR_db_username\""
            [ -n "$TF_VAR_db_password" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_password=$TF_VAR_db_password\""
            
            terraform plan -var-file="$TFVARS_FILE" $VAR_FLAGS
        else
            terraform plan -var-file="$TFVARS_FILE"
        fi
        ;;
    
    apply)
        echo "🚀 Applying Terraform changes for $ENVIRONMENT..."
        echo "⚠️  This will modify AWS resources!"
        
        read -p "Type 'yes' to continue: " confirm
        if [ "$confirm" != "yes" ]; then
            echo "❌ Cancelled"
            exit 0
        fi
        
        VAR_FLAGS=""
        [ -n "$TF_VAR_db_username" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_username=$TF_VAR_db_username\""
        [ -n "$TF_VAR_db_password" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_password=$TF_VAR_db_password\""
        
        terraform apply -var-file="$TFVARS_FILE" $VAR_FLAGS
        ;;
    
    destroy)
        echo "💥 Destroying Terraform infrastructure for $ENVIRONMENT..."
        echo "⚠️  WARNING: This will DELETE all infrastructure!"
        
        read -p "Type the environment name '$ENVIRONMENT' to confirm: " confirm
        if [ "$confirm" != "$ENVIRONMENT" ]; then
            echo "❌ Cancelled"
            exit 0
        fi
        
        VAR_FLAGS=""
        [ -n "$TF_VAR_db_username" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_username=$TF_VAR_db_username\""
        [ -n "$TF_VAR_db_password" ] && VAR_FLAGS="$VAR_FLAGS -var=\"db_password=$TF_VAR_db_password\""
        
        terraform destroy -var-file="$TFVARS_FILE" $VAR_FLAGS
        ;;
    
    validate)
        echo "✅ Validating Terraform configuration..."
        terraform validate
        ;;
    
    fmt)
        echo "🎨 Formatting Terraform files..."
        terraform fmt -recursive
        ;;
esac


