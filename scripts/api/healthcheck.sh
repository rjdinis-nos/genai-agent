#!/bin/bash

# GenAI Agent - Health Check CLI Tool
# This script performs health checks on the GenAI Agent API

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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Perform health checks on the GenAI Agent API"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST        API host (default: $DEFAULT_HOST)"
    echo "  -p, --port PORT        API port (default: $DEFAULT_PORT)"
    echo "  -s, --secure           Use HTTPS instead of HTTP"
    echo "  -v, --verbose          Verbose output"
    echo "  -j, --json             Output raw JSON response"
    echo "  -w, --wait SECONDS     Wait time between retries (default: 5)"
    echo "  -r, --retries COUNT    Number of retries (default: 3)"
    echo "  --timeout SECONDS      Request timeout (default: 10)"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Basic health check"
    echo "  $0 -v                                 # Verbose health check"
    echo "  $0 -h api.example.com -p 443 -s      # Remote HTTPS API"
    echo "  $0 -j                                 # JSON output"
    echo "  $0 -r 5 -w 10                        # 5 retries with 10s wait"
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
        "DETAIL")
            if [ "$VERBOSE" = true ]; then
                echo -e "${CYAN}[DETAIL]${NC} $message"
            fi
            ;;
    esac
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ $bytes -gt 1024 ] && [ $unit -lt 4 ]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Function to perform health check
perform_health_check() {
    local base_url="$1"
    local attempt="$2"
    local max_attempts="$3"
    
    log "INFO" "Performing health check (attempt $attempt/$max_attempts)"
    log "DETAIL" "URL: $base_url/health"
    
    # Make the health check request
    local response=$(curl -s -w "%{http_code}" \
        --max-time "$TIMEOUT" \
        -H "Accept: application/json" \
        -o /tmp/healthcheck_response.json \
        "$base_url/health" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    log "DETAIL" "HTTP response code: $http_code"
    
    case $http_code in
        200)
            log "SUCCESS" "API is healthy"
            
            if [ "$JSON_OUTPUT" = true ]; then
                cat /tmp/healthcheck_response.json
                return 0
            fi
            
            # Parse and display health information
            if command -v jq &> /dev/null; then
                parse_health_response
            else
                log "WARNING" "jq not found - displaying raw JSON response"
                cat /tmp/healthcheck_response.json
            fi
            return 0
            ;;
        000)
            log "ERROR" "Failed to connect to API at $base_url"
            return 1
            ;;
        404)
            log "ERROR" "Health endpoint not found - API may be running an older version"
            return 1
            ;;
        500)
            log "ERROR" "API returned internal server error"
            return 1
            ;;
        *)
            log "ERROR" "Unexpected response code: $http_code"
            return 1
            ;;
    esac
}

