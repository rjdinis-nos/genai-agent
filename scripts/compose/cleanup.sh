#!/bin/bash

# Docker Compose Cleanup script for FastAPI File Downloader & PDF Summarizer
# This script cleans up Docker resources using Docker Compose

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(dirname "$0")"
DEV_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROD_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"
TEST_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.test.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --containers    Remove containers only"
    echo "  --images        Remove images only"
    echo "  --volumes       Remove volumes only"
    echo "  --networks      Remove networks only"
    echo "  --all           Remove everything (default)"
    echo "  --force         Skip confirmation prompts"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive cleanup of everything"
    echo "  $0 --containers       # Remove only containers"
    echo "  $0 --all --force      # Remove everything without prompts"
}

# Default values
CLEANUP_CONTAINERS=false
CLEANUP_IMAGES=false
CLEANUP_VOLUMES=false
CLEANUP_NETWORKS=false
CLEANUP_ALL=true
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --containers)
            CLEANUP_CONTAINERS=true
            CLEANUP_ALL=false
            shift
            ;;
        --images)
            CLEANUP_IMAGES=true
            CLEANUP_ALL=false
            shift
            ;;
        --volumes)
            CLEANUP_VOLUMES=true
            CLEANUP_ALL=false
            shift
            ;;
        --networks)
            CLEANUP_NETWORKS=true
            CLEANUP_ALL=false
            shift
            ;;
        --all)
            CLEANUP_ALL=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If --all is true, enable all cleanup options
if [ "$CLEANUP_ALL" = true ]; then
    CLEANUP_CONTAINERS=true
    CLEANUP_IMAGES=true
    CLEANUP_VOLUMES=true
    CLEANUP_NETWORKS=true
fi

echo "🧹 Docker Compose Cleanup for FastAPI Application"
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

# Navigate to project root
cd "$(dirname "$0")/.."

# Function to ask for confirmation
confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Stop and remove containers
if [ "$CLEANUP_CONTAINERS" = true ]; then
    echo "🛑 Stopping and removing containers..."
    
    if confirm "Stop and remove all FastAPI containers?"; then
        docker compose -f "${DEV_COMPOSE_FILE}" down > /dev/null 2>&1 || true
        docker compose -f "${PROD_COMPOSE_FILE}" down > /dev/null 2>&1 || true
        docker compose -f "${TEST_COMPOSE_FILE}" --profile test down > /dev/null 2>&1 || true
        echo "✅ Containers removed"
    else
        echo "⏭️  Skipping container cleanup"
    fi
fi

# Remove images
if [ "$CLEANUP_IMAGES" = true ]; then
    echo "🖼️  Removing images..."
    
    if confirm "Remove FastAPI Docker images?"; then
        # Remove project-specific images
        docker rmi genai-agent:latest > /dev/null 2>&1 || true
        docker rmi $(docker images -q --filter "reference=*fastapi*") > /dev/null 2>&1 || true
        
        # Remove dangling images
        docker image prune -f > /dev/null 2>&1 || true
        echo "✅ Images removed"
    else
        echo "⏭️  Skipping image cleanup"
    fi
fi

# Remove volumes
if [ "$CLEANUP_VOLUMES" = true ]; then
    echo "💾 Removing volumes..."
    
    if confirm "Remove FastAPI Docker volumes? (This will delete persistent data)"; then
        docker volume rm fastapi-downloads > /dev/null 2>&1 || true
        docker volume prune -f > /dev/null 2>&1 || true
        echo "✅ Volumes removed"
    else
        echo "⏭️  Skipping volume cleanup"
    fi
fi

# Remove networks
if [ "$CLEANUP_NETWORKS" = true ]; then
    echo "🌐 Removing networks..."
    
    if confirm "Remove FastAPI Docker networks?"; then
        docker network rm fastapi-network > /dev/null 2>&1 || true
        docker network prune -f > /dev/null 2>&1 || true
        echo "✅ Networks removed"
    else
        echo "⏭️  Skipping network cleanup"
    fi
fi

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📋 To rebuild and start:"
echo "   • Build: $(dirname "$0")/build.sh"
echo "   • Run dev: $(dirname "$0")/run.sh"
echo "   • Deploy prod: $(dirname "$0")/deploy.sh"
