#!/bin/bash

# Docker Compose Stop script for FastAPI File Downloader & PDF Summarizer
# This script stops running containers using Docker Compose

set -e  # Exit on any error

# Configuration
DEV_COMPOSE_FILE=".docker/docker-compose.yml"
PROD_COMPOSE_FILE=".docker/docker-compose.prod.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [ENVIRONMENT]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Stop development containers (default)"
    echo "  prod    Stop production containers"
    echo "  all     Stop all containers"
    echo ""
    echo "Examples:"
    echo "  $0          # Stop dev containers"
    echo "  $0 prod     # Stop prod containers"
    echo "  $0 all      # Stop all containers"
}

# Default environment
ENVIRONMENT="${1:-dev}"

echo "🛑 Stopping FastAPI containers"
echo "=============================="

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

case $ENVIRONMENT in
    dev)
        echo "🔧 Stopping development containers..."
        docker compose -f "${DEV_COMPOSE_FILE}" down
        ;;
    prod)
        echo "🏭 Stopping production containers..."
        docker compose -f "${PROD_COMPOSE_FILE}" down
        ;;
    all)
        echo "🔧 Stopping development containers..."
        docker compose -f "${DEV_COMPOSE_FILE}" down > /dev/null 2>&1 || true
        echo "🏭 Stopping production containers..."
        docker compose -f "${PROD_COMPOSE_FILE}" down > /dev/null 2>&1 || true
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        echo "❌ Unknown environment: $ENVIRONMENT"
        show_usage
        exit 1
        ;;
esac

echo "✅ Containers stopped successfully!"
echo ""
echo "📋 To start containers again:"
echo "   • Development: .docker/run.sh"
echo "   • Production: .docker/deploy.sh"
