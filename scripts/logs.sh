#!/bin/bash

# Logs script for FastAPI File Downloader & PDF Summarizer
# This script helps view and manage container logs

set -e  # Exit on any error

# Configuration
CONTAINER_NAME_DEV="fastapi-app"
CONTAINER_NAME_PROD="fastapi-app-prod"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [CONTAINER_TYPE]"
    echo ""
    echo "CONTAINER_TYPE:"
    echo "  dev     Show logs for development container (default)"
    echo "  prod    Show logs for production container"
    echo ""
    echo "OPTIONS:"
    echo "  -f, --follow    Follow log output"
    echo "  -t, --tail N    Show last N lines (default: 50)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show last 50 lines of dev container"
    echo "  $0 -f                 # Follow dev container logs"
    echo "  $0 -t 100 prod        # Show last 100 lines of prod container"
    echo "  $0 --follow prod      # Follow prod container logs"
}

# Default values
FOLLOW=false
TAIL_LINES=50
CONTAINER_TYPE="dev"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -t|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        dev|prod)
            CONTAINER_TYPE="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set container name based on type
if [ "$CONTAINER_TYPE" = "prod" ]; then
    CONTAINER_NAME="$CONTAINER_NAME_PROD"
else
    CONTAINER_NAME="$CONTAINER_NAME_DEV"
fi

echo "📋 Viewing logs for ${CONTAINER_TYPE} container: ${CONTAINER_NAME}"
echo "================================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container ${CONTAINER_NAME} not found."
    echo ""
    echo "Available containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    exit 1
fi

# Show container status
echo "Container status:"
docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Build docker logs command
DOCKER_CMD="docker logs"

if [ "$FOLLOW" = true ]; then
    DOCKER_CMD="$DOCKER_CMD --follow"
else
    DOCKER_CMD="$DOCKER_CMD --tail $TAIL_LINES"
fi

DOCKER_CMD="$DOCKER_CMD $CONTAINER_NAME"

# Show logs
echo "📄 Container logs:"
echo "=================="
if [ "$FOLLOW" = true ]; then
    echo "Following logs (Press Ctrl+C to stop)..."
    echo ""
fi

eval $DOCKER_CMD
