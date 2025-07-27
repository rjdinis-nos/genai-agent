#!/bin/bash

# Build script for GenAI Agent
# This script builds the Docker image for the application

set -e  # Exit on any error

# Configuration
IMAGE_NAME="genai-agent"
IMAGE_TAG="${1:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "🐳 Building Docker image: ${FULL_IMAGE_NAME}"
echo "================================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t "${FULL_IMAGE_NAME}" .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully: ${FULL_IMAGE_NAME}"
    
    # Show image details
    echo ""
    echo "📋 Image details:"
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    echo ""
    echo "🚀 To run the container, use:"
    echo "   ./scripts/run.sh"
    echo ""
    echo "🌐 To deploy the container, use:"
    echo "   ./scripts/deploy.sh"
else
    echo "❌ Docker image build failed!"
    exit 1
fi
