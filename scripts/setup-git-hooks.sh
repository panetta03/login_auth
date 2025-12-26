#!/bin/bash
# Setup script to install git hooks for pre-commit validation
# Run this once after cloning the repository

echo "Setting up git hooks for pre-commit validation..."

HOOKS_DIR=".git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create the pre-commit hook
if [ -f "./scripts/ci-local.sh" ]; then
    cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/sh
# Pre-commit hook - runs CI checks before allowing commit
# This hook calls the local CI script

# Try to run the CI script (works on Linux/Mac)
if [ -f "./scripts/ci-local.sh" ]; then
  ./scripts/ci-local.sh
  EXIT_CODE=$?
elif [ -f "./scripts/ci-local.ps1" ]; then
  # On Windows, try to run PowerShell script
  powershell.exe -ExecutionPolicy Bypass -File "./scripts/ci-local.ps1"
  EXIT_CODE=$?
else
  # Fallback: run npm commands directly
  npm ci && npm run lint && npm run type-check && npm run build && npm run test:coverage
  EXIT_CODE=$?
fi

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "Pre-commit checks failed. Please fix the errors before committing."
  echo "You can bypass this hook with: git commit --no-verify"
  exit 1
fi

exit 0
EOF
    
    chmod +x "$PRE_COMMIT_HOOK"
    echo "✅ Pre-commit hook installed successfully!"
    echo ""
    echo "The hook will now run CI checks before each commit."
    echo "To bypass: git commit --no-verify"
else
    echo "❌ Error: scripts/ci-local.sh not found!"
    exit 1
fi

