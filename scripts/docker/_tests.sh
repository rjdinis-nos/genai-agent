#!/bin/bash

# Docker Test Runner - Simplified wrapper for running tests
# Provides an easy-to-use interface for various test scenarios

set -e  # Exit on any error

# Source global variables and utility functions
source "$(dirname "$0")/_utils.sh"

# Default values
DEFAULT_ENV="test"
DEFAULT_VERBOSE="false"
DEFAULT_COVERAGE="false"
DEFAULT_WATCH="false"
DEFAULT_FILTER=""

# Clean test artifacts
clean_test_artifacts() {
    echo -e "${YELLOW}🧹 Cleaning test artifacts...${NC}"
    
    # Remove Python cache
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    
    # Remove pytest cache
    rm -rf .pytest_cache 2>/dev/null || true
    
    # Remove coverage files
    rm -f .coverage* 2>/dev/null || true
    rm -rf htmlcov 2>/dev/null || true
    
    echo -e "${GREEN}✅ Test artifacts cleaned${NC}"
}

# Build test command based on options
build_test_command() {
    local test_cmd="uv run pytest"
    
    # Add verbose flag
    if [ "$verbose" = "true" ]; then
        test_cmd="$test_cmd -v"
    fi
    
    # Add coverage
    if [ "$coverage" = "true" ]; then
        test_cmd="$test_cmd --cov=src --cov-report=html --cov-report=term-missing"
    fi
    
    # Add filter
    if [ -n "$filter" ]; then
        test_cmd="$test_cmd -k \"$filter\""
    fi
    
    # Add quick mode (skip slow tests)
    if [ "$quick" = "true" ]; then
        test_cmd="$test_cmd -m \"not slow\""
    fi
    
    # Add unit tests only
    if [ "$unit" = "true" ]; then
        test_cmd="$test_cmd tests/test_*.py"
    fi
    
    # Add integration tests only
    if [ "$integration" = "true" ]; then
        test_cmd="$test_cmd tests/integration/"
    fi
    
    # Add benchmark tests
    if [ "$benchmark" = "true" ]; then
        test_cmd="$test_cmd --benchmark-only"
    fi
    
    echo "$test_cmd"
}

# Run tests in Docker
run_docker_tests() {
    local environment="$1"
    local compose_file="$2"
    local env_file="$3"
    local test_command="$4"
    local no_build="$5"
    
    echo ""
    echo -e "${BLUE}🐳 Running tests in Docker${NC}"
    echo "=========================="
    echo -e "${GREEN}🌍 Environment: ${environment}${NC}"
    echo -e "${CYAN}🧪 Test command: ${test_command}${NC}"
    echo ""
    
    # Build image if needed
    if [ "$no_build" != "true" ]; then
        if ! docker image inspect "${PROJECT_NAME}:latest" > /dev/null 2>&1; then
            echo -e "${BLUE}📦 Building Docker image...${NC}"
            "$SCRIPT_DIR/_build.sh" --env "$environment" "latest" > /dev/null
        fi
    fi
    
    # Run tests with custom command
    docker compose -f "$compose_file" --env-file "$env_file" run --rm app bash -c "$test_command"
    local exit_code=$?
    
    # Cleanup
    docker compose -f "$compose_file" --env-file "$env_file" down > /dev/null 2>&1
    
    return $exit_code
}

# Watch mode implementation
run_watch_mode() {
    local environment="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}👀 Starting watch mode...${NC}"
    echo "Press Ctrl+C to stop watching"
    echo ""
    
    while true; do
        echo -e "${BLUE}🔄 Running tests...${NC}"
        if run_docker_tests "$environment" "$test_command" "true"; then
            echo -e "${GREEN}✅ Tests passed - waiting for changes...${NC}"
        else
            echo -e "${RED}❌ Tests failed - waiting for changes...${NC}"
        fi
        
        echo ""
        echo -e "${YELLOW}Watching for file changes (press Ctrl+C to stop)...${NC}"
        
        # Simple file watching using find and stat
        local last_change=$(find src tests -type f -name "*.py" -exec stat -c %Y {} \; | sort -n | tail -1)
        
        while true; do
            sleep 2
            local current_change=$(find src tests -type f -name "*.py" -exec stat -c %Y {} \; | sort -n | tail -1)
            if [ "$current_change" != "$last_change" ]; then
                echo -e "${CYAN}📝 File changes detected!${NC}"
                break
            fi
        done
    done
}

