#!/bin/bash

# Docker Compose Run script for FastAPI File Downloader & PDF Summarizer
# This script runs the application using Docker Compose for development

set -e  # Exit on any error

# Configuration
COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"
HOST_PORT="${1:-8000}"

echo "🚀 Running FastAPI application with Docker Compose"
echo "================================================="

# Check if Docker and Docker Compose are running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Please create one with your GEMINI_API_KEY"
    echo "Example .env content:"
    echo "GEMINI_API_KEY=your_api_key_here"
    echo ""
fi

# Navigate to project root
cd "$(dirname "$0")/../.."

# Update port in compose file if different from default
if [ "$HOST_PORT" != "8000" ]; then
    echo "🔧 Using custom port: $HOST_PORT"
    export HOST_PORT
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose -f "scripts/compose/docker-compose.yml" down > /dev/null 2>&1 || true

# Start the application
echo "🐳 Starting application containers..."
COMPOSE_FILE_ABS="scripts/compose/docker-compose.yml"
if [ "$HOST_PORT" != "8000" ]; then
    # Override port mapping
    docker compose -f "$COMPOSE_FILE_ABS" up -d --build
    docker compose -f "$COMPOSE_FILE_ABS" exec fastapi-app sh -c "sed -i 's/8000:8000/${HOST_PORT}:8000/' /etc/hosts" || true
else
    docker compose -f "$COMPOSE_FILE_ABS" up -d --build
fi

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 5

# Check if container is running
if docker compose -f "$(realpath "${COMPOSE_FILE}")" ps --services --filter "status=running" | grep -q "fastapi-app"; then
    echo "✅ Application started successfully!"
    echo ""
    echo "🌐 Application is available at:"
    echo "   • API: http://localhost:${HOST_PORT}"
    echo "   • Docs: http://localhost:${HOST_PORT}/docs"
    echo "   • ReDoc: http://localhost:${HOST_PORT}/redoc"
    echo ""
    echo "📋 Container management:"
    echo "   • View logs: $(dirname "$0")/logs.sh"
    echo "   • Stop application: $(dirname "$0")/stop.sh"
    echo "   • Restart application: docker compose -f ${COMPOSE_FILE} restart"
    echo ""
    echo "📊 Container status:"
    docker compose -f "$(realpath "${COMPOSE_FILE}")" ps
else
    echo "❌ Failed to start application. Check logs with:"
    echo "   $(dirname "$0")/logs.sh"
    exit 1
fi
