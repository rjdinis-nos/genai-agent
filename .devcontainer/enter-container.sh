#!/bin/bash

# Script to enter the running devcontainer
# Usage: ./enter-container.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"

echo "🐳 Entering DevContainer Service: $SERVICE_NAME"
echo "============================================="

# Check if service is running
if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "❌ Service '$SERVICE_NAME' is not running."
    echo "   Start it first with: ./.devcontainer/cli.sh start"
    exit 1
fi

echo "✅ Service is running. Opening bash shell..."
echo "   Working directory: /workspaces/genai-baseline-agent"
echo "   Type 'exit' to leave the container"
echo ""

# Enter the container with bash using Docker Compose
docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" bash
