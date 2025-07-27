#!/bin/bash

# Docker Run Script - Run application with environment support
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

# Run command
cmd_run() {
    local host_port="8000"
    local detached="true"
    local skip_build="false"
    local verbose="false"
    local reload="true"
    local skip_health="false"
    local stop_existing="false"
    local environment="$DEFAULT_ENV"
    
    # Parse run-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                host_port="$2"
                shift 2
                ;;
            -e|--env)
                environment="$2"
                if ! validate_environment "$environment"; then
                    return 1
                fi
                shift 2
                ;;
            -f|--foreground)
                detached="false"
                shift
                ;;
            --skip-build)
                skip_build="true"
                shift
                ;;
            --no-reload)
                reload="false"
                shift
                ;;
            -n|--no-health-check)
                skip_health="true"
                shift
                ;;
            --stop-existing)
                stop_existing="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Run application using Docker Compose"
                echo ""
                echo "Options:"
                echo "  -p, --port PORT      Host port to bind (default: 8000)"
                echo "  -e, --env ENV        Environment: dev, prod, test (default: dev)"
                echo "  -f, --foreground     Run in foreground (default: detached)"
                echo "  --skip-build         Skip building the image"
                echo "  --no-reload          Disable auto-reload (default: enabled)"
                echo "  -n, --no-health-check Skip health check after startup"
                echo "  --stop-existing      Stop existing containers before starting"
                echo "  -v, --verbose        Enable verbose output"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                      # Run dev environment"
                echo "  $0 -e prod -p 80        # Run prod environment on port 80"
                echo "  $0 -f --verbose         # Run in foreground with verbose output"
                echo "  $0 --stop-existing      # Stop existing containers first"
                echo "  $0 -n                   # Skip health check"
                return 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use -h or --help for usage information"
                return 1
                ;;
        esac
    done
    
    compose_file=$(get_compose_file "$environment")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Validate port number
    if ! [[ "$host_port" =~ ^[0-9]+$ ]] || [ "$host_port" -lt 1 ] || [ "$host_port" -gt 65535 ]; then
        echo -e "${RED}❌ Invalid port number: $host_port${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🚀 Starting FastAPI application${NC}"
    echo "================================"
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${GREEN}📋 Port: ${host_port}${NC}"
    echo -e "${GREEN}📋 Mode: $([ "$detached" = "true" ] && echo "Detached" || echo "Foreground")${NC}"
    echo -e "${GREEN}📋 Reload: $([ "$reload" = "true" ] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e "${BLUE}📄 Using compose file: $(basename "$compose_file")${NC}"
    
    # Change to project root
    local project_root="$SCRIPT_DIR/../.."
    cd "$project_root"
    
    # Check if .env file exists for production
    if [ "$environment" = "prod" ] && [ ! -f ".env" ]; then
        echo -e "${RED}❌ Error: .env file not found. This is required for production deployment.${NC}"
        echo "Please create .env file with your GEMINI_API_KEY"
        return 1
    fi
    
    # Stop existing containers if requested
    if [ "$stop_existing" = "true" ]; then
        echo -e "${BLUE}🛑 Stopping existing containers...${NC}"
        if [ "$verbose" = "true" ]; then
            docker compose -f "$compose_file" --env-file "$ENV_FILE" down
        else
            docker compose -f "$compose_file" --env-file "$ENV_FILE" down > /dev/null 2>&1 || true
        fi
    fi
    
    # Build if not skipped
    if [ "$skip_build" = "false" ]; then
        echo -e "${BLUE}📦 Building image...${NC}"
        "$SOURCE_DIR/_build.sh" --env "$environment" "latest" > /dev/null
    fi
    
    # Set environment variables for Docker Compose
    export HOST_PORT="$host_port"
    export RELOAD_MODE="$reload"
    
    # Update the .env.docker file with HOST_PORT
    echo "HOST_PORT=$host_port" >> "$ENV_FILE"
    echo "RELOAD_MODE=$reload" >> "$ENV_FILE"
    
    # Run the application
    local run_args=""
    [ "$detached" = "true" ] && run_args="-d"
    [ "$verbose" = "true" ] && run_args="$run_args --verbose"
    
    docker compose -f "$compose_file" --env-file "$ENV_FILE" up $run_args
    
    # Wait for application to start (only in detached mode)
    if [ "$detached" = "true" ]; then
        echo -e "${YELLOW}⏳ Waiting for application to start...${NC}"
        sleep 5
    fi
    
    # Health check (unless skipped)
    if [ "$skip_health" = "false" ] && [ "$detached" = "true" ]; then
        echo -e "${BLUE}🏥 Performing health check...${NC}"
        local health_url="http://localhost:${host_port}/docs"
        
        for i in {1..10}; do
            if curl -f "$health_url" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Health check passed!${NC}"
                break
            fi
            if [ $i -eq 10 ]; then
                echo -e "${RED}❌ Health check failed after 10 attempts${NC}"
                echo "Container logs:"
                docker compose -f "$compose_file" --env-file "$ENV_FILE" logs --tail 20
                return 1
            fi
            if [ "$verbose" = "true" ]; then
                echo -e "${YELLOW}⏳ Attempt $i/10 - waiting for application...${NC}"
            fi
            sleep 3
        done
    elif [ "$skip_health" = "true" ]; then
        echo -e "${YELLOW}⚠️  Health check skipped as requested${NC}"
    elif [ "$detached" = "false" ]; then
        echo -e "${BLUE}ℹ️  Health check skipped in foreground mode${NC}"
    fi
    
    # Show success message (only in detached mode)
    if [ "$detached" = "true" ]; then
        echo ""
        echo -e "${GREEN}🎉 Application started successfully!${NC}"
        echo ""
        echo -e "${BLUE}🌐 Application is available at:${NC}"
        echo "   • API: http://localhost:${host_port}"
        echo "   • Docs: http://localhost:${host_port}/docs"
        echo "   • ReDoc: http://localhost:${host_port}/redoc"
        echo ""
        echo -e "${BLUE}📋 Container management:${NC}"
        echo "   • View status: $SOURCE_DIR/../cli.sh status --env $environment"
        echo "   • View logs: $SOURCE_DIR/../cli.sh logs --env $environment"
        echo "   • Stop application: $SOURCE_DIR/_stop.sh --env $environment"
    else
        echo ""
        echo -e "${BLUE}ℹ️  Application running in foreground mode${NC}"
        echo "   • Press Ctrl+C to stop the application"
        echo "   • Application available at: http://localhost:${host_port}"
    fi
}

# Initialize environment and run command
init_environment
cmd_run "$@"