# Function to parse health response
parse_health_response() {
    local response_file="/tmp/healthcheck_response.json"
    
    if [ ! -f "$response_file" ]; then
        log "ERROR" "Health response file not found"
        return 1
    fi
    
    # Extract basic information
    local status=$(jq -r '.status // "unknown"' "$response_file")
    local version=$(jq -r '.version // "unknown"' "$response_file")
    local timestamp=$(jq -r '.timestamp // "unknown"' "$response_file")
    
    echo ""
    echo -e "${GREEN}🏥 Health Check Results${NC}"
    echo "=========================="
    echo -e "Status: ${GREEN}$status${NC}"
    echo -e "Version: $version"
    echo -e "Timestamp: $timestamp"
    
    # System information
    if jq -e '.system' "$response_file" > /dev/null; then
        echo ""
        echo -e "${BLUE}💻 System Information${NC}"
        echo "----------------------"
        
        local python_version=$(jq -r '.system.python_version // "unknown"' "$response_file")
        echo -e "Python Version: $python_version"
        
        # Memory information
        if jq -e '.system.memory_usage' "$response_file" > /dev/null; then
            local memory_total=$(jq -r '.system.memory_usage.total // "N/A"' "$response_file")
            local memory_available=$(jq -r '.system.memory_usage.available // "N/A"' "$response_file")
            local memory_used=$(jq -r '.system.memory_usage.used // "N/A"' "$response_file")
            local memory_percent=$(jq -r '.system.memory_usage.percent // "N/A"' "$response_file")
            
            echo -e "Memory: ${memory_available} available / ${memory_total} total (${memory_used} used, ${memory_percent} used)"
        fi
        
        # Disk information
        if jq -e '.system.disk_usage' "$response_file" > /dev/null; then
            local disk_total=$(jq -r '.system.disk_usage.total // "N/A"' "$response_file")
            local disk_free=$(jq -r '.system.disk_usage.free // "N/A"' "$response_file")
            local disk_used=$(jq -r '.system.disk_usage.used // "N/A"' "$response_file")
            local disk_percent=$(jq -r '.system.disk_usage.percent // "N/A"' "$response_file")
            
            echo -e "Disk: ${disk_free} free / ${disk_total} total (${disk_used} used, ${disk_percent} used)"
        fi
    fi
    
    # Dependencies
    if jq -e '.dependencies' "$response_file" > /dev/null; then
        echo ""
        echo -e "${YELLOW}🔧 Dependencies${NC}"
        echo "----------------"
        
        local downloads_dir=$(jq -r '.dependencies.downloads_directory // false' "$response_file")
        local gemini_api=$(jq -r '.dependencies.google_gemini_api // false' "$response_file")
        
        if [ "$downloads_dir" = "true" ]; then
            echo -e "Downloads Directory: ${GREEN}✅ Available${NC}"
        else
            echo -e "Downloads Directory: ${RED}❌ Not Available${NC}"
        fi
        
        if [ "$gemini_api" = "true" ]; then
            echo -e "Google Gemini API: ${GREEN}✅ Configured${NC}"
        else
            echo -e "Google Gemini API: ${YELLOW}⚠️ Not Configured${NC}"
        fi
    fi
    
    # Endpoints
    if jq -e '.endpoints' "$response_file" > /dev/null; then
        echo ""
        echo -e "${CYAN}🌐 Available Endpoints${NC}"
        echo "----------------------"
        
        jq -r '.endpoints | to_entries[] | "• \(.key): \(.value)"' "$response_file"
    fi
    
    echo ""
}

# Function to check basic connectivity
check_basic_connectivity() {
    local base_url="$1"
    
    log "INFO" "Checking basic connectivity to $base_url"
    
    # Try to connect to root endpoint
    local response=$(curl -s -w "%{http_code}" \
        --max-time 5 \
        -o /dev/null \
        "$base_url/" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        log "SUCCESS" "Basic connectivity confirmed"
        return 0
    else
        log "WARNING" "Basic connectivity check failed (HTTP: $http_code)"
        return 1
    fi
}

# Main function
main() {
    # Default values
    local host="$DEFAULT_HOST"
    local port="$DEFAULT_PORT"
    local protocol="$DEFAULT_PROTOCOL"
    local VERBOSE=false
    local JSON_OUTPUT=false
    local WAIT_TIME=5
    local MAX_RETRIES=3
    local TIMEOUT=10
    
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
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            -w|--wait)
                WAIT_TIME="$2"
                shift 2
                ;;
            -r|--retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
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
                log "ERROR" "Unexpected argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Build base URL
    local base_url="$protocol://$host:$port"
    
    if [ "$JSON_OUTPUT" != true ]; then
        echo -e "${GREEN}🏥 GenAI Agent Health Check${NC}"
        echo "============================"
        echo -e "Target: $base_url"
        echo -e "Timeout: ${TIMEOUT}s"
        echo -e "Retries: $MAX_RETRIES"
        echo ""
    fi
    
    # Check basic connectivity first
    if ! check_basic_connectivity "$base_url"; then
        log "WARNING" "Basic connectivity failed, but continuing with health check..."
    fi
    
    # Perform health check with retries
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        if perform_health_check "$base_url" "$attempt" "$MAX_RETRIES"; then
            # Cleanup
            rm -f /tmp/healthcheck_response.json
            exit 0
        fi
        
        if [ $attempt -lt $MAX_RETRIES ]; then
            log "INFO" "Waiting ${WAIT_TIME}s before retry..."
            sleep "$WAIT_TIME"
        fi
        
        attempt=$((attempt + 1))
    done
    
    # All attempts failed
    log "ERROR" "Health check failed after $MAX_RETRIES attempts"
    
    # Cleanup
    rm -f /tmp/healthcheck_response.json
    exit 1
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed"
    exit 1
fi

# Run main function
main "$@"
