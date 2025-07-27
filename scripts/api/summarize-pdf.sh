#!/bin/bash

# GenAI Agent - PDF Summarization CLI Tool
# Usage: ./summarize-pdf.sh <pdf_file_path> [server_url]

set -e

# Default configuration
DEFAULT_SERVER_URL="http://localhost:8000"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${BLUE}GenAI Agent - PDF Summarization CLI Tool${NC}"
    echo ""
    echo "Usage: $0 <pdf_file_path> [server_url]"
    echo ""
    echo "Arguments:"
    echo "  pdf_file_path    Path to the PDF file to summarize (required)"
    echo "  server_url       GenAI Agent server URL (optional, default: $DEFAULT_SERVER_URL)"
    echo ""
    echo "Examples:"
    echo "  $0 document.pdf"
    echo "  $0 /path/to/document.pdf http://localhost:8000"
    echo "  $0 report.pdf https://genai-agent.example.com"
    echo ""
    echo "Environment Variables:"
    echo "  GENAI_SERVER_URL    Override default server URL"
    echo "  GENAI_TIMEOUT       Request timeout in seconds (default: 60)"
    echo ""
}

# Function to check if file exists and is readable
check_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Error: File '$file_path' does not exist${NC}" >&2
        exit 1
    fi
    
    if [[ ! -r "$file_path" ]]; then
        echo -e "${RED}Error: File '$file_path' is not readable${NC}" >&2
        exit 1
    fi
    
    # Check if it's a PDF file (basic check)
    if ! file "$file_path" | grep -q "PDF"; then
        echo -e "${YELLOW}Warning: File '$file_path' may not be a PDF file${NC}" >&2
    fi
}

# Function to check if server is running
check_server() {
    local server_url="$1"
    local timeout="${GENAI_TIMEOUT:-10}"
    
    echo -e "${BLUE}Checking server availability at $server_url...${NC}" >&2
    
    if ! curl -s --max-time "$timeout" "$server_url/docs" > /dev/null 2>&1; then
        echo -e "${RED}Error: GenAI Agent server is not accessible at $server_url${NC}" >&2
        echo -e "${YELLOW}Make sure the server is running:${NC}" >&2
        echo -e "  ${YELLOW}cd $(dirname "$SCRIPT_DIR") && uv run uvicorn src.main:app --reload${NC}" >&2
        echo -e "  ${YELLOW}or use Docker: ./scripts/run.sh${NC}" >&2
        exit 1
    fi
    
    echo -e "${GREEN}Server is accessible${NC}" >&2
}

# Function to summarize PDF
summarize_pdf() {
    local pdf_file="$1"
    local server_url="$2"
    local timeout="${GENAI_TIMEOUT:-60}"
    
    echo -e "${BLUE}Summarizing PDF: $(basename "$pdf_file")...${NC}" >&2
    
    # Make the API request
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" \
        --max-time "$timeout" \
        -X POST \
        -F "file=@$pdf_file" \
        "$server_url/summarize" 2>/dev/null)
    
    # Extract HTTP status code (last line)
    http_code=$(echo "$response" | tail -n1)
    # Extract response body (all lines except last)
    response_body=$(echo "$response" | head -n -1)
    
    case "$http_code" in
        200)
            echo -e "${GREEN}✓ Summary generated successfully${NC}" >&2
            echo "$response_body"
            ;;
        400)
            echo -e "${RED}Error: Bad request - $response_body${NC}" >&2
            exit 1
            ;;
        422)
            echo -e "${RED}Error: Invalid file format - $response_body${NC}" >&2
            exit 1
            ;;
        500)
            echo -e "${RED}Error: Server error - $response_body${NC}" >&2
            exit 1
            ;;
        *)
            echo -e "${RED}Error: HTTP $http_code - $response_body${NC}" >&2
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check arguments
    if [[ $# -lt 1 ]]; then
        echo -e "${RED}Error: PDF file path is required${NC}" >&2
        echo ""
        usage
        exit 1
    fi
    
    local pdf_file="$1"
    local server_url="${2:-${GENAI_SERVER_URL:-$DEFAULT_SERVER_URL}}"
    
    # Validate inputs
    check_file "$pdf_file"
    check_server "$server_url"
    
    # Summarize the PDF
    summarize_pdf "$pdf_file" "$server_url"
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}" >&2
    exit 1
fi

if ! command -v file &> /dev/null; then
    echo -e "${RED}Error: file command is required but not installed${NC}" >&2
    exit 1
fi

# Run main function
main "$@"
