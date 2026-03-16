#!/bin/sh
# Local pipeline runner for testing with act

set -e

echo "========================================="
echo "Local CI Pipeline Runner (act-compatible)"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create necessary directories
mkdir -p build coverage

# Load environment if exists
if [ -f ".env" ]; then
    echo "Loading environment variables..."
    set -a
    . .env
    set +a
fi

# Simulate GitHub Actions environment
export GITHUB_WORKSPACE="$(pwd)"
export GITHUB_ACTION="local-runner"
export GITHUB_RUN_ID="local-$(date +%s)"
export CI=true

echo ""
echo "Step 1: Code Quality Check"
echo "-----------------------------------------"
if bash scripts/lint.sh; then
    echo -e "${GREEN}✓ Code quality passed${NC}"
else
    echo -e "${RED}✗ Code quality failed${NC}"
    exit 1
fi

echo ""
echo "Step 2: Static Type Check"
echo "-----------------------------------------"
if bash scripts/typecheck.sh; then
    echo -e "${GREEN}✓ Type check passed${NC}"
else
    echo -e "${RED}✗ Type check failed${NC}"
    exit 1
fi

echo ""
echo "Step 3: Security Scan"
echo "-----------------------------------------"
if bash scripts/security.sh; then
    echo -e "${GREEN}✓ Security scan passed${NC}"
else
    echo -e "${RED}✗ Security scan failed${NC}"
    exit 1
fi

echo ""
echo "Step 4: Tests & Coverage"
echo "-----------------------------------------"
if bash scripts/test.sh; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi

echo ""
echo "Step 5: Build"
echo "-----------------------------------------"
if bash scripts/build.sh; then
    echo -e "${GREEN}✓ Build succeeded${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo -e "${GREEN}✓ All CI stages completed successfully!${NC}"
echo "========================================="
