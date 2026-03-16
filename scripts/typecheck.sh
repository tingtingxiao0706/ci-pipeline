# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo "Running static type checking..."
echo "----------------------------------------"

# Run mypy
mypy app/ tests/ --ignore-missing-imports --pretty || {
    echo "❌ Type checking failed"
    exit 1
}

echo "✅ Type checking passed!"
