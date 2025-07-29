#!/bin/bash

# Docker Compose Logs script for FastAPI File Downloader & PDF Summarizer
# This script helps view and manage container logs using Docker Compose

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

# Default values
FOLLOW=false
TAIL_LINES=50

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [ENVIRONMENT]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev     Show logs for development containers (default)"
    echo "  prod    Show logs for production containers"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --env ENV   Environment: dev, prod, test (default: dev)"
    echo "  -f, --follow    Follow log output"
    echo "  -t, --tail N    Show last N lines (default: 50)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show last 50 lines of dev containers"
    echo "  $0 -f                 # Follow dev container logs"
    echo "  $0 -t 100 prod        # Show last 100 lines of prod containers"
    echo "  $0 --follow prod      # Follow prod container logs"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="${2:-dev}"
                if ! validate_environment "$environment"; then
                    exit 1
                fi
                shift 2
                ;;
            -f|--follow)
                FOLLOW=true
                shift
                ;;
            -t|--tail)
                TAIL_LINES="$2"
                shift 2
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
}

view_logs() {
    local environment="$1"
    local project_name="$2"

    echo ""
    echo "📋 Viewing logs for ${environment} environment"
    echo "============================================="

    # Check if containers exist
    if ! docker compose -p $project_name-$environment ps --services | grep -q "app"; then
        echo "❌ Error: No containers found for ${environment} environment."
        echo ""
        exit 1
    fi

    # Show container status
    echo "Container status:"
    docker compose -p $project_name-$environment ps
    echo ""

    # Build docker compose logs command
    DOCKER_CMD="docker compose -p $project_name-$environment logs"

    if [ "$FOLLOW" = true ]; then
        DOCKER_CMD="$DOCKER_CMD --follow"
    else
        DOCKER_CMD="$DOCKER_CMD --tail $TAIL_LINES"
    fi

    DOCKER_CMD="$DOCKER_CMD app"

    # Show logs
    echo "📄 Container logs:"
    echo "=================="
    if [ "$FOLLOW" = true ]; then
        echo "Following logs (Press Ctrl+C to stop)..."
        echo ""
    fi

    eval $DOCKER_CMD
}

main() {
    # Check for help or no arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    parse_args "$@"

    # Get project name from pyproject.toml
    project_name=$(get_project_name)
    echo "✅ Project name: $project_name" 

    view_logs "$environment" "$project_name"
}

main "$@"
