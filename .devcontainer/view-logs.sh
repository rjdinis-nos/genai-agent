#!/bin/bash

# Script to view logs from the devcontainer
# Usage: ./view-logs.sh [options]
# Options:
#   -f, --follow    Follow log output (like tail -f)
#   -n, --lines N   Show last N lines (default: 50)
#   -h, --help      Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="app"
LINES=50
FOLLOW=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "View logs from the devcontainer"
            echo ""
            echo "Options:"
            echo "  -f, --follow    Follow log output (like tail -f)"
            echo "  -n, --lines N   Show last N lines (default: 50)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Show last 50 lines"
            echo "  $0 -n 100       # Show last 100 lines"
            echo "  $0 -f           # Follow logs in real-time"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "📋 Viewing DevContainer Logs: $SERVICE_NAME"
echo "==========================================="

# Check if service exists
if ! docker compose -f "$COMPOSE_FILE" ps --services | grep -q "^$SERVICE_NAME$"; then
    echo "❌ Service '$SERVICE_NAME' does not exist."
    echo "   Create it first with: ./.devcontainer/cli.sh start"
    exit 1
fi

# Check if service is running
if ! docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "^$SERVICE_NAME$"; then
    echo "⚠️ Service '$SERVICE_NAME' is not running (showing historical logs)"
fi

echo "📊 Showing last $LINES lines..."
if [ "$FOLLOW" = true ]; then
    echo "   Following logs (Press Ctrl+C to stop)"
fi
echo ""

# View logs using Docker Compose
if [ "$FOLLOW" = true ]; then
    docker compose -f "$COMPOSE_FILE" logs -f --tail="$LINES" "$SERVICE_NAME"
else
    docker compose -f "$COMPOSE_FILE" logs --tail="$LINES" "$SERVICE_NAME"
fi
