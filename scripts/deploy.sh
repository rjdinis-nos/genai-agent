#!/bin/bash

# Deploy script for FastAPI File Downloader & PDF Summarizer
# This script deploys the Docker container to production environments

set -e  # Exit on any error

# Configuration
IMAGE_NAME="fastapi-file-downloader"
IMAGE_TAG="${1:-latest}"
CONTAINER_NAME="fastapi-app-prod"
HOST_PORT="${2:-80}"
CONTAINER_PORT="8000"
NETWORK_NAME="fastapi-network"

echo "🚀 Deploying Docker container: ${IMAGE_NAME}:${IMAGE_TAG}"
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

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. This is required for production deployment."
    echo "Please create .env file with your GEMINI_API_KEY"
    exit 1
fi

# Create Docker network if it doesn't exist
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
    echo "🌐 Creating Docker network: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}"
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 Stopping existing production container..."
    docker stop "${CONTAINER_NAME}" > /dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" > /dev/null 2>&1 || true
fi

# Create persistent volume for downloads
VOLUME_NAME="fastapi-downloads"
if ! docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    echo "💾 Creating persistent volume: ${VOLUME_NAME}"
    docker volume create "${VOLUME_NAME}"
fi

# Deploy the container
echo "🐳 Deploying production container on port ${HOST_PORT}..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    --network "${NETWORK_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    --env-file .env \
    -v "${VOLUME_NAME}:/app/downloads" \
    --restart unless-stopped \
    --memory="512m" \
    --cpus="0.5" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 5

# Health check
echo "🏥 Performing health check..."
for i in {1..10}; do
    if curl -f "http://localhost:${HOST_PORT}/docs" > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Health check failed after 10 attempts"
        echo "Container logs:"
        docker logs "${CONTAINER_NAME}" --tail 20
        exit 1
    fi
    echo "⏳ Attempt $i/10 - waiting for application to start..."
    sleep 3
done

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo "🎉 Production deployment successful!"
    echo ""
    echo "🌐 Application is available at:"
    echo "   • API: http://localhost:${HOST_PORT}"
    echo "   • Docs: http://localhost:${HOST_PORT}/docs"
    echo "   • ReDoc: http://localhost:${HOST_PORT}/redoc"
    echo ""
    echo "📋 Production container management:"
    echo "   • View logs: docker logs ${CONTAINER_NAME}"
    echo "   • Follow logs: docker logs -f ${CONTAINER_NAME}"
    echo "   • Stop container: docker stop ${CONTAINER_NAME}"
    echo "   • Restart container: docker restart ${CONTAINER_NAME}"
    echo ""
    echo "📊 Container status:"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}"
    echo ""
    echo "💾 Persistent storage:"
    echo "   • Volume: ${VOLUME_NAME}"
    echo "   • Network: ${NETWORK_NAME}"
else
    echo "❌ Deployment failed. Check logs with:"
    echo "   docker logs ${CONTAINER_NAME}"
    exit 1
fi
