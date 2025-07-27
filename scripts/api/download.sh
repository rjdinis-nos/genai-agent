#!/bin/bash

# GenAI Agent - Simple File Download CLI (One-liner)
# Usage: ./download.sh <URL> [output_file]

URL="$1"
OUTPUT="${2:-$(basename "$URL")}"
HOST="${GENAI_HOST:-localhost}"
PORT="${GENAI_PORT:-8000}"

if [ -z "$URL" ]; then
    echo "Usage: $0 <URL> [output_file]"
    echo "Example: $0 https://example.com/document.pdf my-document.pdf"
    exit 1
fi

echo "📥 Downloading: $URL"
curl -s -X POST "http://$HOST:$PORT/download" \
    -H "Content-Type: application/json" \
    -H "Accept: application/octet-stream" \
    -d "{\"url\":\"$URL\"}" \
    -o "$OUTPUT" && echo "✅ Downloaded: $OUTPUT" || echo "❌ Download failed"
