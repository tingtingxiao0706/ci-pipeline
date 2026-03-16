#!/bin/sh
# Stop on errors
set -e

# Load environment variables
if [ -f ".env" ]; then
    . .env
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-dev}"

echo "========================================="
echo "Deploying to ${ENVIRONMENT} environment"
echo "========================================="

# Validate environment
valid_envs=("dev" "staging" "prod")
if ! printf '%s\n' "${valid_envs[@]}" | grep -qx "${ENVIRONMENT}"; then
    echo "❌ Invalid environment: ${ENVIRONMENT}. Must be one of: ${valid_envs[*]}"
    exit 1
fi

# Check for deployment manifest
cd "$PROJECT_ROOT"
if [ ! -f "deployments/${ENVIRONMENT}.yml" ]; then
    echo "❌ Deployment manifest not found: deployments/${ENVIRONMENT}.yml"
    exit 1
fi

# Read deployment configuration
SERVER=$(grep -E "^server:" "deployments/${ENVIRONMENT}.yml" | cut -d' ' -f2)
DEPLOY_DIR=$(grep -E "^deploy_dir:" "deployments/${ENVIRONMENT}.yml" | cut -d' ' -f2)

if [ -z "$SERVER" ] || [ -z "$DEPLOY_DIR" ]; then
    echo "❌ Invalid deployment manifest format"
    exit 1
fi

# Build and push Docker image if needed
if [ "$ENVIRONMENT" != "dev" ] || [ "$FORCE_DOCKER" = "true" ]; then
    echo "Building Docker image..."
    docker build -t "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${ENVIRONMENT}-${IMAGE_TAG:-latest}" .

    echo "Pushing Docker image..."
    docker push "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${ENVIRONMENT}-${IMAGE_TAG:-latest}"
fi

# Deploy to server
echo "Deploying to ${SERVER}:${DEPLOY_DIR}..."

ssh -i "${SSH_PRIVATE_KEY}" "${SERVER}" bash -s << EOF
set -e
DEPLOY_DIR="${DEPLOY_DIR}"
ENV_FILE="${ENV_FILE:-.env}"
IMAGE="${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${ENVIRONMENT}-${IMAGE_TAG:-latest}"
APP="${APP_NAME}"

echo "Preparing deployment directory..."
mkdir -p "\$DEPLOY_DIR"
cd "\$DEPLOY_DIR"

# Pull latest image
if [ -f "docker-compose.yml" ]; then
    docker-compose pull
    docker-compose up -d
else
    docker pull "\$IMAGE"
    docker stop "\$APP" 2>/dev/null || true
    docker rm "\$APP" 2>/dev/null || true
    docker run -d \
        --name "\$APP" \
        --restart unless-stopped \
        --env-file "\$ENV_FILE" \
        -p 8080:8080 \
        "\$IMAGE"
fi

echo "✅ Deployment completed!"
EOF

echo "========================================="
echo "✅ Deployment successful!"
echo "========================================="
