# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo "Running code quality checks..."
echo "----------------------------------------"

# Check Python syntax
echo "Checking Python syntax..."
python -m py_compile app/main.py || exit 1

# Run formatter check (black)
echo "Checking code formatting..."
black --check app/ tests/ || {
    echo "❌ Code formatting issues found. Run: black app/ tests/"
    exit 1
}

# Run linter (ruff)
echo "Running linter..."
ruff check app/ tests/ || {
    echo "❌ Linting errors found"
    exit 1
}

echo "✅ Code quality checks passed!"
