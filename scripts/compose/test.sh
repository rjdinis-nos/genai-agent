#!/bin/bash

# Docker Compose Test script for FastAPI File Downloader & PDF Summarizer
# This script runs the test suite using Docker Compose

set -e  # Exit on any error

# Configuration
COMPOSE_FILE="$(dirname "$0")/docker-compose.test.yml"

echo "🧪 Running tests with Docker Compose"
echo "===================================="

# Check if Docker and Docker Compose are running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Build the main image first if it doesn't exist
if ! docker image inspect genai-agent:latest > /dev/null 2>&1; then
    echo "📦 Main image not found. Building..."
    BUILD_SCRIPT="$(dirname "$0")/build.sh"
    if [ ! -x "$BUILD_SCRIPT" ]; then
        echo "❌ Error: Build script not found or not executable at $BUILD_SCRIPT"
        exit 1
    fi
    "$BUILD_SCRIPT"
fi

echo "🧪 Running tests in container..."
echo ""

# Run tests using Docker Compose
if docker compose -f "$(realpath "${COMPOSE_FILE}")" --profile test run --rm fastapi-test; then
    echo ""
    echo "✅ All tests passed in container!"
    
    echo ""
    echo "🎉 Container testing completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   • Deploy with: $(dirname "$0")/deploy.sh"
    echo "   • Run locally: $(dirname "$0")/run.sh"
else
    echo ""
    echo "❌ Tests failed in container!"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   • Check test logs above for specific failures"
    echo "   • Run tests locally: uv run pytest -v"
    echo "   • Verify dependencies: uv sync --dev"
    
    exit 1
fi

# Clean up test containers
echo "🧹 Cleaning up test containers..."
docker compose -f "$(realpath "${COMPOSE_FILE}")" --profile test down > /dev/null 2>&1 || true
