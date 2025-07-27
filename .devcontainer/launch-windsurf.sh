#!/bin/bash

# Script to launch Windsurf in devcontainer on WSL Arch Linux
# Usage: ./launch-windsurf.sh

set -e

echo "🚀 Launching Windsurf in DevContainer (WSL Arch Linux)"
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

# Stop any existing containers
echo "🧹 Cleaning up existing containers..."
docker compose -f .devcontainer/docker-compose.yml down 2>/dev/null || true

# Build and start the devcontainer using Docker Compose
echo "🔨 Building and starting devcontainer with Docker Compose..."
docker compose -f .devcontainer/docker-compose.yml up -d --build

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Check if Windsurf is available
if command -v windsurf >/dev/null 2>&1; then
    echo "🌪️ Opening Windsurf with devcontainer..."
    # Open Windsurf with the devcontainer
    windsurf --folder-uri "vscode-remote://dev-container+$(echo -n "$(pwd)/.devcontainer" | base64 -w 0)/workspaces/genai-baseline-agent"
else
    echo "⚠️ Windsurf command not found. Please ensure Windsurf is installed."
    echo "   You can download it from: https://codeium.com/windsurf"
    echo ""
    echo "📋 Alternative: Open VS Code with Dev Containers extension:"
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
