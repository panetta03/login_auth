# Setup script to install git hooks for pre-commit validation
# Run this once after cloning the repository

Write-Host "Setting up git hooks for pre-commit validation..." -ForegroundColor Cyan

$hooksDir = ".git\hooks"
$preCommitHook = "$hooksDir\pre-commit"

# Create hooks directory if it doesn't exist
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

# Copy the pre-commit hook (use shell script format for cross-platform compatibility)
if (Test-Path ".\scripts\ci-local.ps1") {
    $hookContent = @"
#!/bin/sh
# Pre-commit hook - runs CI checks before allowing commit
# This hook calls the local CI script

# Try to run the CI script (works on Linux/Mac)
if [ -f "./scripts/ci-local.sh" ]; then
  ./scripts/ci-local.sh
  EXIT_CODE=`$?
elif [ -f "./scripts/ci-local.ps1" ]; then
  # On Windows, try to run PowerShell script
  powershell.exe -ExecutionPolicy Bypass -File "./scripts/ci-local.ps1"
  EXIT_CODE=`$?
else
  # Fallback: run npm commands directly
  npm ci && npm run lint && npm run type-check && npm run build && npm run test:coverage
  EXIT_CODE=`$?
fi

if [ `$EXIT_CODE -ne 0 ]; then
  echo ""
  echo "Pre-commit checks failed. Please fix the errors before committing."
  echo "You can bypass this hook with: git commit --no-verify"
  exit 1
fi

exit 0
"@
    
    Set-Content -Path $preCommitHook -Value $hookContent -NoNewline
    Write-Host "✅ Pre-commit hook installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The hook will now run CI checks before each commit." -ForegroundColor Yellow
    Write-Host "To bypass: git commit --no-verify" -ForegroundColor Gray
} else {
    Write-Host "❌ Error: scripts/ci-local.ps1 not found!" -ForegroundColor Red
    exit 1
}

