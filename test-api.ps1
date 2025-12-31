# Test Auth Service API Endpoints
$BASE_URL = "https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev"

Write-Host "Testing Auth Service API at: $BASE_URL" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/health" -Method Get
    Write-Host "✓ Health check passed" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "✗ Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Readiness Check
Write-Host "2. Testing Readiness Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/ready" -Method Get
    Write-Host "✓ Readiness check passed" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "✗ Readiness check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: JWKS Endpoint
Write-Host "3. Testing JWKS Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/.well-known/jwks.json" -Method Get
    Write-Host "✓ JWKS endpoint accessible" -ForegroundColor Green
    Write-Host "Keys found: $($response.keys.Count)"
} catch {
    Write-Host "✗ JWKS endpoint failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: OAuth Login (Google) - This will return a redirect
Write-Host "4. Testing OAuth Login (Google)..." -ForegroundColor Yellow
Write-Host "Note: This will redirect to Google OAuth" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/v1/auth/login/google" -Method Get -MaximumRedirection 0 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 302) {
        Write-Host "✓ OAuth login redirect working" -ForegroundColor Green
        Write-Host "Redirect location: $($response.Headers.Location)"
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 302) {
        Write-Host "✓ OAuth login redirect working (302)" -ForegroundColor Green
    } else {
        Write-Host "✗ OAuth login failed: $_" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "API Testing Complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test OAuth flow:" -ForegroundColor Yellow
Write-Host "1. Open in browser: $BASE_URL/api/v1/auth/login/google" -ForegroundColor White
Write-Host "2. Complete OAuth flow" -ForegroundColor White
Write-Host "3. You'll receive tokens in the callback" -ForegroundColor White

