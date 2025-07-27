#!/bin/bash

# Docker Cleanup Script for GenAI Agent
# This script removes all project-created Docker resources
# Uses dynamic project name from .env.docker file

# Source utility functions
SOURCE_DIR="$(dirname "$0")"
source "$SOURCE_DIR/_utils.sh"

set -e  # Exit on any error

# Generate Docker environment file to ensure consistency
echo "📋 Generating Docker environment file..."
"$SOURCE_DIR/_generate-env.sh"
ENV_FILE="$SOURCE_DIR/.env.docker"

# Source the environment file to get PROJECT_NAME
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ PROJECT_NAME not found in environment file"
    exit 1
fi

echo "📋 Using project name from .env.docker: $PROJECT_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(dirname "$0")"
DEV_COMPOSE_FILE="$SCRIPT_DIR/../.docker/docker-compose.dev.yml"
PROD_COMPOSE_FILE="$SCRIPT_DIR/../.docker/docker-compose.prod.yml"
TEST_COMPOSE_FILE="$SCRIPT_DIR/../.docker/docker-compose.test.yml"

# Default values
DRY_RUN=false
FORCE=false
VERBOSE=false

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to execute commands with dry-run support
execute_cmd() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status "$YELLOW" "🔍 [DRY RUN] Would execute: $cmd"
        return 0
    fi
    
    if [ "$VERBOSE" = "true" ]; then
        print_status "$BLUE" "🔧 Executing: $cmd"
    fi
    
    if eval "$cmd" 2>/dev/null; then
        if [ -n "$description" ]; then
            print_status "$GREEN" "✅ $description"
        fi
        return 0
    else
        if [ -n "$description" ]; then
            print_status "$YELLOW" "⚠️  $description (may not exist)"
        fi
        return 0  # Don't fail the script for missing resources
    fi
}

