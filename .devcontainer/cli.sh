#!/bin/bash

# DevContainer CLI - Main wrapper script for container management
# Usage: ./cli.sh <command> [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"
CONTAINER_NAME="genai-baseline-agent-app-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${CYAN}🐳 DevContainer CLI${NC}"
    echo -e "${CYAN}==================${NC}"
    echo ""
    echo "Manage your GenAI Agent devcontainer with ease!"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}     Start the devcontainer with Docker Compose (auto-starts FastAPI)"
    echo -e "  ${GREEN}launch${NC}    Launch the devcontainer and open Windsurf (auto-starts FastAPI)"
    echo -e "  ${GREEN}vscode${NC}    Launch the devcontainer and open VS Code (auto-starts FastAPI)"
    echo -e "  ${GREEN}enter${NC}     Enter the running container with bash"
    echo -e "  ${GREEN}fastapi${NC}   Start the FastAPI server inside the container"
    echo -e "  ${GREEN}fastapi-stop${NC}  Stop the FastAPI server"
    echo -e "  ${GREEN}fastapi-restart${NC}  Restart the FastAPI server"
    echo -e "  ${GREEN}fastapi-logs${NC}  View FastAPI server logs"
    echo -e "  ${GREEN}logs${NC}      View container logs"
    echo -e "  ${GREEN}stop${NC}      Stop the container"
    echo -e "  ${GREEN}status${NC}    Show container status"
    echo -e "  ${GREEN}restart${NC}   Restart the container"
    echo -e "  ${GREEN}help${NC}      Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start           # Start devcontainer with Docker Compose + FastAPI"
    echo "  $0 launch          # Launch devcontainer and open Windsurf + FastAPI"
    echo "  $0 vscode          # Launch devcontainer and open VS Code + FastAPI"
    echo "  $0 enter           # Enter container shell"
    echo "  $0 fastapi         # Start FastAPI development server"
    echo "  $0 fastapi-stop    # Stop FastAPI development server"
    echo "  $0 fastapi-restart # Restart FastAPI development server"
    echo "  $0 fastapi-logs    # View FastAPI server logs"
    echo "  $0 fastapi-logs -f # Follow FastAPI server logs"
    echo "  $0 logs -f         # Follow logs in real-time"
    echo "  $0 stop -r         # Stop and remove container"
    echo "  $0 status          # Check container status"
    echo ""
    echo -e "${YELLOW}Individual Scripts:${NC}"
    echo "  You can also run the individual scripts directly:"
    echo "  - $SCRIPT_DIR/start-container.sh"
    echo "  - $SCRIPT_DIR/launch-windsurf.sh"
    echo "  - $SCRIPT_DIR/launch-vscode.sh"
    echo "  - $SCRIPT_DIR/enter-container.sh"
    echo "  - $SCRIPT_DIR/fastapi-server.sh"
    echo "  - $SCRIPT_DIR/view-logs.sh"
    echo "  - $SCRIPT_DIR/stop-container.sh"
}

# Function to prompt user for editor choice with timeout
prompt_editor_choice() {
    echo ""
    echo -e "${YELLOW}🚀 Choose your editor:${NC}"
    echo -e "  ${GREEN}1${NC}) VS Code (default)"
    echo -e "  ${GREEN}2${NC}) Windsurf"
    echo -e "  ${GREEN}3${NC}) Do not launch IDE"
    echo ""
    echo -e "${YELLOW}Choose [1-3] (defaults to VS Code in 15 seconds):${NC}"
    
    # Read user input with timeout
    if read -t 15 -r choice; then
        case "$choice" in
            1|"")
                echo -e "${GREEN}💻 Launching VS Code...${NC}"
                "$SCRIPT_DIR/launch-vscode.sh"
                ;;
            2)
                echo -e "${GREEN}🌪️ Launching Windsurf...${NC}"
                "$SCRIPT_DIR/launch-windsurf.sh"
                ;;
            3)
                echo -e "${GREEN}✅ Skipping IDE launch. Container and FastAPI are ready!${NC}"
                echo -e "${CYAN}📊 Development environment status:${NC}"
                echo -e "  ✅ Container: Running"
                echo -e "  ✅ FastAPI: Running on http://localhost:8000"
                echo -e "  📝 Swagger UI: http://localhost:8000/docs"
                echo ""
                echo -e "${YELLOW}🛠️ Useful commands:${NC}"
                echo -e "  ./cli.sh enter          # Enter container shell"
                echo -e "  ./cli.sh fastapi-logs   # View FastAPI logs"
                echo -e "  ./cli.sh status         # Check status"
                ;;
            *)
                echo -e "${YELLOW}⚠️ Invalid choice. Defaulting to VS Code...${NC}"
                "$SCRIPT_DIR/launch-vscode.sh"
                ;;
        esac
    else
        echo ""
        echo -e "${YELLOW}⏰ Timeout reached. Launching VS Code (default)...${NC}"
        "$SCRIPT_DIR/launch-vscode.sh"
    fi
}

