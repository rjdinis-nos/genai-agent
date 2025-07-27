#!/bin/bash

# Script to stop the devcontainer
# Usage: ./stop-container.sh [options]
# Options:
#   -r, --remove    Also remove the container after stopping
#   -f, --force     Force stop the container (kill instead of graceful stop)
#   -h, --help      Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"
REMOVE=false
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--remove)
            REMOVE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Stop the devcontainer"
            echo ""
            echo "Options:"
            echo "  -r, --remove    Also remove the container after stopping"
            echo "  -f, --force     Force stop the container (kill instead of graceful stop)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Gracefully stop the container"
            echo "  $0 -r           # Stop and remove the container"
            echo "  $0 -f           # Force stop the container"
            echo "  $0 -rf          # Force stop and remove the container"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "🛑 Stopping DevContainer Service: $SERVICE_NAME"
echo "============================================="

# Check if service exists
if ! docker compose -f "$COMPOSE_FILE" ps --services | grep -q "^$SERVICE_NAME$"; then
    echo "❌ Service '$SERVICE_NAME' does not exist."
    exit 1
fi

# Check if service is running
if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "⚠️ Service '$SERVICE_NAME' is already stopped."
    if [ "$REMOVE" = true ]; then
        echo "🗑️ Removing stopped containers..."
        docker compose -f "$COMPOSE_FILE" down
        echo "✅ Containers removed successfully."
    fi
    exit 0
fi

# Stop the service using Docker Compose
if [ "$FORCE" = true ]; then
    echo "⚡ Force stopping service..."
    docker compose -f "$COMPOSE_FILE" kill "$SERVICE_NAME"
    echo "✅ Service force stopped."
else
    echo "🔄 Gracefully stopping service..."
    docker compose -f "$COMPOSE_FILE" stop "$SERVICE_NAME"
    echo "✅ Service stopped gracefully."
fi

# Remove containers if requested
if [ "$REMOVE" = true ]; then
    echo "🗑️ Removing containers..."
    docker compose -f "$COMPOSE_FILE" down
    echo "✅ Containers removed successfully."
fi

echo ""
echo "📋 Service Status Summary:"
echo "   - Service: $SERVICE_NAME"
echo "   - Status: Stopped"
if [ "$REMOVE" = true ]; then
    echo "   - Removed: Yes"
else
    echo "   - Removed: No (use -r flag to remove)"
fi
echo ""
echo "🚀 To restart the service, run:"
echo "   ./.devcontainer/cli.sh start"
