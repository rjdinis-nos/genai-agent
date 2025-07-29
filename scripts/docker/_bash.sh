#!/bin/bash

# Simple Bash Entry script for FastAPI containers
# Quick access to bash shell in running containers

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

# Function to show usage
show_usage() {
    echo "Usage: $0 [DEFAULT_ENV] [OPTIONS]"
    echo ""
    echo "Quick bash access to FastAPI containers"
    echo ""
    echo "Environment:"
    echo "  dev     Enter development container (default)"
    echo "  prod    Enter production container"
    echo "  test    Enter test container"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --env ENV      Environment: dev, prod, test (default: dev)"
    echo "  -v, --verbose      Show detailed container information"
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
        -e|--env)
            environment="${2:-dev}"
            if ! validate_environment "$environment"; then
                exit 1
            fi
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -u|--user)
            user="${2:-root}"
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


# Get project name from pyproject.toml
project_name=$(get_project_name)
echo "✅ Project name: $project_name"

# Get env file
env_file=$(get_env_file "$environment")
echo "✅ Env file: $(realpath -s -e $env_file)"

# Get compose file
compose_file=$(get_compose_file "$environment")
echo "✅ Compose file: $(realpath -s -e $compose_file)"

echo
echo "🐚 Entering $DEFAULT_ENV container with bash"
echo "==========================================="

# Check if container is running
if ! docker compose -p $project_name-$environment ps --filter "status=running" | grep -q "$project_name"; then
    echo "❌ Error: No running containers found for $DEFAULT_ENV environment"
    echo ""
    echo "💡 Start the container first:"

    exit 1
fi

echo "🚪 Connecting to container as user: $user"
echo "   • Type 'exit' to leave the container"
echo ""

# Enter container with bash
docker compose -p $project_name-$environment exec --user "$user" app bash
