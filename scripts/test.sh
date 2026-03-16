# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo "Running tests with coverage..."
echo "----------------------------------------"

# Create coverage directory
mkdir -p coverage

# Run pytest with coverage
pytest tests/ \
    --cov=app \
    --cov-report=xml:coverage/coverage.xml \
    --cov-report=html:coverage/html \
    --cov-report=term \
    --cov-fail-under=${COVERAGE_THRESHOLD:-80} \
    -v || {
    echo "❌ Tests failed or coverage below threshold"
    exit 1
}

echo "✅ Tests passed with coverage >= ${COVERAGE_THRESHOLD}%"