# Function to show help
show_help() {
    cat << EOF
Docker Cleanup Script for $PROJECT_NAME

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    Removes all Docker resources created by this project including:
    • Containers (dev, prod, test environments)
    • Images (${PROJECT_NAME}:latest and related)
    • Volumes (${PROJECT_NAME}-downloads)
    • Networks (${PROJECT_NAME}-network)
    • Build cache

OPTIONS:
    --dry-run       Show what would be removed without executing
    --force         Skip confirmation prompts
    -v, --verbose   Show detailed command execution
    -h, --help      Show this help message

EXAMPLES:
    $0                    # Interactive cleanup with confirmation
    $0 --dry-run          # Preview what would be removed
    $0 --force            # Remove all resources without prompts
    $0 --verbose --dry-run # Preview with detailed output

SAFETY:
    • Only removes resources with project prefix: $PROJECT_NAME
    • Safe to run - won't affect other Docker projects
    • Use --dry-run to preview changes before execution
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to stop and remove containers
remove_containers() {
    print_status "$BLUE" "🛑 Stopping and removing containers..."
    
    # List specific containers created by project scripts
    echo "  Listing containers to remove..."
    local dev_containers=$(docker compose -f "$DEV_COMPOSE_FILE" --env-file "$ENV_FILE" ps --format "{{.Name}}" 2>/dev/null || true)
    local prod_containers=$(docker compose -f "$PROD_COMPOSE_FILE" --env-file "$ENV_FILE" ps --format "{{.Name}}" 2>/dev/null || true)
    local test_containers=$(docker compose -f "$TEST_COMPOSE_FILE" --env-file "$ENV_FILE" ps --format "{{.Name}}" 2>/dev/null || true)
    
    # Check for specific project containers by exact name
    local specific_containers=""
    for container_name in "${PROJECT_NAME}-app" "${PROJECT_NAME}-app-prod" "${PROJECT_NAME}-test"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$" 2>/dev/null; then
            specific_containers="$specific_containers $container_name"
        fi
    done
    
    if [ -n "$dev_containers" ]; then
        echo "    Dev containers: $dev_containers"
    fi
    if [ -n "$prod_containers" ]; then
        echo "    Prod containers: $prod_containers"
    fi
    if [ -n "$test_containers" ]; then
        echo "    Test containers: $test_containers"
    fi
    if [ -n "$specific_containers" ]; then
        echo "    Specific project containers:$specific_containers"
    fi
    
    if [ -z "$dev_containers" ] && [ -z "$prod_containers" ] && [ -z "$test_containers" ] && [ -z "$specific_containers" ]; then
        echo "    No project containers found"
    fi
    
    # Stop and remove containers using Docker Compose (safest method)
    execute_cmd "docker compose -f '$DEV_COMPOSE_FILE' --env-file '$ENV_FILE' down" "Dev containers stopped"
    execute_cmd "docker compose -f '$PROD_COMPOSE_FILE' --env-file '$ENV_FILE' down" "Prod containers stopped"
    execute_cmd "docker compose -f '$TEST_COMPOSE_FILE' --env-file '$ENV_FILE' down" "Test containers stopped"
    
    # Remove specific project containers by exact name (if any remain)
    for container_name in "${PROJECT_NAME}-app" "${PROJECT_NAME}-app-prod" "${PROJECT_NAME}-test"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$" 2>/dev/null; then
            execute_cmd "docker rm -f $container_name" "$container_name container removed"
        fi
    done
}

# Function to remove images
remove_images() {
    print_status "$BLUE" "🖼️  Removing images..."
    
    # List specific images created by project scripts
    echo "  Listing images to remove..."
    local project_image="${PROJECT_NAME}:latest"
    local image_exists=""
    
    # Check if the specific project image exists
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${project_image}$" 2>/dev/null; then
        image_exists="$project_image"
        echo "    Project image: $project_image"
    else
        echo "    No project images found"
    fi
    
    # Only remove the specific image created by build.sh
    if [ -n "$image_exists" ]; then
        execute_cmd "docker rmi ${PROJECT_NAME}:latest" "${PROJECT_NAME}:latest image removed"
    fi
    
    # Note: We don't remove dangling images as they may belong to other projects
    # Users can run 'docker image prune' manually if needed
}

# Function to remove volumes
remove_volumes() {
    print_status "$BLUE" "💾 Removing volumes..."
    
    # List specific volumes created by project scripts
    echo "  Listing volumes to remove..."
    
    # Check for Docker Compose managed volumes (created by prod environment)
    local compose_volumes=$(docker compose -f "$PROD_COMPOSE_FILE" --env-file "$ENV_FILE" config --volumes 2>/dev/null || true)
    local existing_volumes=""
    
    # Check if compose-managed volumes exist
    if [ -n "$compose_volumes" ]; then
        for volume in $compose_volumes; do
            # Docker Compose prefixes volumes with project name
            local full_volume_name="${PROJECT_NAME}_${volume}"
            if docker volume ls --format "{{.Name}}" | grep -q "^${full_volume_name}$" 2>/dev/null; then
                existing_volumes="$existing_volumes $full_volume_name"
            fi
        done
    fi
    
    if [ -n "$existing_volumes" ]; then
        echo "    Project volumes:$existing_volumes"
    else
        echo "    No project volumes found"
    fi
    
    # Remove volumes using Docker Compose (safest method)
    execute_cmd "docker compose -f '$PROD_COMPOSE_FILE' --env-file '$ENV_FILE' down -v" "Project volumes removed via compose"
    
    # Note: We don't remove unused volumes as they may belong to other projects
    # Users can run 'docker volume prune' manually if needed
}

# Function to remove networks
remove_networks() {
    print_status "$BLUE" "🌐 Removing networks..."
    
    # List specific networks created by project scripts
    echo "  Listing networks to remove..."
    local project_network="${PROJECT_NAME}-network"
    local network_exists=""
    
    # Check if the specific project network exists
    if docker network ls --format "{{.Name}}" | grep -q "^${project_network}$" 2>/dev/null; then
        network_exists="$project_network"
        echo "    Project network: $project_network"
    else
        echo "    No project networks found"
    fi
    
    # Remove the specific network created by Docker Compose files
    if [ -n "$network_exists" ]; then
        execute_cmd "docker network rm ${PROJECT_NAME}-network" "${PROJECT_NAME}-network removed"
    fi
    
    # Note: We don't remove unused networks as they may belong to other projects
    # Users can run 'docker network prune' manually if needed
}

# Function to remove build cache
remove_build_cache() {
    print_status "$BLUE" "🗑️  Removing build cache..."
    
    echo "  Note: Build cache removal affects all Docker projects on this system"
    echo "  Only removing dangling build cache to preserve other projects' cache"
    
    # Only remove dangling build cache (safer approach)
    execute_cmd "docker builder prune -f" "Dangling build cache removed"
    
    # Note: We don't run 'docker system prune' as it affects all Docker projects
    # Users can run it manually if they want to clean up everything
}

# Function to show resource counts
show_resource_counts() {
    if [ "$VERBOSE" = "true" ]; then
        echo ""
        print_status "$BLUE" "📊 Current Docker resources:"
        echo "   Containers: $(docker ps -aq | wc -l)"
        echo "   Images: $(docker images -q | wc -l)"
        echo "   Volumes: $(docker volume ls -q | wc -l)"
        echo "   Networks: $(docker network ls -q | wc -l)"
        echo ""
    fi
}

# Main cleanup function
main() {
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_status "$RED" "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker compose version > /dev/null 2>&1; then
        print_status "$RED" "❌ Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    
    # Show header
    print_status "$BLUE" "🧹 Docker Cleanup Script"
    echo "======================================"
    print_status "$GREEN" "📦 Removing all project-created resources"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status "$YELLOW" "🔍 DRY RUN MODE - No changes will be made"
    fi
    
    echo ""
    
    # Show current resource counts
    show_resource_counts
    
    # Confirmation prompt (unless forced or dry-run)
    if [ "$FORCE" != "true" ] && [ "$DRY_RUN" != "true" ]; then
        print_status "$YELLOW" "Remove all project-created Docker resources? (containers, images, volumes, networks, cache)"
        read -p "Continue? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "$YELLOW" "⏭️  Cleanup cancelled by user"
            exit 0
        fi
        echo ""
    elif [ "$DRY_RUN" = "true" ]; then
        print_status "$YELLOW" "🔍 DRY RUN - Showing what would be removed:"
        echo ""
    fi
    
    # Execute cleanup steps
    remove_containers
    remove_images
    remove_volumes
    remove_networks
    remove_build_cache
    
    echo ""
    
    # Show final status
    if [ "$DRY_RUN" = "true" ]; then
        print_status "$YELLOW" "🔍 DRY RUN COMPLETE - No changes were made"
        print_status "$BLUE" "Run without --dry-run to execute cleanup"
    else
        print_status "$GREEN" "✅ Cleanup completed successfully!"
        
        # Show updated resource counts
        show_resource_counts
        
        print_status "$BLUE" "🚀 Next steps:"
        echo "   • Build: $SCRIPT_DIR/build.sh"
        echo "   • Run: $SCRIPT_DIR/run.sh"
        echo "   • Deploy: $SCRIPT_DIR/deploy.sh"
    fi
}

# Run main function
main "$@"
