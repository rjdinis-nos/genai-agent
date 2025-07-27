#!/bin/bash

# Script to launch VS Code in devcontainer on WSL Arch Linux
# Usage: ./launch-vscode.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"

echo "🚀 Launching VS Code in DevContainer (WSL Arch Linux)"
echo "=================================================="

# Check if we're in WSL
if ! grep -q microsoft /proc/version 2>/dev/null; then
    echo "❌ This script is designed to run in WSL. Please run from WSL Arch Linux."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop or Docker daemon."
    echo "   For WSL, you can start Docker Desktop on Windows or install Docker in WSL."
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ] || [ ! -d ".devcontainer" ]; then
    echo "❌ Please run this script from the genai-baseline-agent project root directory."
    exit 1
fi

# Check if service is already running
if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "⚠️ Service '$SERVICE_NAME' is already running."
else
    echo "🔨 Building and starting devcontainer with Docker Compose..."
    docker compose -f .devcontainer/docker-compose.yml up -d --build
fi

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Check if VS Code is available
if command -v code >/dev/null 2>&1; then
    echo "💻 Opening VS Code with devcontainer..."
    # Open VS Code with the devcontainer
    code --folder-uri "vscode-remote://dev-container+$(echo -n "$(pwd)/.devcontainer" | base64 -w 0)/workspaces/genai-baseline-agent"
else
    echo "⚠️ VS Code command not found. Please ensure VS Code is installed."
    echo "   You can download it from: https://code.visualstudio.com/"
    echo ""
    echo "📋 Alternative: Manual setup:"
    echo "   1. Install the 'Dev Containers' extension in VS Code"
    echo "   2. Open this project folder in VS Code"
    echo "   3. Press Ctrl+Shift+P and select 'Dev Containers: Reopen in Container'"
fi

echo ""
echo "✅ DevContainer is running!"
echo "   Service: genai-baseline-agent-app-1 (Docker Compose)"
echo "   Port forwarding: localhost:8000 -> container:8000"
echo ""
echo "🔧 Useful commands:"
echo "   - Enter container: ./.devcontainer/cli.sh enter"
echo "   - View logs: ./.devcontainer/cli.sh logs"
echo "   - Stop containers: ./.devcontainer/cli.sh stop"
echo "   - Restart containers: ./.devcontainer/cli.sh restart"
echo ""
echo "🚀 To start the FastAPI server inside the container:"
echo "   ./.devcontainer/cli.sh fastapi"
