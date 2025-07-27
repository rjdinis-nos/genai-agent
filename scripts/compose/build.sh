#!/bin/bash

# Docker Compose Build script for FastAPI File Downloader & PDF Summarizer
# This script builds the Docker image using Docker Compose

set -e  # Exit on any error

# Configuration
IMAGE_TAG="${1:-latest}"
COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"

echo "🐳 Building Docker image using Docker Compose"
echo "=============================================="

# Check if Docker and Docker Compose are running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Build the image
echo "📦 Building Docker image with tag: ${IMAGE_TAG}..."
# Change to project root and use absolute path for compose file
PROJECT_ROOT="$(dirname "$0")/../.."
COMPOSE_FILE_ABS="$(dirname "$0")/docker-compose.yml"
cd "$PROJECT_ROOT"
docker compose -f "$COMPOSE_FILE_ABS" build --build-arg IMAGE_TAG="${IMAGE_TAG}"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    
    # Show image details
    echo ""
    echo "📋 Image details:"
    docker images genai-agent --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    echo ""
    echo "🚀 To run the application, use:"
    echo "   $(dirname "$0")/run.sh"
    echo ""
    echo "🌐 To deploy for production, use:"
    echo "   $(dirname "$0")/deploy.sh"
else
    echo "❌ Docker image build failed!"
    exit 1
fi
