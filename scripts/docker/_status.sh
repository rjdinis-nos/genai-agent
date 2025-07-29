#!/bin/bash

# Docker Compose Status script for FastAPI File Downloader & PDF Summarizer
# This script checks the status of running containers using Docker Compose

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

# Function to check service health
check_service_health() {
    local project_name="$1"
    local environment="$2"
    
    port=$(docker compose -p "$project_name"-$environment ps --format "{{.Ports}}" | grep -oP '\d+(?=->)' | head -n1)
    
    echo "🏥 Checking $environment service health on http://localhost:$port..."
    if docker compose -p "$project_name"-$environment ps --format "{{.Status}}" | grep -q "Up"; then
        if curl -s -f "http://localhost:$port/docs" > /dev/null 2>&1; then
            echo "✅ FastAPI $environment service is healthy and responding"

        elif curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
            echo "⚠️ Container is running, but FastAPI $environment service is responding but docs endpoint may be unavailable"

        else
            echo "🔴 Container is running, but FastAPI $environment service is not responding"
        fi
    else
        echo "🔴 No containers running for $environment environment"
    fi
    echo ""
}

check_service_status() {
    echo ""
    echo "🔍 FastAPI Service Status Check"
    echo "================================="

    local environment="$1"
    local project_name="$2"

    case $environment in
        dev)
            check_service_health "$project_name" "dev"
            ;;
        prod)
            check_service_health "$project_name" "prod"
            ;;
        test)
            ;;
        all)
            check_service_health "$project_name" "dev"
            check_service_health "$project_name" "prod"
            ;;
        *)
            echo "❌ Unknown environment: $environment"
            show_usage
            exit 1
            ;;
    esac
}

check_container_health() {
    local environment="$1"
    local project_name="$2"

    # Get container status
    local containers
    local containers_count

    echo "🏥 Checking $environment environment container health..."

    containers=$(docker compose -p "$project_name"-$environment ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "")
    containers_count=$(echo "$containers" | wc -l)
    
    if [ $containers_count -le "1" ] || [ "$containers" = "NAME	STATUS	PORTS" ]; then
        echo "🔴 No containers running for $environment environment"
        echo ""
        return 0
    else
        echo "$containers"
        echo ""
    fi
    
    # Show detailed info if verbose
    if [ "$VERBOSE" = "true" ]; then
        echo "📋 Detailed container information:"
        docker compose -p "$project_name"-$environment ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}" 2>/dev/null || true
        echo ""
    fi
    
    # Show logs if requested
    if [ "$SHOW_LOGS" = "true" ]; then
        echo "📝 Recent logs (last 20 lines):"
        docker compose -p "$project_name"-$environment logs --tail=20 2>/dev/null || echo "No logs available"
        echo ""
    fi
}

check_container_status() {
    echo ""
    echo "🔍 FastAPI Container Status Check"
    echo "================================="

    local environment="$1"
    local project_name="$2"

    case $environment in
        dev)
            check_container_health "$environment" "$project_name"
            ;;
        prod)
            check_container_health "$environment" "$project_name"
            ;;
        test)
            check_container_health "$environment" "$project_name"
            ;;
        all)
            check_container_health "dev" "$project_name"
            check_container_health "prod" "$project_name"
            check_container_health "test" "$project_name"
            ;;
    esac
}

show_resource_counts() {
    local environment="$1"
    local project_name="$2"

    echo "🐳 Docker System Information:"
    echo "Active containers: $(docker compose -p "$project_name"-$environment ps | tail -n +2 | wc -l)"
    echo "Total images: $(docker compose -p "$project_name"-$environment images | tail -n +2 | wc -l)"
    echo "Networks: $(docker network ls | grep "$project_name"-$environment | wc -l)"
    echo "Volumes: $(docker volume ls | grep "$project_name"-$environment | wc -l)"
    echo ""
} 

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
    echo "  -e, --env ENV    Environment: dev, prod, test (default: dev)"
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

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="${2:-dev}"
                if ! validate_environment "$environment"; then
                    show_usage
                    exit 1
                fi
                shift 2
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
}  

main() {
    # Parse command line arguments and set global variables
    VERBOSE="false"
    SHOW_LOGS="false"

    # Parse arguments
    parse_args "$@"

    project_name=$(get_project_name)
    echo "✅ Project name: $project_name"

    check_container_status "$environment" "$project_name"
    check_service_status "$environment" "$project_name"

    if [ ! $environment = "all" ]; then
        show_resource_counts "$environment" "$project_name"
    fi

    echo "📋 Management commands:"
    echo "   • Start containers: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/run.sh [env]"
    echo "   • Stop containers: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/stop.sh [env]"
    echo "   • View logs: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/logs.sh [env] -f"
}

main "$@"
