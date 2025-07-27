#!/bin/bash

# Docker Stop Script - Stop containers with environment support
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
DEFAULT_ENV="dev"

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

# Stop command
cmd_stop() {
    local environment="$DEFAULT_ENV"
    local verbose="false"
    
    # Parse stop-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="$2"
                if [ "$environment" != "all" ] && ! validate_environment "$environment"; then
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
                echo "Stop Docker containers using Docker Compose"
                echo ""
                echo "Options:"
                echo "  -e, --env ENV        Environment: dev, prod, test, all (default: dev)"
                echo "  -v, --verbose        Enable verbose output"
                echo "  -h, --help           Show this help"
                echo ""
                echo "Examples:"
                echo "  $0                # Stop dev containers"
                echo "  $0 --env prod     # Stop prod containers"
                echo "  $0 --env all      # Stop all containers"
                return 0
                ;;
            *)
                # Support legacy positional argument
                if [ -z "$environment" ] || [ "$environment" = "$DEFAULT_ENV" ]; then
                    environment="$1"
                    if [ "$environment" != "all" ] && ! validate_environment "$environment"; then
                        return 1
                    fi
                else
                    echo -e "${RED}❌ Unknown option: $1${NC}"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    echo -e "${BLUE}🛑 Stopping Docker containers${NC}"
    echo "=============================="
    
    # Change to project root
    local project_root="$SCRIPT_DIR/../.."
    cd "$project_root"
    
    if [ "$environment" = "all" ]; then
        echo -e "${YELLOW}🔄 Stopping all environments...${NC}"
        
        # Stop all environments
        for env in dev prod test; do
            local compose_file
            compose_file=$(get_compose_file "$env")
            if [ -f "$compose_file" ]; then
                echo -e "${BLUE}🔧 Stopping $env containers...${NC}"
                if [ "$verbose" = "true" ]; then
                    docker compose -f "$compose_file" --env-file "$ENV_FILE" down
                else
                    docker compose -f "$compose_file" --env-file "$ENV_FILE" down > /dev/null 2>&1 || true
                fi
            fi
        done
    else
        local compose_file
        compose_file=$(get_compose_file "$environment")
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
        echo -e "${BLUE}📄 Using compose file: $(basename "$compose_file")${NC}"
        
        if [ ! -f "$compose_file" ]; then
            echo -e "${RED}❌ Compose file not found: $compose_file${NC}"
            return 1
        fi
        
        echo -e "${BLUE}🔧 Stopping $environment containers...${NC}"
        if [ "$verbose" = "true" ]; then
            docker compose -f "$compose_file" --env-file "$ENV_FILE" down
        else
            docker compose -f "$compose_file" --env-file "$ENV_FILE" down
        fi
    fi
    
    echo -e "${GREEN}✅ Containers stopped successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 To start containers again:${NC}"
    echo "   • Development: $0/../_run.sh --env dev"
    echo "   • Production: $0/../_deploy.sh --env prod"
    echo "   • Testing: $0/../_test.sh --env test"
}

# Initialize environment and run stop command
init_environment
cmd_stop "$@"
