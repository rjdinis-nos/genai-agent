#!/bin/bash

# Docker Build Script - Build Docker images with environment support
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
            echo "$SOURCE_DIR/../../.docker/docker-compose.dev.yml"
            ;;
        prod)
            echo "$SOURCE_DIR/../../.docker/docker-compose.prod.yml"
            ;;
        test)
            echo "$SOURCE_DIR/../../.docker/docker-compose.test.yml"
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
    # Convert to absolute path since we'll change directories
    ENV_FILE="$(cd "$SOURCE_DIR" && pwd)/.env.docker"
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

# Build command
cmd_build() {
    local tag="latest"
    local environment="$DEFAULT_ENV"
    local verbose="false"
    local no_cache="false"
    
    # Parse build-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="$2"
                if ! validate_environment "$environment"; then
                    return 1
                fi
                shift 2
                ;;
            -t|--tag)
                tag="$2"
                shift 2
                ;;
            --no-cache)
                no_cache="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS] [TAG]"
                echo ""
                echo "Build Docker images using Docker Compose"
                echo ""
                echo "Options:"
                echo "  -e, --env ENV        Environment: dev, prod, test (default: dev)"
                echo "  -t, --tag TAG        Image tag (default: latest)"
                echo "  --no-cache           Build without using cache"
                echo "  -v, --verbose        Enable verbose output"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                      # Build dev environment with latest tag"
                echo "  $0 -e prod v1.0         # Build prod environment with v1.0 tag"
                echo "  $0 --no-cache           # Build without cache"
                echo "  $0 -v                   # Build with verbose output"
                return 0
                ;;
            *)
                # Treat unknown argument as tag if it doesn't start with -
                if [[ "$1" != -* ]]; then
                    tag="$1"
                    shift
                else
                    echo -e "${RED}❌ Unknown option: $1${NC}"
                    echo "Use -h or --help for usage information"
                    return 1
                fi
                ;;
        esac
    done
    
    compose_file=$(get_compose_file "$environment")
    # Convert to absolute path since we'll change directories
    compose_file="$(realpath "$compose_file")"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}🔨 Building Docker image${NC}"
    echo "=========================="
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${GREEN}🏷️  Tag: ${tag}${NC}"
    echo -e "${GREEN}📄 Using compose file: $(basename "$compose_file")${NC}"
    
    # Change to project root
    local project_root="$SCRIPT_DIR/../.."
    cd "$project_root"
    
    # Build the image
    local build_args=""
    [ "$no_cache" = "true" ] && build_args="$build_args --no-cache"
    
    # Set the image tag
    export IMAGE_TAG="$tag"
    
    echo -e "${BLUE}🐳 Building image...${NC}"
    if [ "$verbose" = "true" ]; then
        docker compose -f "$compose_file" --env-file "$ENV_FILE" build $build_args
    else
        docker compose -f "$compose_file" --env-file "$ENV_FILE" build $build_args > /dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build completed successfully!${NC}"
        echo ""
        echo -e "${BLUE}📋 Next steps:${NC}"
        echo "   • Run application: $SOURCE_DIR/_run.sh --env $environment"
        echo "   • View images: docker images | grep ${PROJECT_NAME:-genai-agent}"
        echo "   • Test application: $SOURCE_DIR/_test.sh --env $environment"
    else
        echo -e "${RED}❌ Build failed!${NC}"
        return 1
    fi
}

# Initialize environment and run build command
init_environment
cmd_build "$@"
