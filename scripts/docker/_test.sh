#!/bin/bash

# Docker Test Script - Run test suite with environment support
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

# Default environment
DEFAULT_ENV="test"

# Helper function to get compose file based on environment
get_compose_file() {
    local env="${1:-$DEFAULT_ENV}"
    case "$env" in
        dev)
            echo "$SOURCE_DIR/../.docker/docker-compose.dev.yml"
            ;;
        prod)
            echo "$SOURCE_DIR/../.docker/docker-compose.prod.yml"
            ;;
        test)
            echo "$SOURCE_DIR/../.docker/docker-compose.test.yml"
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
    SCRIPT_DIR="$(realpath "$(dirname "$0)")"
    
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

# Test command
cmd_test() {
    local verbose="false"
    local environment="$DEFAULT_ENV"  # Default to test environment for tests
    
    # Parse test-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="$2"
                if ! validate_environment "$environment"; then
                    return 1
                fi
                shift 2
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Run test suite using Docker Compose"
                echo ""
                echo "Options:"
                echo "  -e, --env ENV        Environment: dev, prod, test (default: test)"
                echo "  -v, --verbose        Enable verbose output"
                echo "  -h, --help           Show this help"
                echo ""
                echo "Examples:"
                echo "  $0                # Run tests in test environment"
                echo "  $0 --env dev -v   # Run tests in dev with verbose output"
                return 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                return 1
                ;;
        esac
    done
    
    local compose_file
    compose_file=$(get_compose_file "$environment")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}🧪 Running tests with Docker Compose${NC}"
    echo "===================================="
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${BLUE}📄 Using compose file: $(basename "$compose_file")${NC}"
    
    # Build main image if it doesn't exist
    if ! docker image inspect "${PROJECT_NAME}:latest" > /dev/null 2>&1; then
        echo -e "${BLUE}📦 Main image not found. Building...${NC}"
        "$SOURCE_DIR/_build.sh" --env "$environment" "latest" > /dev/null
    fi
    
    # Change to project root
    local project_root="$SCRIPT_DIR/../.."
    cd "$project_root"
    
    # Run tests
    local test_args=""
    [ "$verbose" = "true" ] && test_args="--verbose"
    
    # For test environment, use profile if it exists
    local profile_args=""
    if [ "$environment" = "test" ]; then
        profile_args="--profile test"
    fi
    
    docker compose -f "$compose_file" --env-file "$ENV_FILE" $profile_args up --build --abort-on-container-exit $test_args
    local exit_code=$?
    
    # Cleanup test containers
    docker compose -f "$compose_file" --env-file "$ENV_FILE" $profile_args down > /dev/null 2>&1
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
    else
        echo -e "${RED}❌ Tests failed!${NC}"
        exit $exit_code
    fi
}

# Initialize environment and run test command
init_environment
cmd_test "$@"
