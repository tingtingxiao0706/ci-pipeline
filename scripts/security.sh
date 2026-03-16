# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo "Running security scan..."
echo "----------------------------------------"

# Run bandit security scanner
bandit -r app/ -f json -o security-report.json || {
    echo "❌ Security scan failed. Check security-report.json"
    exit 1
}

# Check for common vulnerabilities
echo "Checking for secrets in code..."
if git ls-files | grep -E "(\.env|\.key|\.pem|id_rsa)" | grep -v "^config/"; then
    echo "❌ Possible secrets found in repository!"
    exit 1
fi

echo "✅ Security scan completed!"
