#!/bin/bash

# Docker CLI - Centralized interface for all Docker operations
# This script provides a unified command-line interface for Docker operations
# Uses dynamic project name from pyproject.toml

# Source utility functions
SOURCE_DIR="$(dirname "$0")"
source "$SOURCE_DIR/_utils.sh"

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global configuration
PROJECT_NAME=""
ENV_FILE=""
SCRIPT_DIR=""
DEFAULT_ENV="dev"

# Helper function to get compose file based on environment
get_compose_file() {
    local env="${1:-$DEFAULT_ENV}"
    case "$env" in
        dev)
            echo "$SCRIPT_DIR/../../.docker/docker-compose.dev.yml"
            ;;
        prod)
            echo "$SCRIPT_DIR/../../.docker/docker-compose.prod.yml"
            ;;
        test)
            echo "$SCRIPT_DIR/../../.docker/docker-compose.test.yml"
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $env. Valid options: dev, prod, test${NC}" >&2
            return 1
            ;;
    esac
}

# Helper function to validate environment
validate_environment() {
    local env="$1"
    case "$env" in
        dev|prod|test)
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $env. Valid options: dev, prod, test${NC}" >&2
            return 1
            ;;
    esac
}

# Initialize environment
init_environment() {
    # Get project name from pyproject.toml
    PROJECT_NAME=$(get_project_name)
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to get project name from pyproject.toml${NC}"
        exit 1
    fi

    # Generate Docker environment file
    echo -e "${BLUE}📋 Generating Docker environment file...${NC}"
    "$SOURCE_DIR/_generate-env.sh"
    ENV_FILE="$SOURCE_DIR/.env.docker"
    SCRIPT_DIR="$(realpath "$(dirname "$0")")"
    
    # Verify Docker is available
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi

    if ! docker compose version > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker Compose is not available. Please install Docker Compose.${NC}"
        exit 1
    fi
}

# Show main usage
show_usage() {
    echo -e "${BLUE}🐳 Docker CLI - Centralized Docker Operations${NC}"
    echo "=============================================="
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo "  build [options]       Build Docker image"
    echo "  run [options]         Run application"
    echo "  test [options]        Run test suite"
    echo "  cleanup [options]     Clean up Docker resources"
    echo "  logs [options]        View container logs"
    echo "  status [options]      Show container status"
    echo "  stop [options]        Stop running containers"
    echo "  bash [options]        Open bash shell in container"
    echo "  deploy [options]      Deploy to production"
    echo ""
    echo -e "${GREEN}Global Options:${NC}"
    echo "  -e, --env ENV        Environment: dev, prod, test (default: dev)"
    echo "  -h, --help           Show help for command"
    echo "  -v, --verbose        Enable verbose output"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0 build --env prod          # Build for production"
    echo "  $0 run --port 3000 --env dev # Run dev environment on port 3000"
    echo "  $0 test --env test           # Run tests in test environment"
    echo "  $0 cleanup --dry-run         # Preview cleanup actions"
    echo ""
    echo "Use '$0 <command> --help' for command-specific options."
}

# Build command - delegate to wrapper script
cmd_build() {
    "$SOURCE_DIR/_build.sh" "$@"
}

# Run command - delegate to wrapper script
cmd_run() {
    "$SOURCE_DIR/_run.sh" "$@"
}

# Test command - delegate to wrapper script
cmd_test() {
    "$SOURCE_DIR/_test.sh" "$@"
}

# Cleanup command
cmd_cleanup() {
    # Delegate to the full cleanup script with all arguments
    "$SOURCE_DIR/_cleanup.sh" "$@"
}

# Logs command
cmd_logs() {
    # Delegate to the logs script with all arguments
    "$SOURCE_DIR/_logs.sh" "$@"
}

# Status command
cmd_status() {
    # Delegate to the status script with all arguments
    "$SOURCE_DIR/_status.sh" "$@"
}

# Stop command - delegate to wrapper script
cmd_stop() {
    "$SOURCE_DIR/_stop.sh" "$@"
}

# Bash command
cmd_bash() {
    # Delegate to the bash script with all arguments
    "$SOURCE_DIR/_bash.sh" "$@"
}

# Deploy command - delegate to wrapper script
cmd_deploy() {
    "$SOURCE_DIR/_deploy.sh" "$@"
}

# Main command dispatcher
main() {
    # Check for help or no arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Initialize environment
    init_environment
    
    # Get command
    local command="$1"
    shift
    
    # Dispatch to appropriate command
    case "$command" in
        build)
            cmd_build "$@"
            ;;
        run)
            cmd_run "$@"
            ;;
        test)
            cmd_test "$@"
            ;;
        cleanup)
            cmd_cleanup "$@"
            ;;
        logs)
            cmd_logs "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        bash)
            cmd_bash "$@"
            ;;
        deploy)
            cmd_deploy "$@"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
