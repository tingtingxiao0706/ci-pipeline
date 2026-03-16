# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo "Building application..."
echo "----------------------------------------"

# Clean previous builds
rm -rf "${BUILD_DIR:-build}" "${DIST_DIR:-dist}"
mkdir -p "${BUILD_DIR:-build}" "${DIST_DIR:-dist}"

# Build Python package
echo "Building Python package..."
python -m build --outdir "${DIST_DIR:-dist}" || {
    echo "❌ Build failed"
    exit 1
}

# Archive source
echo "Creating source archive..."
tar -czf "${DIST_DIR:-dist}/source.tar.gz" \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='coverage' \
    --exclude='.pytest_cache' \
    .

echo "✅ Build completed! Artifacts in ${DIST_DIR:-dist}/"
