#!/bin/bash

# Docker Build Script - Build Docker images with environment argument
# Uses dynamic project name from pyproject.toml

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

build_image() {
    local environment="$1"
    local project_name="$2"
    local env_file="$3"
    local compose_file="$4"
    local tag="$5"
    local no_cache="$6"
    local verbose="$7"
    
    echo ""
    echo -e "${BLUE}🔨 Building Docker image${NC}"
    echo "=========================="
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${GREEN}🏷️ Image name: ${project_name}-${environment}:${tag}${NC}"
    echo -e "${GREEN}📄 Using compose file: $(basename "$compose_file")${NC}"
    
    # Build arguments
    local build_args=""
    [ "$no_cache" = "true" ] && build_args="$build_args --no-cache"
    
    # Set the image tag
    export IMAGE_TAG="$tag"

    # Set docker compose environment variables
    COMPOSE_ENV_VARS=$(echo "ENVIRONMENT=$environment PROJECT_NAME=$project_name")

    # Build image    
    echo -e "${BLUE}🐳 Building image...${NC}"
    if [ "$verbose" = "true" ]; then
        eval $COMPOSE_ENV_VARS docker compose -f "$compose_file" --env-file "$env_file" -p $project_name-$environment build $build_args
    else
        eval $COMPOSE_ENV_VARS docker compose -f "$compose_file" --env-file "$env_file" -p $project_name-$environment build $build_args > /dev/null
    fi

    # Check if image exists
    eval $COMPOSE_ENV_VARS docker compose -f "$compose_file" --env-file "$env_file" images
    [ $? -eq 0 ] && echo "✅ Image built successfully" || echo "❌ Image build failed"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${BLUE}📋 Next steps:${NC}"
        echo "   • Run application: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/_run.sh --env $environment"
        echo "   • View images: docker compose -p $project_name-$environment images | grep ${project_name}"
    else
        echo -e "${RED}❌ Build failed!${NC}"
        return 1
    fi
}

show_usage() {
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
}

# Parse build-specific arguments
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
                show_usage
                exit 0
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
}

# Build command
main() {
    local tag="latest"
    local environment="$DEFAULT_ENV"
    local verbose="false"
    local no_cache="false"

    parse_args "$@"

    # Get project name from pyproject.toml
    project_name=$(get_project_name)
    echo "✅ Project name: $project_name"

    # Get env file
    env_file=$(get_env_file "$environment")
    echo "✅ Env file: $(realpath -s -e $env_file)"

    # Get compose file
    compose_file=$(get_compose_file "$environment")
    echo "✅ Compose file: $(realpath -s -e $compose_file)"
    
    build_image "$environment" "$project_name" "$env_file" "$compose_file" "$tag" "$no_cache" "$verbose"
}

main "$@"
