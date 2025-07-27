#!/bin/bash

# Script to manage the FastAPI development server inside the devcontainer
# Usage: ./fastapi-server.sh [command] [options]
# Commands:
#   start           Start the FastAPI server (default)
#   stop            Stop the FastAPI server
#   restart         Restart the FastAPI server
#   logs            View FastAPI server logs
# Options:
#   --host HOST     Host to bind to (default: 0.0.0.0)
#   --port PORT     Port to bind to (default: 8000)
#   --no-reload     Disable auto-reload
#   -h, --help      Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"
HOST="0.0.0.0"
PORT="8000"
RELOAD="--reload"
COMMAND="start"

# Parse command line arguments
# First argument might be a command
if [[ $# -gt 0 ]] && [[ "$1" =~ ^(start|stop|restart|logs)$ ]]; then
    COMMAND="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --no-reload)
            RELOAD=""
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [command] [options]"
            echo "Manage the FastAPI development server inside the devcontainer"
            echo ""
            echo "Commands:"
            echo "  start           Start the FastAPI server (default)"
            echo "  stop            Stop the FastAPI server"
            echo "  restart         Restart the FastAPI server"
            echo "  logs            View FastAPI server logs"
            echo ""
            echo "Options:"
            echo "  --host HOST     Host to bind to (default: 0.0.0.0)"
            echo "  --port PORT     Port to bind to (default: 8000)"
            echo "  --no-reload     Disable auto-reload"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 start                    # Start with default settings"
            echo "  $0 start --port 8080        # Start on port 8080"
            echo "  $0 start --no-reload        # Start without auto-reload"
            echo "  $0 stop                     # Stop the FastAPI server"
            echo "  $0 restart                  # Restart the FastAPI server"
            echo "  $0 logs                     # View FastAPI server logs"
            echo "  $0 logs -f                  # Follow FastAPI server logs"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to check if FastAPI server is running
check_fastapi_running() {
    if docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" pgrep -f "uvicorn.*backend.main:app" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to start FastAPI server
start_fastapi() {
    echo "🚀 Starting FastAPI Development Server"
    echo "======================================"
    
    # Check if service is running
    if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
        echo "❌ Service '$SERVICE_NAME' is not running."
        echo "   Start it first with: ./.devcontainer/cli.sh start"
        exit 1
    fi
    
    # Check if FastAPI is already running
    if check_fastapi_running; then
        echo "⚠️  FastAPI server is already running."
        echo "   Use 'stop' to stop it first, or 'restart' to restart it."
        exit 1
    fi
    
    echo "📋 Server Configuration:"
    echo "   - Host: $HOST"
    echo "   - Port: $PORT"
    echo "   - Auto-reload: $([ -n "$RELOAD" ] && echo "Enabled" || echo "Disabled")"
    echo "   - Server URL: http://localhost:$PORT"
    echo ""
    
    echo "🔧 Starting FastAPI server in background..."
    echo "   Use 'fastapi-stop' to stop the server"
    echo "   Use 'logs' to view server logs"
    echo ""
    
    # Start the FastAPI server in background with proper logging
    docker compose -f "$COMPOSE_FILE" exec -d "$SERVICE_NAME" bash -c "exec uv run uvicorn backend.main:app --host $HOST --port $PORT $RELOAD > >(tee -a /tmp/fastapi.log) 2>&1"
    
    # Wait a moment and check if it started successfully
    sleep 3
    if check_fastapi_running; then
        echo "✅ FastAPI server started successfully in background."
        echo "   Server URL: http://localhost:$PORT"
        echo "   View logs with: ./cli.sh logs"
    else
        echo "❌ Failed to start FastAPI server. Check logs for details."
        exit 1
    fi
}

# Function to stop FastAPI server
stop_fastapi() {
    echo "🛑 Stopping FastAPI Development Server"
    echo "====================================="
    
    # Check if service is running
    if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
        echo "❌ Service '$SERVICE_NAME' is not running."
        exit 1
    fi
    
    # Check if FastAPI is running
    if ! check_fastapi_running; then
        echo "ℹ️  FastAPI server is not running."
        exit 0
    fi
    
    echo "🔧 Stopping FastAPI server..."
    
    # Kill uvicorn processes
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" pkill -f "uvicorn.*backend.main:app" || true
    
    # Wait a moment and check if it's stopped
    sleep 2
    if ! check_fastapi_running; then
        echo "✅ FastAPI server stopped successfully."
    else
        echo "⚠️  FastAPI server may still be running. You might need to restart the container."
    fi
}

# Function to restart FastAPI server
restart_fastapi() {
    echo "🔄 Restarting FastAPI Development Server"
    echo "======================================="
    
    # Stop first if running
    if check_fastapi_running; then
        echo "🛑 Stopping current FastAPI server..."
        docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" pkill -f "uvicorn.*backend.main:app" || true
        sleep 2
    fi
    
    # Clear previous log file
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" rm -f /tmp/fastapi.log || true
    
    # Start the server in background
    echo "🚀 Starting FastAPI server in background..."
    echo "   Use 'fastapi-stop' to stop the server"
    echo "   Use 'logs' to view server logs"
    echo ""
    
    # Start the FastAPI server in background with proper logging
    docker compose -f "$COMPOSE_FILE" exec -d "$SERVICE_NAME" bash -c "exec uv run uvicorn backend.main:app --host $HOST --port $PORT $RELOAD > >(tee -a /tmp/fastapi.log) 2>&1"
    
    # Wait a moment and check if it started successfully
    sleep 3
    if check_fastapi_running; then
        echo "✅ FastAPI server restarted successfully in background."
        echo "   Server URL: http://localhost:$PORT"
        echo "   View logs with: ./cli.sh logs"
    else
        echo "❌ Failed to restart FastAPI server. Check logs for details."
        exit 1
    fi
}

# Function to view FastAPI server logs
view_fastapi_logs() {
    echo "📋 FastAPI Server Logs"
    echo "====================="
    
    # Check if service is running
    if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
        echo "❌ Service '$SERVICE_NAME' is not running."
        exit 1
    fi
    
    # Check if log file exists
    if ! docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" test -f /tmp/fastapi.log >/dev/null 2>&1; then
        echo "ℹ️  No FastAPI logs found. Server may not have been started yet."
        echo "   Start the server with: ./cli.sh fastapi"
        exit 0
    fi
    
    echo "🔍 Showing FastAPI server logs..."
    echo "   Press Ctrl+C to exit log viewing"
    echo ""
    
    # Show logs with tail, pass through any additional arguments (like -f for follow)
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" tail "$@" /tmp/fastapi.log
}

# Execute the appropriate command
case "$COMMAND" in
    start)
        start_fastapi
        ;;
    stop)
        stop_fastapi
        ;;
    restart)
        restart_fastapi
        ;;
    logs)
        view_fastapi_logs "$@"
        ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        echo "Use -h or --help for usage information"
        exit 1
        ;;
esac
