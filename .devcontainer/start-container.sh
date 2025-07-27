#!/bin/bash

# Script to start the devcontainer using Docker Compose
# Usage: ./start-container.sh [options]
# Options:
#   --build     Force rebuild the container images
#   -h, --help  Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"
BUILD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Start the devcontainer using Docker Compose"
            echo ""
            echo "Options:"
            echo "  --build     Force rebuild the container images"
            echo "  -h, --help  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Start existing containers"
            echo "  $0 --build      # Rebuild and start containers"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 Starting DevContainer Service: $SERVICE_NAME"
echo "============================================="

# Check if service is already running
if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "⚠️ Service '$SERVICE_NAME' is already running."
    echo "   Use './.devcontainer/cli.sh status' to see status"
    exit 0
fi

# Start the service
if [ "$BUILD" = true ]; then
    echo "🔨 Building and starting devcontainer with Docker Compose..."
    docker compose -f "$COMPOSE_FILE" up -d --build
else
    echo "🐳 Starting devcontainer with Docker Compose..."
    docker compose -f "$COMPOSE_FILE" up -d
fi

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Verify the service is running
if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "✅ DevContainer started successfully!"
    echo ""
    echo "📋 Service Status:"
    echo "   - Service: $SERVICE_NAME"
    echo "   - Status: Running"
    echo "   - Port forwarding: localhost:8000 -> container:8000"
    echo ""
    echo "🔧 Next steps:"
    echo "   - Enter container: ./.devcontainer/cli.sh enter"
    echo "   - View logs: ./.devcontainer/cli.sh logs"
    echo "   - Stop service: ./.devcontainer/cli.sh stop"
    echo ""
    echo "🚀 To start the FastAPI server inside the container:"
    echo "   ./.devcontainer/cli.sh fastapi"
else
    echo "❌ Failed to start the devcontainer service."
    echo "   Check logs with: ./.devcontainer/cli.sh logs"
    exit 1
fi
