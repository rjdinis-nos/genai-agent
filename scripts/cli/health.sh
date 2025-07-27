#!/bin/bash

# GenAI Agent - Simple Health Check CLI (One-liner)
# Usage: ./health.sh [host] [port]

HOST="${1:-${GENAI_HOST:-localhost}}"
PORT="${2:-${GENAI_PORT:-8000}}"
PROTOCOL="${GENAI_PROTOCOL:-http}"

echo "🏥 Checking health of GenAI Agent API at $PROTOCOL://$HOST:$PORT"

if curl -s -f "$PROTOCOL://$HOST:$PORT/health" > /dev/null; then
    echo "✅ API is healthy"
    curl -s "$PROTOCOL://$HOST:$PORT/health" | jq -r '"Status: " + .status + " | Version: " + .version + " | Dependencies: Downloads=" + (.dependencies.downloads_directory | tostring) + ", Gemini=" + (.dependencies.google_gemini_api | tostring)' 2>/dev/null || echo "📊 Health data available at $PROTOCOL://$HOST:$PORT/health"
else
    echo "❌ API health check failed"
    exit 1
fi
