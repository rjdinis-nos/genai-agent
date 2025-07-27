#!/bin/bash

# Docker Compose Logs script for FastAPI File Downloader & PDF Summarizer
# This script helps view and manage container logs using Docker Compose

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
DEV_COMPOSE_FILE="$SCRIPT_DIR/../../.docker/docker-compose.dev.yml"
PROD_COMPOSE_FILE="$SCRIPT_DIR/../../.docker/docker-compose.prod.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [ENVIRONMENT]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Show logs for development containers (default)"
    echo "  prod    Show logs for production containers"
    echo ""
    echo "OPTIONS:"
    echo "  -f, --follow    Follow log output"
    echo "  -t, --tail N    Show last N lines (default: 50)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show last 50 lines of dev containers"
    echo "  $0 -f                 # Follow dev container logs"
    echo "  $0 -t 100 prod        # Show last 100 lines of prod containers"
    echo "  $0 --follow prod      # Follow prod container logs"
}

# Default values
FOLLOW=false
TAIL_LINES=50
ENVIRONMENT="dev"

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
            ENVIRONMENT="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set compose file based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    COMPOSE_FILE="$PROD_COMPOSE_FILE"
    SERVICE_NAME="fastapi-app"
else
    COMPOSE_FILE="$DEV_COMPOSE_FILE"
    SERVICE_NAME="fastapi-app"
fi

echo "📋 Viewing logs for ${ENVIRONMENT} environment"
echo "============================================="

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
cd "$SCRIPT_DIR/.."

# Check if containers exist
if ! docker compose -f "$COMPOSE_FILE" ps --services | grep -q "${SERVICE_NAME}"; then
    echo "❌ Error: No containers found for ${ENVIRONMENT} environment."
    echo ""
    echo "Available services:"
    docker compose -f "$COMPOSE_FILE" ps --services || echo "No services found"
    exit 1
fi

# Show container status
echo "Container status:"
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Build docker compose logs command
DOCKER_CMD="docker compose -f ${COMPOSE_FILE} logs"

if [ "$FOLLOW" = true ]; then
    DOCKER_CMD="$DOCKER_CMD --follow"
else
    DOCKER_CMD="$DOCKER_CMD --tail $TAIL_LINES"
fi

DOCKER_CMD="$DOCKER_CMD $SERVICE_NAME"

# Show logs
echo "📄 Container logs:"
echo "=================="
if [ "$FOLLOW" = true ]; then
    echo "Following logs (Press Ctrl+C to stop)..."
    echo ""
fi

eval $DOCKER_CMD
