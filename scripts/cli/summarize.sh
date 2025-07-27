#!/bin/bash

# GenAI Agent - Simple PDF Summarization One-liner
# Usage: ./summarize.sh <pdf_file_path>

PDF_FILE="$1"
SERVER_URL="${2:-http://localhost:8000}"

if [[ -z "$PDF_FILE" ]]; then
    echo "Usage: $0 <pdf_file_path> [server_url]"
    echo "Example: $0 document.pdf"
    exit 1
fi

if [[ ! -f "$PDF_FILE" ]]; then
    echo "Error: File '$PDF_FILE' does not exist"
    exit 1
fi

curl -s -X POST -F "file=@$PDF_FILE" "$SERVER_URL/summarize" | jq -r '.summary // .'