show_status() {
    echo -e "${CYAN}📊 DevContainer Status${NC}"
    echo -e "${CYAN}=====================${NC}"
    echo ""
    
    # Check if Docker Compose service is running
    if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
        echo -e "Service: ${GREEN}$SERVICE_NAME${NC}"
        echo -e "Status: ${GREEN}Running ✅${NC}"
        
        # Get container info using compose
        CONTAINER_ID=$(docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE_NAME")
        if [ -n "$CONTAINER_ID" ]; then
            UPTIME=$(docker inspect --format='{{.State.Status}} ({{.State.StartedAt}})' "$CONTAINER_ID" 2>/dev/null || echo "Unknown")
            PORTS=$(docker compose -f "$COMPOSE_FILE" port "$SERVICE_NAME" 8000 2>/dev/null || echo "8000:8000")
            
            echo -e "Container ID: ${BLUE}${CONTAINER_ID:0:12}${NC}"
            echo -e "Status: ${BLUE}$UPTIME${NC}"
            echo -e "Ports: ${BLUE}$PORTS${NC}"
        fi
        
        # Check if FastAPI is running
        if curl -s http://localhost:8000/health >/dev/null 2>&1; then
            echo -e "FastAPI: ${GREEN}Running on http://localhost:8000 ✅${NC}"
        else
            echo -e "FastAPI: ${YELLOW}Not responding ⚠️${NC}"
        fi
    elif docker compose -f "$COMPOSE_FILE" ps --services | grep -q "^$SERVICE_NAME$"; then
        echo -e "Service: ${YELLOW}$SERVICE_NAME${NC}"
        echo -e "Status: ${YELLOW}Stopped 🛑${NC}"
    else
        echo -e "Service: ${RED}$SERVICE_NAME${NC}"
        echo -e "Status: ${RED}Not created ❌${NC}"
        echo ""
        echo -e "${YELLOW}💡 Tip:${NC} Run '$0 start' to create and launch the container"
    fi
    echo ""
}

# Check if no arguments provided
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Parse command
COMMAND="$1"
shift

case "$COMMAND" in
    start)
        echo -e "${GREEN}🚀 Starting DevContainer...${NC}"
        "$SCRIPT_DIR/start-container.sh" --build
        
        # Wait a moment for container to be fully ready
        echo -e "${GREEN}⏳ Waiting for container to be ready...${NC}"
        sleep 3
        
        # Automatically start FastAPI server in background
        echo -e "${GREEN}🚀 Auto-starting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" start
        
        # Prompt user for editor choice
        prompt_editor_choice
        ;;
    launch)
        echo -e "${GREEN}🌊 Launching DevContainer with Windsurf...${NC}"
        "$SCRIPT_DIR/launch-windsurf.sh"
        
        # Wait a moment for container to be fully ready
        echo -e "${GREEN}⏳ Waiting for container to be ready...${NC}"
        sleep 3
        
        # Automatically start FastAPI server in background
        echo -e "${GREEN}🚀 Auto-starting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" start
        ;;
    vscode)
        echo -e "${GREEN}💻 Launching DevContainer with VS Code...${NC}"
        "$SCRIPT_DIR/launch-vscode.sh"
        
        # Wait a moment for container to be fully ready
        echo -e "${GREEN}⏳ Waiting for container to be ready...${NC}"
        sleep 3
        
        # Automatically start FastAPI server in background
        echo -e "${GREEN}🚀 Auto-starting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" start
        ;;
    enter|exec|bash|shell)
        echo -e "${GREEN}🐳 Entering DevContainer...${NC}"
        "$SCRIPT_DIR/enter-container.sh"
        ;;
    fastapi|server|dev)
        echo -e "${GREEN}🚀 Starting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" "$@"
        ;;
    fastapi-stop)
        echo -e "${GREEN}🛑 Stopping FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" stop "$@"
        ;;
    fastapi-restart)
        echo -e "${GREEN}🔄 Restarting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" restart "$@"
        ;;
    fastapi-logs)
        echo -e "${GREEN}📋 Viewing FastAPI Server Logs...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" logs "$@"
        ;;
    logs|log)
        echo -e "${GREEN}📋 Viewing Container Logs...${NC}"
        "$SCRIPT_DIR/view-logs.sh" "$@"
        ;;
    stop|kill)
        echo -e "${GREEN}🛑 Stopping DevContainer...${NC}"
        "$SCRIPT_DIR/stop-container.sh" "$@"
        ;;
    status|info|ps)
        show_status
        ;;
    restart|reboot)
        echo -e "${GREEN}🔄 Restarting DevContainer...${NC}"
        "$SCRIPT_DIR/stop-container.sh" -r
        sleep 2
        
        # Build and start the devcontainer using Docker Compose
        echo -e "${GREEN}🔨 Building and starting devcontainer...${NC}"
        docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d --build
        
        # Wait a moment for container to be fully ready
        echo -e "${GREEN}⏳ Waiting for container to be ready...${NC}"
        sleep 3
        
        # Automatically start FastAPI server in background
        echo -e "${GREEN}🚀 Auto-starting FastAPI Server...${NC}"
        "$SCRIPT_DIR/fastapi-server.sh" start
        
        # Prompt user for editor choice
        prompt_editor_choice
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        echo ""
        echo "Use '$0 help' to see available commands"
        exit 1
        ;;
esac