# Show usage information
show_usage() {
    echo -e "${BLUE}🧪 Docker Test Runner${NC}"
    echo "====================="
    echo ""
    echo "Usage: $0 [OPTIONS] [TEST_ARGS]"
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo "  -e, --env ENV          Environment: dev, prod, test (default: test)"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -c, --coverage         Run tests with coverage report"
    echo "  -w, --watch            Watch mode (rebuild and rerun on changes)"
    echo "  -f, --filter PATTERN   Run only tests matching pattern"
    echo "  -q, --quick            Quick test run (skip slow tests)"
    echo "  -u, --unit             Run only unit tests"
    echo "  -i, --integration      Run only integration tests"
    echo "  -b, --benchmark        Run benchmark tests"
    echo "  --clean                Clean test artifacts before running"
    echo "  --no-build             Skip Docker image build"
    echo "  -h, --help             Show this help"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0                              # Run all tests"
    echo "  $0 --verbose --coverage         # Verbose run with coverage"
    echo "  $0 --filter test_api            # Run tests matching 'test_api'"
    echo "  $0 --unit --quick               # Quick unit tests only"
    echo "  $0 --env dev --watch            # Watch mode in dev environment"
    echo "  $0 --benchmark                  # Run performance benchmarks"
    echo "  $0 --clean --coverage           # Clean run with coverage"
    echo ""
    echo -e "${CYAN}Test Arguments:${NC}"
    echo "  Any additional arguments are passed directly to pytest"
    echo "  Example: $0 tests/test_api.py::test_health -v"
}

parse_args() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                environment="${2:-test}"
                if ! validate_environment "$environment"; then
                    exit 1
                fi
                shift 2
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -c|--coverage)
                coverage="true"
                shift
                ;;
            -w|--watch)
                watch="true"
                shift
                ;;
            -f|--filter)
                filter="$2"
                shift 2
                ;;
            -q|--quick)
                quick="true"
                shift
                ;;
            -u|--unit)
                unit="true"
                shift
                ;;
            -i|--integration)
                integration="true"
                shift
                ;;
            -b|--benchmark)
                benchmark="true"
                shift
                ;;
            --clean)
                clean="true"
                shift
                ;;
            --no-build)
                no_build="true"
                shift
                ;;
            -h|--help)
                show_usage
                return 0
                ;;
            --)
                shift
                test_args+=("$@")
                break
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use --help for usage information"
                return 1
                ;;
            *)
                test_args+=("$1")
                shift
                ;;
        esac
    done
}

# Main function
main() {
    local environment="$DEFAULT_ENV"
    local verbose="$DEFAULT_VERBOSE"
    local coverage="$DEFAULT_COVERAGE"
    local watch="$DEFAULT_WATCH"
    local filter="$DEFAULT_FILTER"
    local quick="false"
    local unit="false"
    local integration="false"
    local benchmark="false"
    local clean="false"
    local no_build="false"
    local test_args=()

    # Check for help or no arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    parse_args "$@"

    # Get project name from pyproject.toml
    project_name=$(get_project_name)
    echo "✅ Project name: $project_name"

    # Get env file
    env_file=$(get_env_file "$environment")
    echo "✅ Env file: $(realpath -s -e $env_file)"

    # Get compose file
    compose_file=$(get_compose_file "$environment")
    echo "✅ Compose file: $(realpath -s -e $compose_file)"
    
    # Clean artifacts if requested
    if [ "$clean" = "true" ]; then
        clean_test_artifacts
    fi
    
    # Build test command
    local test_command
    test_command=$(build_test_command)
    
    # Add any additional test arguments
    if [ ${#test_args[@]} -gt 0 ]; then
        test_command="$test_command ${test_args[*]}"
    fi
    
    # Run tests
    if [ "$watch" = "true" ]; then
        run_watch_mode "$environment" "$test_command"
    else
        if run_docker_tests "$environment" "$compose_file" "$env_file" "$test_command" "$no_build"; then
            echo -e "${GREEN}🎉 All tests passed!${NC}"
            
            # Show coverage report location if coverage was enabled
            if [ "$coverage" = "true" ]; then
                echo -e "${CYAN}📊 Coverage report generated in htmlcov/index.html${NC}"
            fi
        else
            echo -e "${RED}💥 Tests failed!${NC}"
            exit 1
        fi
    fi
}

# Run main function
main "$@"
