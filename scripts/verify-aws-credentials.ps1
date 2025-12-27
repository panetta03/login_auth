# Verify AWS Credentials File Format
$credsPath = "$env:USERPROFILE\.aws\credentials"

Write-Host "Checking AWS credentials file: $credsPath" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $credsPath)) {
    Write-Host "❌ Credentials file not found!" -ForegroundColor Red
    exit 1
}

$content = Get-Content $credsPath
$accessKeyId = $null
$secretAccessKey = $null

foreach ($line in $content) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^aws_access_key_id\s*=\s*(.+)$') {
        $accessKeyId = $matches[1].Trim()
    }
    elseif ($trimmed -match '^aws_secret_access_key\s*=\s*(.+)$') {
        $secretAccessKey = $matches[1].Trim()
    }
}

Write-Host "Access Key ID:" -ForegroundColor Yellow
if ($accessKeyId) {
    Write-Host "  Value: $($accessKeyId.Substring(0,4))...$($accessKeyId.Substring($accessKeyId.Length-4))" -ForegroundColor Green
    Write-Host "  Length: $($accessKeyId.Length) (should be 20)" -ForegroundColor $(if ($accessKeyId.Length -eq 20) { "Green" } else { "Red" })
} else {
    Write-Host "  ❌ Not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Secret Access Key:" -ForegroundColor Yellow
if ($secretAccessKey) {
    Write-Host "  Value: ***$($secretAccessKey.Substring($secretAccessKey.Length-4))" -ForegroundColor Green
    Write-Host "  Length: $($secretAccessKey.Length) (should be 40)" -ForegroundColor $(if ($secretAccessKey.Length -eq 40) { "Green" } else { "Red" })
    if ($secretAccessKey.Length -ne 40) {
        Write-Host "  ⚠️  Warning: Length is not 40 characters!" -ForegroundColor Red
        Write-Host "  Check for extra spaces or characters" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing AWS connection..." -ForegroundColor Cyan
try {
    $result = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS credentials are working!" -ForegroundColor Green
        $result
    } else {
        Write-Host "❌ AWS credentials failed:" -ForegroundColor Red
        $result
    }
} catch {
    Write-Host "❌ Error testing credentials: $_" -ForegroundColor Red
}

