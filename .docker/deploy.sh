#!/bin/bash

# Docker Compose Deploy script for FastAPI File Downloader & PDF Summarizer
# This script deploys the application using Docker Compose for production

set -e  # Exit on any error

# Configuration
COMPOSE_FILE=".docker/docker-compose.prod.yml"
HOST_PORT="${1:-80}"

echo "🚀 Deploying FastAPI application with Docker Compose (Production)"
echo "================================================================"

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
    echo "❌ Error: .env file not found. This is required for production deployment."
    echo "Please create .env file with your GEMINI_API_KEY"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Update port in compose file if different from default
if [ "$HOST_PORT" != "80" ]; then
    echo "🔧 Using custom port: $HOST_PORT"
    export HOST_PORT
fi

# Stop any existing containers
echo "🛑 Stopping existing production containers..."
docker compose -f "${COMPOSE_FILE}" down > /dev/null 2>&1 || true

# Deploy the application
echo "🐳 Deploying production containers..."
if [ "$HOST_PORT" != "80" ]; then
    # Override port mapping
    sed "s/80:8000/${HOST_PORT}:8000/" "${COMPOSE_FILE}" | docker compose -f - up -d --build
else
    docker compose -f "${COMPOSE_FILE}" up -d --build
fi

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Health check
echo "🏥 Performing health check..."
for i in {1..10}; do
    if curl -f "http://localhost:${HOST_PORT}/docs" > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Health check failed after 10 attempts"
        echo "Container logs:"
        docker compose -f "${COMPOSE_FILE}" logs --tail 20
        exit 1
    fi
    echo "⏳ Attempt $i/10 - waiting for application to start..."
    sleep 3
done

# Check if container is running
if docker compose -f "${COMPOSE_FILE}" ps --services --filter "status=running" | grep -q "fastapi-app"; then
    echo ""
    echo "🎉 Production deployment successful!"
    echo ""
    echo "🌐 Application is available at:"
    echo "   • API: http://localhost:${HOST_PORT}"
    echo "   • Docs: http://localhost:${HOST_PORT}/docs"
    echo "   • ReDoc: http://localhost:${HOST_PORT}/redoc"
    echo ""
    echo "📋 Production container management:"
    echo "   • View logs: .docker/logs.sh prod"
    echo "   • Stop application: .docker/stop.sh prod"
    echo "   • Restart application: docker compose -f ${COMPOSE_FILE} restart"
    echo ""
    echo "📊 Container status:"
    docker compose -f "${COMPOSE_FILE}" ps
    echo ""
    echo "💾 Persistent storage:"
    echo "   • Volume: fastapi-downloads"
    echo "   • Network: fastapi-network"
else
    echo "❌ Deployment failed. Check logs with:"
    echo "   .docker/logs.sh prod"
    exit 1
fi
