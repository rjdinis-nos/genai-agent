#!/bin/bash

# GenAI Agent - File Download CLI Tool
# This script downloads files using the FastAPI /download endpoint

set -e  # Exit on any error

# Configuration
DEFAULT_HOST="localhost"
DEFAULT_PORT="8000"
DEFAULT_PROTOCOL="http"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <URL>"
    echo ""
    echo "Download files using the GenAI Agent /download endpoint"
    echo ""
    echo "Arguments:"
    echo "  URL                    The URL of the file to download"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST        API host (default: $DEFAULT_HOST)"
    echo "  -p, --port PORT        API port (default: $DEFAULT_PORT)"
    echo "  -s, --secure           Use HTTPS instead of HTTP"
    echo "  -o, --output FILE      Output filename (default: extracted from URL)"
    echo "  -d, --directory DIR    Output directory (default: current directory)"
    echo "  -v, --verbose          Verbose output"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 https://example.com/document.pdf"
    echo "  $0 -o my-file.pdf https://example.com/document.pdf"
    echo "  $0 -h api.example.com -p 443 -s https://example.com/document.pdf"
    echo "  $0 -d downloads/ -v https://example.com/document.pdf"
}

# Function to log messages
log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# Function to extract filename from URL
extract_filename() {
    local url="$1"
    local filename=$(basename "$url")
    
    # If no extension, add .bin
    if [[ "$filename" != *.* ]]; then
        filename="${filename}.bin"
    fi
    
    echo "$filename"
}

# Function to validate URL
validate_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        log "ERROR" "Invalid URL format. URL must start with http:// or https://"
        return 1
    fi
    
    return 0
}

# Function to check if API is running
check_api_health() {
    local base_url="$1"
    
    if [ "$VERBOSE" = true ]; then
        log "INFO" "Checking API health at $base_url"
    fi
    
    local health_response=$(curl -s -w "%{http_code}" -o /dev/null "$base_url/docs" 2>/dev/null || echo "000")
    
    if [ "$health_response" != "200" ]; then
        log "ERROR" "API is not accessible at $base_url"
        log "ERROR" "Please ensure the GenAI Agent server is running"
        return 1
    fi
    
    if [ "$VERBOSE" = true ]; then
        log "SUCCESS" "API is accessible"
    fi
    
    return 0
}

# Function to download file
download_file() {
    local url="$1"
    local output_file="$2"
    local base_url="$3"
    
    log "INFO" "Downloading file from: $url"
    log "INFO" "Output file: $output_file"
    
    # Prepare the API request
    local api_endpoint="$base_url/download"
    local json_payload=$(jq -n --arg url "$url" '{url: $url}')
    
    if [ "$VERBOSE" = true ]; then
        log "INFO" "API endpoint: $api_endpoint"
        log "INFO" "Request payload: $json_payload"
    fi
    
    # Make the API request
    local response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/octet-stream" \
        -d "$json_payload" \
        -o "$output_file" \
        "$api_endpoint" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [ "$VERBOSE" = true ]; then
        log "INFO" "HTTP response code: $http_code"
    fi
    
    case $http_code in
        200)
            log "SUCCESS" "File downloaded successfully: $output_file"
            
            # Show file info
            if [ -f "$output_file" ]; then
                local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "unknown")
                log "INFO" "File size: $file_size bytes"
            fi
            ;;
        400)
            log "ERROR" "Bad request - Invalid URL or parameters"
            rm -f "$output_file" 2>/dev/null
            return 1
            ;;
        404)
            log "ERROR" "File not found at the specified URL"
            rm -f "$output_file" 2>/dev/null
            return 1
            ;;
        422)
            log "ERROR" "Validation error - Check URL format"
            rm -f "$output_file" 2>/dev/null
            return 1
            ;;
        500)
            log "ERROR" "Server error - Please try again later"
            rm -f "$output_file" 2>/dev/null
            return 1
            ;;
        *)
            log "ERROR" "Unexpected response code: $http_code"
            rm -f "$output_file" 2>/dev/null
            return 1
            ;;
    esac
    
    return 0
}

# Main function
main() {
    # Default values
    local host="$DEFAULT_HOST"
    local port="$DEFAULT_PORT"
    local protocol="$DEFAULT_PROTOCOL"
    local output_file=""
    local output_dir="."
    local url=""
    local VERBOSE=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                host="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -s|--secure)
                protocol="https"
                shift
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -d|--directory)
                output_dir="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$url" ]; then
                    url="$1"
                else
                    log "ERROR" "Multiple URLs provided. Only one URL is allowed."
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$url" ]; then
        log "ERROR" "URL is required"
        show_usage
        exit 1
    fi
    
    # Validate URL format
    if ! validate_url "$url"; then
        exit 1
    fi
    
    # Set output filename if not provided
    if [ -z "$output_file" ]; then
        output_file=$(extract_filename "$url")
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        log "INFO" "Created output directory: $output_dir"
    fi
    
    # Full output path
    local full_output_path="$output_dir/$output_file"
    
    # Check if output file already exists
    if [ -f "$full_output_path" ]; then
        log "WARNING" "Output file already exists: $full_output_path"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Download cancelled"
            exit 0
        fi
    fi
    
    # Build base URL
    local base_url="$protocol://$host:$port"
    
    # Check API health
    if ! check_api_health "$base_url"; then
        exit 1
    fi
    
    # Download the file
    if download_file "$url" "$full_output_path" "$base_url"; then
        log "SUCCESS" "Download completed successfully!"
        exit 0
    else
        log "ERROR" "Download failed"
        exit 1
    fi
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log "ERROR" "jq is required but not installed"
    exit 1
fi

# Run main function
main "$@"
