#!/bin/bash

# Docker Run Script - Run application with environment support
# Uses dynamic project name from pyproject.toml

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"


check_health() {
    local project_name="$1"
    local host_port="$2"
    local verbose="$3"
    
    local health_url="http://localhost:${host_port}/docs"
    echo -e "${BLUE}🏥 Performing health check to $health_url ...${NC}"
    
    for i in {1..10}; do
        if curl -f "$health_url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check passed!${NC}"
            break
        fi
        if [ $i -eq 10 ]; then
            echo -e "${RED}❌ Health check failed after 10 attempts${NC}"
            echo "Container logs:"
            docker compose -p "$project_name" logs --tail 20
            return 1
        fi
        if [ "$verbose" = "true" ]; then
            echo -e "${YELLOW}⏳ Attempt $i/10 - waiting for application...${NC}"
        fi
        sleep 3
    done
}

show_success_message() {
    local host_port="$1"
    local environment="$2"

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
        echo "   • View status: $(realpath -e --relative-to=$PWD $SCRIPT_DIR/cli.sh) status -e $environment"
        echo "   • View logs: $(realpath -e --relative-to=$PWD $SCRIPT_DIR/cli.sh) logs -e $environment"
        echo "   • Test application: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/_test.sh --env $environment"
        echo "   • Run bash in container: $(realpath -e --relative-to=$PWD $SCRIPT_DIR/cli.sh) bash -e $environment"
        echo "   • Stop application: $(realpath -e --relative-to=$PWD $SCRIPT_DIR/cli.sh) stop -e $environment"
    else
        echo ""
        echo -e "${BLUE}ℹ️  Application running in foreground mode${NC}"
        echo "   • Press Ctrl+C to stop the application"
        echo "   • Application available at: http://localhost:${host_port}"
    fi
}

start_container() {
    local environment="$1"
    local project_name="$2"
    local compose_file="$3"
    local env_file="$4"
    local host_port="$5"
    local detached="$6"
    local skip_health="$7"
    local verbose="$8"

    echo
    echo -e "${BLUE}🚀 Starting FastAPI application${NC}"
    echo "================================"
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${GREEN}📋 Port: ${host_port}${NC}"
    echo -e "${GREEN}📋 Mode: $([ "$detached" = "true" ] && echo "Detached" || echo "Foreground")${NC}" 
    
    # Build if not skipped
    if [ "$build" = "true" ]; then
        echo -e "${BLUE}📦 Building image...${NC}"
        "$SCRIPT_DIR/_build.sh" --env "$environment" "latest" > /dev/null
    fi
    
    # Set run arguments
    local run_args=""
    [ "$detached" = "true" ] && run_args="-d"

    # Set docker compose environment variables
    COMPOSE_ENV_VARS=$(echo "ENVIRONMENT=$environment PROJECT_NAME=$project_name HOST_PORT=$host_port")

    # Start Container in specified environment
    eval $COMPOSE_ENV_VARS docker compose -f "$compose_file" --env-file "$ENV_FILE" -p $project_name-$environment up app $run_args --build

    # Wait for application to start (only in detached mode)
    if [ "$detached" = "true" ]; then
        echo -e "${YELLOW}⏳ Waiting for application to start...${NC}"
        sleep 5
    fi

    # Check health if not skipped
    if [ "$skip_health" = "false" ] && [ "$detached" = "true" ]; then
        check_health "$project_name" "$host_port" "$verbose"
    elif [ "$skip_health" = "true" ]; then
        echo -e "${YELLOW}⚠️  Health check skipped as requested${NC}"
    elif [ "$detached" = "false" ]; then
        echo -e "${BLUE}ℹ️  Health check skipped in foreground mode${NC}"
    fi
    
    # Show success message
    show_success_message "$host_port" "$environment"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Start application using Docker Compose"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV          Environment: dev, prod, test (default: dev)"
    echo "  -p, --port PORT        Host port to bind (default: 8000)"
    echo "  -f, --foreground       Run in foreground (default: detached)"
    echo "  --build                Build the image (default: false)"
    echo "  -n, --no-health-check  Skip health check after startup"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run dev environment"
    echo "  $0 -e prod -p 80        # Run prod environment on port 80"
    echo "  $0 -f --verbose         # Run in foreground with verbose output"
    echo "  $0 -n                   # Skip health check"
}

# Parse run-specific arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                host_port="$2"
                shift 2
                ;;
            -e|--env)
                environment="${2:-dev}"
                if ! validate_environment "$environment"; then
                    exit 1
                fi
                shift 2
                ;;
            -f|--foreground)
                detached="false"
                shift
                ;;
            --build)
                build="true"
                shift
                ;;
            -n|--no-health-check)
                skip_health="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Run command
main() {
    local detached="true"
    local build="false"
    local verbose="false"
    local skip_health="false"

    # Check for help or no arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    # Parse arguments
    parse_args "$@"

    # Set default port if not specified in cli arguments
    if [ -z ${host_port} ]; then
        if [ "$environment" == "prod" ]; then
            host_port=8000
        elif [ "$environment" == "dev" ]; then
            host_port=8001
        else
            host_port=8002
        fi
    fi
    
    # Validate port number
    if ! [[ "$host_port" =~ ^[0-9]+$ ]] || [ "$host_port" -lt 1 ] || [ "$host_port" -gt 65535 ]; then
        echo -e "${RED}❌ Invalid port number: $host_port${NC}"
        exit 1
    fi

    # Get project name from pyproject.toml
    project_name=$(get_project_name)
    echo "✅ Project name: $project_name"

    # Get env file
    env_file=$(get_env_file "$environment")
    echo "✅ Env file: $(realpath -s -e $env_file)"

    # Get compose file
    compose_file=$(get_compose_file "$environment")
    echo "✅ Compose file: $(realpath -s -e $compose_file)"
    
    start_container "$environment" "$project_name" "$compose_file" "$env_file" "$host_port" "$detached" "$skip_health" "$verbose"
}

# Run command
main "$@"
