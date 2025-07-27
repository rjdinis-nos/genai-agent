#!/bin/bash

# Cleanup script for FastAPI File Downloader & PDF Summarizer
# This script cleans up Docker containers, images, and volumes

set -e  # Exit on any error

# Configuration
IMAGE_NAME="fastapi-file-downloader"
CONTAINER_NAME_DEV="fastapi-app"
CONTAINER_NAME_PROD="fastapi-app-prod"
NETWORK_NAME="fastapi-network"
VOLUME_NAME="fastapi-downloads"

echo "🧹 Cleaning up Docker resources"
echo "================================"

# Function to stop and remove container
cleanup_container() {
    local container_name=$1
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "🛑 Stopping and removing container: ${container_name}"
        docker stop "${container_name}" > /dev/null 2>&1 || true
        docker rm "${container_name}" > /dev/null 2>&1 || true
        echo "✅ Container ${container_name} removed"
    else
        echo "ℹ️  Container ${container_name} not found"
    fi
}

# Stop and remove containers
cleanup_container "${CONTAINER_NAME_DEV}"
cleanup_container "${CONTAINER_NAME_PROD}"

# Remove Docker images
echo ""
echo "🗑️  Removing Docker images..."
if docker images "${IMAGE_NAME}" --format '{{.Repository}}:{{.Tag}}' | grep -q "${IMAGE_NAME}"; then
    docker images "${IMAGE_NAME}" --format '{{.Repository}}:{{.Tag}}' | xargs docker rmi || true
    echo "✅ Docker images removed"
else
    echo "ℹ️  No Docker images found for ${IMAGE_NAME}"
fi

# Remove Docker network
echo ""
echo "🌐 Removing Docker network..."
if docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
    docker network rm "${NETWORK_NAME}" > /dev/null 2>&1 || true
    echo "✅ Docker network ${NETWORK_NAME} removed"
else
    echo "ℹ️  Docker network ${NETWORK_NAME} not found"
fi

# Ask about volume removal
echo ""
echo "💾 Docker volume cleanup:"
if docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    read -p "Do you want to remove the persistent volume '${VOLUME_NAME}'? This will delete all downloaded files. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume rm "${VOLUME_NAME}" > /dev/null 2>&1 || true
        echo "✅ Docker volume ${VOLUME_NAME} removed"
    else
        echo "ℹ️  Docker volume ${VOLUME_NAME} preserved"
    fi
else
    echo "ℹ️  Docker volume ${VOLUME_NAME} not found"
fi

# Clean up dangling images and containers
echo ""
echo "🧽 Cleaning up dangling Docker resources..."
docker system prune -f > /dev/null 2>&1 || true
echo "✅ Dangling resources cleaned up"

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📋 To rebuild and redeploy:"
echo "   ./scripts/build.sh"
echo "   ./scripts/run.sh     # For development"
echo "   ./scripts/deploy.sh  # For production"
