#!/bin/bash

# Run script for GenAI Agent
# This script runs the Docker container locally for development/testing

set -e  # Exit on any error

# Configuration
IMAGE_NAME="genai-agent"
IMAGE_TAG="${1:-latest}"
CONTAINER_NAME="fastapi-app"
HOST_PORT="${2:-8000}"
CONTAINER_PORT="8000"

echo "🚀 Running Docker container: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "================================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if image exists
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    echo "❌ Error: Docker image ${IMAGE_NAME}:${IMAGE_TAG} not found."
    echo "Please build the image first using: ./scripts/build.sh"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 Stopping existing container..."
    docker stop "${CONTAINER_NAME}" > /dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" > /dev/null 2>&1 || true
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Please create one with your GEMINI_API_KEY"
    echo "Example .env content:"
    echo "GEMINI_API_KEY=your_api_key_here"
    echo ""
fi

# Run the container
echo "🐳 Starting container on port ${HOST_PORT}..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    --env-file .env \
    -v "$(pwd)/downloads:/app/downloads" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

# Wait a moment for container to start
sleep 3

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ Container started successfully!"
    echo ""
    echo "🌐 Application is available at:"
    echo "   • API: http://localhost:${HOST_PORT}"
    echo "   • Docs: http://localhost:${HOST_PORT}/docs"
    echo "   • ReDoc: http://localhost:${HOST_PORT}/redoc"
    echo ""
    echo "📋 Container management:"
    echo "   • View logs: docker logs ${CONTAINER_NAME}"
    echo "   • Stop container: docker stop ${CONTAINER_NAME}"
    echo "   • Remove container: docker rm ${CONTAINER_NAME}"
    echo ""
    echo "📊 Container status:"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ Failed to start container. Check logs with:"
    echo "   docker logs ${CONTAINER_NAME}"
    exit 1
fi
