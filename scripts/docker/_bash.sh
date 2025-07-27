#!/bin/bash

# Simple Bash Entry script for FastAPI containers
# Quick access to bash shell in running containers

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(realpath "$(dirname "$0")")"

# Default values
ENVIRONMENT="dev"
USER="root"

# Function to show usage
show_usage() {
    echo "Usage: $0 [ENVIRONMENT] [OPTIONS]"
    echo ""
    echo "Quick bash access to FastAPI containers"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Enter development container (default)"
    echo "  prod    Enter production container"
    echo "  test    Enter test container"
    echo ""
    echo "OPTIONS:"
    echo "  -u, --user USER    User to run as (default: root)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Enter dev container as root"
    echo "  $0 prod            # Enter prod container as root"
    echo "  $0 -u app          # Enter dev container as app user"
    echo "  $0 prod -u app     # Enter prod container as app user"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod|test)
            ENVIRONMENT="$1"
            shift
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Get compose file for environment
get_compose_file() {
    case $ENVIRONMENT in
        dev)
            echo "$SCRIPT_DIR/../.docker/docker-compose.dev.yml"
            ;;
        prod)
            echo "$SCRIPT_DIR/../.docker/docker-compose.prod.yml"
            ;;
        test)
            echo "$SCRIPT_DIR/../.docker/docker-compose.test.yml"
            ;;
        *)
            echo "$SCRIPT_DIR/../.docker/docker-compose.dev.yml"
            ;;
    esac
}

echo "🐚 Entering $ENVIRONMENT container with bash"
echo "==========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Navigate to project root
cd "$SCRIPT_DIR/.."

# Get compose file
COMPOSE_FILE=$(get_compose_file)

# Check if container is running
if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "fastapi-app"; then
    echo "❌ Error: No running containers found for $ENVIRONMENT environment"
    echo ""
    echo "💡 Start the container first:"
    case $ENVIRONMENT in
        dev)
            echo "   $SCRIPT_DIR/run.sh"
            ;;
        prod)
            echo "   $SCRIPT_DIR/deploy.sh"
            ;;
        test)
            echo "   $SCRIPT_DIR/test.sh"
            ;;
    esac
    exit 1
fi

echo "🚪 Connecting to container as user: $USER"
echo "   • Type 'exit' to leave the container"
echo ""

# Enter container with bash
docker compose -f "$COMPOSE_FILE" exec --user "$USER" fastapi-app bash
