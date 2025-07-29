#!/bin/bash

# Utility functions for Docker scripts
# This file provides common functions used across Docker scripts


# Directory configuration
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../")"

# Docker Compose variables
ENV_FILE="$(realpath $SCRIPT_DIR/.env.docker)"
DEV_COMPOSE_FILE="$(realpath $SCRIPT_DIR/../../.docker/docker-compose.dev.yml)"
PROD_COMPOSE_FILE="$(realpath $SCRIPT_DIR/../../.docker/docker-compose.prod.yml)"
TEST_COMPOSE_FILE="$(realpath $SCRIPT_DIR/../../.docker/docker-compose.test.yml)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Function to extract project name from pyproject.toml
get_project_name() {
    local pyproject_file="$(dirname "$0")/../../pyproject.toml"
    
    if [ ! -f "$pyproject_file" ]; then
        echo "❌ Error: pyproject.toml not found at $pyproject_file" >&2
        exit 1
    fi
    
    # Extract project name from pyproject.toml
    local project_name=$(grep '^name = ' "$pyproject_file" | sed 's/name = "\(.*\)"/\1/' | tr -d '"')
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Could not extract project name from pyproject.toml" >&2
        exit 1
    fi
    
    echo "$project_name"
}

# Function to validate project name
validate_project_name() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name is empty" >&2
        return 1
    fi
    
    # Check if project name contains only valid characters for Docker resources
    if ! echo "$project_name" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$'; then
        echo "❌ Error: Project name '$project_name' contains invalid characters for Docker resources" >&2
        return 1
    fi
    
    return 0
}

get_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        echo "❌ Error: .env file not found" >&2
        exit 1
    fi
    echo "$ENV_FILE"
}

# Function to check if Docker Compose file exists
check_compose_file() {
    local compose_file="$1"
    
    if [ ! -f "$compose_file" ]; then
        echo "❌ Docker Compose file not found: $(realpath -s -e $compose_file)"
        exit 1
    fi

    return 0
}

# Function to get compose file based on environment
get_compose_file() {
    case "$1" in
        dev)
            check_compose_file "$DEV_COMPOSE_FILE"
            echo "$DEV_COMPOSE_FILE"
            ;;
        prod)
            check_compose_file "$PROD_COMPOSE_FILE"
            echo "$PROD_COMPOSE_FILE"
            ;;
        test)
            check_compose_file "$TEST_COMPOSE_FILE"
            echo "$TEST_COMPOSE_FILE"
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $1. Valid options: dev, prod, test${NC}" >&2
            exit 1
            ;;
    esac 
}

# Function to check if Docker and Docker Compose are running
check_docker_is_installed() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi

    if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
    fi

    echo "✅ Docker and Docker Compose are installed."

    return 0
}

# Helper function to validate environment
validate_environment() {
    local env="$1"
    case "$env" in
        dev|prod|test|all)
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $env. Valid options: dev, prod, test, all${NC}" >&2
            return 1
            ;;
    esac
}   