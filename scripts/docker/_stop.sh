#!/bin/bash

# Docker Stop Script - Stop containers with environment support
# Uses dynamic project name from pyproject.toml

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

show_usage() {
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
            -v|--verbose)
                verbose="true"
                shift
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
}

stop_containers() {
    local environment="$1"
    local project_name="$2"
    local verbose="$3"


    echo -e "${BLUE}🛑 Stopping Docker containers${NC}"
    echo "=============================="
    
    if [ "$environment" = "all" ]; then
        echo -e "${YELLOW}🔄 Stopping all environments...${NC}"
        
        # Stop all environments
        for env in dev prod test; do
            echo -e "${BLUE}🔧 Stopping $env containers...${NC}"
            compose_file=$(get_compose_file "$env")
            env_file=$(get_env_file "$env")

            if [ "$verbose" = "true" ]; then
                docker compose -p $project_name-$env down
            else
                docker compose -p $project_name-$env down > /dev/null 2>&1 || true
            fi
        done
    else
        echo -e "${BLUE}🔧 Stopping $environment containers...${NC}"
        compose_file=$(get_compose_file "$environment")
        env_file=$(get_env_file "$environment")
        
        if [ "$verbose" = "true" ]; then
            docker compose -p $project_name-$environment down
        else
            docker compose -p $project_name-$environment down > /dev/null 2>&1 || true
        fi
    fi
}

main() {
    local verbose="false"
    
    # Check for help or no arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    # Parse arguments
    parse_args "$@"

    # Get project name from pyproject.toml
    project_name=$(get_project_name)
    echo "✅ Project name: $project_name"

    # Stop containers
    stop_containers "$environment" "$project_name" "$verbose"
    
    echo -e "${GREEN}✅ Containers stopped successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 To start containers again:${NC}"
    echo "   • Development: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/_run.sh --env dev"
    echo "   • Production: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/_deploy.sh --env prod"
    echo "   • Testing: $(realpath -e --relative-to=$PWD $SCRIPT_DIR)/_test.sh --env test"
}

main "$@"
