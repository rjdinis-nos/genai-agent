#!/bin/bash

# Docker Compose Status script for FastAPI File Downloader & PDF Summarizer
# This script checks the status of running containers using Docker Compose

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
DEV_COMPOSE_FILE="$SCRIPT_DIR/../../.docker/docker-compose.dev.yml"
PROD_COMPOSE_FILE="$SCRIPT_DIR/../../.docker/docker-compose.prod.yml"
TEST_COMPOSE_FILE="$SCRIPT_DIR/../../.docker/docker-compose.test.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [ENVIRONMENT] [OPTIONS]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Check development containers (default)"
    echo "  prod    Check production containers"
    echo "  test    Check test containers"
    echo "  all     Check all containers"
    echo ""
    echo "OPTIONS:"
    echo "  -v, --verbose    Show detailed container information"
    echo "  -l, --logs       Show recent logs for running containers"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Check dev containers"
    echo "  $0 prod         # Check prod containers"
    echo "  $0 all -v       # Check all containers with details"
    echo "  $0 dev --logs   # Check dev containers and show logs"
}

# Function to check container status
check_container_status() {
    local compose_file="$1"
    local env_name="$2"
    
    if [ ! -f "$compose_file" ]; then
        echo "⚠️  Docker Compose file not found: $compose_file"
        return 1
    fi
    
    echo "📊 Checking $env_name containers..."
    echo "Compose file: $compose_file"
    echo ""
    
    # Get container status
    local containers
    containers=$(docker compose -f "$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "")
    
    if [ -z "$containers" ] || [ "$containers" = "NAME	STATUS	PORTS" ]; then
        echo "🔴 No containers running for $env_name environment"
        echo ""
        return 0
    fi
    
    echo "$containers"
    echo ""
    
    # Show detailed info if verbose
    if [ "$VERBOSE" = "true" ]; then
        echo "📋 Detailed container information:"
        docker compose -f "$compose_file" ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}" 2>/dev/null || true
        echo ""
    fi
    
    # Show logs if requested
    if [ "$SHOW_LOGS" = "true" ]; then
        echo "📝 Recent logs (last 20 lines):"
        docker compose -f "$compose_file" logs --tail=20 2>/dev/null || echo "No logs available"
        echo ""
    fi
}

# Function to check service health
check_service_health() {
    local service_url="$1"
    local service_name="$2"
    
    echo "🏥 Checking $service_name health..."
    
    if curl -s -f "$service_url/docs" > /dev/null 2>&1; then
        echo "✅ $service_name is healthy and responding"
    elif curl -s -f "$service_url" > /dev/null 2>&1; then
        echo "⚠️  $service_name is responding but docs endpoint may be unavailable"
    else
        echo "🔴 $service_name is not responding"
    fi
    echo ""
}

# Parse command line arguments
ENVIRONMENT=""
VERBOSE="false"
SHOW_LOGS="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod|test|all)
            ENVIRONMENT="$1"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -l|--logs)
            SHOW_LOGS="true"
            shift
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

# Default environment
ENVIRONMENT="${ENVIRONMENT:-dev}"

echo "🔍 FastAPI Container Status Check"
echo "================================="

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
cd "$SCRIPT_DIR/.."

case $ENVIRONMENT in
    dev)
        check_container_status "$DEV_COMPOSE_FILE" "development"
        # Check if dev service is accessible
        if docker compose -f "$DEV_COMPOSE_FILE" ps --format "{{.Status}}" | grep -q "Up"; then
            check_service_health "http://localhost:8000" "Development API"
        fi
        ;;
    prod)
        check_container_status "$PROD_COMPOSE_FILE" "production"
        # Check if prod service is accessible
        if docker compose -f "$PROD_COMPOSE_FILE" ps --format "{{.Status}}" | grep -q "Up"; then
            check_service_health "http://localhost" "Production API"
        fi
        ;;
    test)
        check_container_status "$TEST_COMPOSE_FILE" "test"
        ;;
    all)
        check_container_status "$DEV_COMPOSE_FILE" "development"
        check_container_status "$PROD_COMPOSE_FILE" "production"
        check_container_status "$TEST_COMPOSE_FILE" "test"
        
        # Check service health for running containers
        if docker compose -f "$DEV_COMPOSE_FILE" ps --format "{{.Status}}" | grep -q "Up"; then
            check_service_health "http://localhost:8000" "Development API"
        fi
        if docker compose -f "$PROD_COMPOSE_FILE" ps --format "{{.Status}}" | grep -q "Up"; then
            check_service_health "http://localhost" "Production API"
        fi
        ;;
    *)
        echo "❌ Unknown environment: $ENVIRONMENT"
        show_usage
        exit 1
        ;;
esac

# Show overall Docker status
echo "🐳 Docker System Information:"
echo "Active containers: $(docker ps --format "table {{.Names}}" | tail -n +2 | wc -l)"
echo "Total images: $(docker images -q | wc -l)"
echo "Networks: $(docker network ls --format "table {{.Name}}" | tail -n +2 | wc -l)"
echo "Volumes: $(docker volume ls --format "table {{.Name}}" | tail -n +2 | wc -l)"
echo ""

echo "📋 Management commands:"
echo "   • Start containers: $SCRIPT_DIR/run.sh [env]"
echo "   • Stop containers: $SCRIPT_DIR/stop.sh [env]"
echo "   • View logs: docker compose -f [compose-file] logs -f"
echo "   • Restart: $SCRIPT_DIR/stop.sh [env] && $SCRIPT_DIR/run.sh [env]"
