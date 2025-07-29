#!/bin/bash

# Docker CLI - Centralized interface for all Docker operations
# This script provides a unified command-line interface for Docker operations
# Uses dynamic project name from pyproject.toml

set -e  # Exit on any error

# Source utility functions
source "$(dirname "$0")/_utils.sh"


# Initialize environment
init_environment() {
    # Verify Docker is available
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi

    # Verify Docker Compose is available
    if ! docker compose version > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker Compose is not available. Please install Docker Compose.${NC}"
        exit 1
    fi

    # Check if .env file exists for production
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo -e "${RED}❌ Error: .env file not found. This is required for deployment.${NC}"
        echo "Please create $PROJECT_ROOT/.env file with project configuration."
        return 1
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
    echo "  start [options]       Start application"
    echo "  tests [options]       Run test suite"
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
    echo "  $0 build --env prod             # Build for production"
    echo "  $0 start --port 3000 --env dev  # Run dev environment on port 3000"
    echo "  $0 test --env test              # Run tests in test environment"
    echo "  $0 cleanup --dry-run            # Preview cleanup actions"
    echo ""
    echo "Use '$0 <command> --help' for command-specific options."
}

cmd_build() {
    "$SCRIPT_DIR/_build.sh" "$@"
}

cmd_start() {
    "$SCRIPT_DIR/_start.sh" "$@"
}

cmd_tests() {
    "$SCRIPT_DIR/_tests.sh" "$@"
}

cmd_cleanup() {
    "$SCRIPT_DIR/_cleanup.sh" "$@"
}

cmd_logs() {
    "$SCRIPT_DIR/_logs.sh" "$@"
}

cmd_status() {
    "$SCRIPT_DIR/_status.sh" "$@"
}

cmd_stop() {
    "$SCRIPT_DIR/_stop.sh" "$@"
}

cmd_bash() {
    "$SCRIPT_DIR/_bash.sh" "$@"
}

cmd_deploy() {
    "$SCRIPT_DIR/_deploy.sh" "$@"
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
        start)
            cmd_start "$@"
            ;;
        tests)
            cmd_tests "$@"
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
