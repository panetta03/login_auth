# GCP OAuth Configuration Verification Script
param(
    [string]$Environment = "dev",
    [string]$Region = "us-east-2"
)

Write-Host "Verifying GCP OAuth Configuration" -ForegroundColor Cyan
Write-Host ""

# Get API Gateway URL
Write-Host "1. Checking API Gateway Configuration..." -ForegroundColor Yellow
$apiGatewayId = "2tqnibdpg0"
$apiGatewayUrl = "https://${apiGatewayId}.execute-api.${Region}.amazonaws.com/${Environment}"
$expectedRedirectUri = "${apiGatewayUrl}/api/v1/auth/callback/google"

Write-Host "   API Gateway URL: $apiGatewayUrl" -ForegroundColor Green
Write-Host "   Expected Redirect URI: $expectedRedirectUri" -ForegroundColor Green
Write-Host ""

# Check AWS Secrets Manager
Write-Host "2. Checking AWS Secrets Manager Configuration..." -ForegroundColor Yellow
$secretOutput = aws secretsmanager get-secret-value --secret-id googleoauth --region $Region --query 'SecretString' --output text 2>&1
if ($LASTEXITCODE -eq 0) {
    $secrets = $secretOutput | ConvertFrom-Json
    
    if ($secrets.GOOGLE_CLIENT_ID -match '^\d+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$') {
        Write-Host "   GOOGLE_CLIENT_ID format is valid" -ForegroundColor Green
        Write-Host "      Client ID: $($secrets.GOOGLE_CLIENT_ID)" -ForegroundColor Gray
    } else {
        Write-Host "   GOOGLE_CLIENT_ID format is invalid" -ForegroundColor Red
        Write-Host "      Expected format: xxxxx-xxxxx.apps.googleusercontent.com" -ForegroundColor Yellow
    }
    
    if ($secrets.GOOGLE_CLIENT_SECRET -match '^GOCSPX-') {
        Write-Host "   GOOGLE_CLIENT_SECRET format is valid" -ForegroundColor Green
    } else {
        Write-Host "   GOOGLE_CLIENT_SECRET format is invalid" -ForegroundColor Red
        Write-Host "      Expected format: GOCSPX-xxxxx" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Failed to retrieve secrets" -ForegroundColor Red
}

Write-Host ""

# Check ECS Task Configuration
Write-Host "3. Checking ECS Task Configuration..." -ForegroundColor Yellow
$taskDefJson = aws ecs describe-task-definition --task-definition "${Environment}-auth-service" --region $Region --query 'taskDefinition.containerDefinitions[0].environment' --output json 2>&1
if ($LASTEXITCODE -eq 0) {
    $taskDef = $taskDefJson | ConvertFrom-Json
    $redirectUriEnv = $taskDef | Where-Object { $_.name -eq "GOOGLE_REDIRECT_URI" }
    
    if ($redirectUriEnv) {
        $redirectUri = $redirectUriEnv.value
        Write-Host "   Current GOOGLE_REDIRECT_URI: $redirectUri" -ForegroundColor Gray
        if ($redirectUri -eq $expectedRedirectUri) {
            Write-Host "   Redirect URI matches expected value" -ForegroundColor Green
        } else {
            Write-Host "   Redirect URI mismatch" -ForegroundColor Yellow
            Write-Host "      Expected: $expectedRedirectUri" -ForegroundColor Yellow
            Write-Host "      Current:  $redirectUri" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   GOOGLE_REDIRECT_URI not set in task definition" -ForegroundColor Yellow
        Write-Host "      Will use default: http://localhost:3000/api/v1/auth/callback/google" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Could not check ECS task definition" -ForegroundColor Yellow
}

Write-Host ""

# GCP Configuration Checklist
Write-Host "4. GCP Console Checklist (Manual Verification Required)" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Please verify the following in Google Cloud Console:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor White
Write-Host ""
Write-Host "   OAuth 2.0 Client ID Type: Web application" -ForegroundColor White
Write-Host ""
Write-Host "   Authorized redirect URIs must include:" -ForegroundColor White
Write-Host "      $expectedRedirectUri" -ForegroundColor Green
Write-Host ""
Write-Host "   Go to: https://console.cloud.google.com/apis/credentials/consent" -ForegroundColor White
Write-Host ""
Write-Host "   OAuth consent screen is published (or in Testing mode)" -ForegroundColor White
Write-Host "   Required scopes are approved:" -ForegroundColor White
Write-Host "      - openid" -ForegroundColor Gray
Write-Host "      - email" -ForegroundColor Gray
Write-Host "      - profile" -ForegroundColor Gray
Write-Host ""
Write-Host "   Note: No APIs need to be enabled!" -ForegroundColor Gray
Write-Host "   OAuth 2.0 uses public Google endpoints that don't require API enablement." -ForegroundColor Gray
Write-Host ""

# Test URL
Write-Host "5. Test OAuth Flow" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Test URL (open in browser):" -ForegroundColor Cyan
Write-Host "   $apiGatewayUrl/api/v1/auth/login/google" -ForegroundColor Green
Write-Host ""
Write-Host "   Expected behavior:" -ForegroundColor Cyan
Write-Host "   1. Should redirect to Google OAuth consent page" -ForegroundColor White
Write-Host "   2. After consent, should redirect back with code and state parameters" -ForegroundColor White
Write-Host "   3. If you see redirect_uri_mismatch error, check GCP redirect URI configuration" -ForegroundColor Yellow
Write-Host ""

# Summary
Write-Host "Summary" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected Redirect URI for GCP:" -ForegroundColor Yellow
Write-Host "$expectedRedirectUri" -ForegroundColor Green
Write-Host ""
Write-Host "Make sure this EXACT URL is in GCP Authorized redirect URIs list." -ForegroundColor Yellow
Write-Host "The URL is case-sensitive and must match exactly (including /dev prefix)." -ForegroundColor Yellow
Write-Host ""
