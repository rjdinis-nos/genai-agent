#!/bin/bash

# Test script for FastAPI File Downloader & PDF Summarizer
# This script runs the test suite inside a Docker container

set -e  # Exit on any error

# Configuration
IMAGE_NAME="fastapi-file-downloader"
IMAGE_TAG="${1:-latest}"
CONTAINER_NAME="fastapi-test-$(date +%s)"

echo "🧪 Running tests in Docker container: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "================================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if image exists, if not build it
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    echo "📦 Docker image ${IMAGE_NAME}:${IMAGE_TAG} not found. Building..."
    ./scripts/build.sh "${IMAGE_TAG}"
fi

# Create a temporary Dockerfile for testing
cat > Dockerfile.test << 'EOF'
# Use the existing application image as base
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Copy test files
COPY tests/ ./tests/
COPY pytest.ini ./

# Install test dependencies (they should already be in dev-dependencies)
RUN uv sync --dev

# Set the default command to run tests
CMD ["uv", "run", "pytest", "-v", "--tb=short"]
EOF

echo "🔨 Building test image..."
docker build -f Dockerfile.test --build-arg BASE_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}" -t "${IMAGE_NAME}-test:${IMAGE_TAG}" .

# Clean up temporary Dockerfile
rm Dockerfile.test

echo "🧪 Running tests in container..."
echo ""

# Run tests in container
if docker run --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}-test:${IMAGE_TAG}"; then
    echo ""
    echo "✅ All tests passed in container!"
    
    # Clean up test image
    docker rmi "${IMAGE_NAME}-test:${IMAGE_TAG}" > /dev/null 2>&1 || true
    
    echo ""
    echo "🎉 Container testing completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   • Deploy with: ./scripts/deploy.sh"
    echo "   • Run locally: ./scripts/run.sh"
else
    echo ""
    echo "❌ Tests failed in container!"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   • Check test logs above for specific failures"
    echo "   • Run tests locally: uv run pytest -v"
    echo "   • Verify dependencies: uv sync --dev"
    
    # Clean up test image
    docker rmi "${IMAGE_NAME}-test:${IMAGE_TAG}" > /dev/null 2>&1 || true
    
    exit 1
fi
