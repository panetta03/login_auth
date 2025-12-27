# Terraform Local Development Helper Script
# Usage: .\scripts\terraform-local.ps1 [command] [environment]
# Example: .\scripts\terraform-local.ps1 plan dev

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate", "fmt")]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"
$TerraformDir = $PSScriptRoot + "\.."
$BackendConfig = "$TerraformDir\backend.local.hcl"
$TfVarsFile = "$TerraformDir\environments\$Environment\terraform.tfvars"

# Check if backend config exists
if (-not (Test-Path $BackendConfig)) {
    Write-Host "❌ Backend config not found: $BackendConfig" -ForegroundColor Red
    Write-Host "📝 Creating from example..." -ForegroundColor Yellow
    
    $ExampleFile = "$TerraformDir\backend.local.hcl.example"
    if (Test-Path $ExampleFile) {
        Copy-Item $ExampleFile $BackendConfig
        Write-Host "✅ Created $BackendConfig" -ForegroundColor Green
        Write-Host "⚠️  Please edit $BackendConfig with your values before continuing" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "❌ Example file not found: $ExampleFile" -ForegroundColor Red
        exit 1
    }
}

# Check if tfvars file exists
if (-not (Test-Path $TfVarsFile)) {
    Write-Host "❌ Terraform vars file not found: $TfVarsFile" -ForegroundColor Red
    exit 1
}

# Change to Terraform directory
Push-Location $TerraformDir

try {
    switch ($Command) {
        "init" {
            Write-Host "🔧 Initializing Terraform with backend config..." -ForegroundColor Cyan
            terraform init -backend-config=$BackendConfig -reconfigure
        }
        
        "plan" {
            Write-Host "📋 Running Terraform plan for $Environment..." -ForegroundColor Cyan
            
            # Check for required environment variables
            $dbUsername = $env:TF_VAR_db_username
            $dbPassword = $env:TF_VAR_db_password
            
            if (-not $dbUsername -or -not $dbPassword) {
                Write-Host "⚠️  Warning: TF_VAR_db_username or TF_VAR_db_password not set" -ForegroundColor Yellow
                Write-Host "   Using -var flags (you'll be prompted if missing)" -ForegroundColor Yellow
                
                $varFlags = @()
                if ($dbUsername) { $varFlags += "-var=`"db_username=$dbUsername`"" }
                if ($dbPassword) { $varFlags += "-var=`"db_password=$dbPassword`"" }
                
                terraform plan -var-file=$TfVarsFile $varFlags
            } else {
                terraform plan -var-file=$TfVarsFile
            }
        }
        
        "apply" {
            Write-Host "🚀 Applying Terraform changes for $Environment..." -ForegroundColor Cyan
            Write-Host "⚠️  This will modify AWS resources!" -ForegroundColor Yellow
            
            $confirm = Read-Host "Type 'yes' to continue"
            if ($confirm -ne "yes") {
                Write-Host "❌ Cancelled" -ForegroundColor Red
                exit 0
            }
            
            $dbUsername = $env:TF_VAR_db_username
            $dbPassword = $env:TF_VAR_db_password
            
            $varFlags = @()
            if ($dbUsername) { $varFlags += "-var=`"db_username=$dbUsername`"" }
            if ($dbPassword) { $varFlags += "-var=`"db_password=$dbPassword`"" }
            
            terraform apply -var-file=$TfVarsFile $varFlags
        }
        
        "destroy" {
            Write-Host "💥 Destroying Terraform infrastructure for $Environment..." -ForegroundColor Red
            Write-Host "⚠️  WARNING: This will DELETE all infrastructure!" -ForegroundColor Red
            
            $confirm = Read-Host "Type the environment name '$Environment' to confirm"
            if ($confirm -ne $Environment) {
                Write-Host "❌ Cancelled" -ForegroundColor Red
                exit 0
            }
            
            $dbUsername = $env:TF_VAR_db_username
            $dbPassword = $env:TF_VAR_db_password
            
            $varFlags = @()
            if ($dbUsername) { $varFlags += "-var=`"db_username=$dbUsername`"" }
            if ($dbPassword) { $varFlags += "-var=`"db_password=$dbPassword`"" }
            
            terraform destroy -var-file=$TfVarsFile $varFlags
        }
        
        "validate" {
            Write-Host "✅ Validating Terraform configuration..." -ForegroundColor Cyan
            terraform validate
        }
        
        "fmt" {
            Write-Host "🎨 Formatting Terraform files..." -ForegroundColor Cyan
            terraform fmt -recursive
        }
    }
} finally {
    Pop-Location
}

