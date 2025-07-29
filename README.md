# GenAI Agent

[![CI/CD Pipeline](https://github.com/rjdinis-nos/genai-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/ci.yml)
[![PR Validation](https://github.com/rjdinis-nos/genai-agent/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/pr-validation.yml)
[![Dependency Updates](https://github.com/rjdinis-nos/genai-agent/actions/workflows/dependency-update.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/dependency-update.yml)
[![Performance Monitoring](https://github.com/rjdinis-nos/genai-agent/actions/workflows/performance.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/performance.yml)
[![Release](https://github.com/rjdinis-nos/genai-agent/actions/workflows/release.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/release.yml)

[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[![GitHub issues](https://img.shields.io/github/issues/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/network)
[![GitHub stars](https://img.shields.io/github/stars/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/commits/main)

[![Container Registry](https://img.shields.io/badge/ghcr.io-genai--agent-blue?logo=github)](https://github.com/rjdinis-nos/genai-agent/pkgs/container/genai-agent)
[![Code Quality](https://img.shields.io/badge/code%20quality-A+-brightgreen)](https://github.com/rjdinis-nos/genai-agent)
[![Security](https://img.shields.io/badge/security-scanned-green?logo=github)](https://github.com/rjdinis-nos/genai-agent/security)
[![Tests](https://img.shields.io/badge/tests-14%20passing-brightgreen)](https://github.com/rjdinis-nos/genai-agent/actions)

A FastAPI application that provides two main endpoints:

1. **File Download**: Download files from the internet
2. **PDF Summarization**: Summarize PDF documents using Google Gemini AI

## Project Structure

```
genai-baseline-agent/
├── .devcontainer/              # Development container configuration
├── .docker/                    # Docker configuration files
│   ├── Dockerfile              # Main application container
│   ├── Dockerfile.test         # Test environment container
│   ├── docker-compose.dev.yml  # Development environment
│   ├── docker-compose.prod.yml # Production environment
│   └── docker-compose.test.yml # Test environment
├── .github/                    # GitHub Actions workflows
│   ├── workflows/              # CI/CD pipeline definitions
│   └── ...
├── downloads/                  # Downloaded files storage
├── scripts/                    # CLI tools and automation
│   ├── api/                    # API interaction tools
│   │   ├── download.sh         # File download script
│   │   ├── download-file.sh    # Enhanced download with options
│   │   ├── health.sh           # Health check script
│   │   ├── healthcheck.sh      # Comprehensive health monitoring
│   │   ├── summarize.sh        # PDF summarization script
│   │   ├── summarize-pdf.sh    # Enhanced PDF processing
│   │   └── README.md           # API tools documentation
│   ├── docker/                 # Docker management tools
│   │   ├── cli.sh              # Unified CLI entry point
│   │   ├── _build.sh           # Container build operations
│   │   ├── _start.sh           # Service startup operations
│   │   ├── _stop.sh            # Service shutdown operations
│   │   ├── _tests.sh           # Test execution operations
│   │   ├── _cleanup.sh         # Resource cleanup operations
│   │   ├── _logs.sh            # Log viewing operations
│   │   ├── _status.sh          # Status checking operations
│   │   ├── _bash.sh            # Interactive shell access
│   │   ├── _utils.sh           # Shared utility functions
│   │   ├── .env.docker         # Docker environment variables
│   │   └── README.md           # Docker CLI documentation
│   └── README.md               # Scripts overview documentation
├── src/                        # Application source code
│   └── main.py                 # FastAPI application entry point
├── tests/                      # Test suite
│   ├── __init__.py             # Test package initialization
│   ├── test_api.py             # API endpoint tests
│   └── test_benchmarks.py      # Performance benchmark tests
├── .dockerignore               # Docker build exclusions
├── .env                        # Environment variables (local)
├── .gitignore                  # Git exclusions
├── LICENSE                     # Project license
├── README.md                   # Project documentation (this file)
├── pyproject.toml              # Python project configuration
├── pytest.ini                 # Test configuration
├── requirements.txt            # Python dependencies
└── uv.lock                     # Dependency lock file
```

### Key Directories

- **`.docker/`**: Contains all Docker-related configuration files for different environments
- **`scripts/`**: Comprehensive CLI tooling for Docker operations and API interactions
  - **`scripts/docker/`**: Unified Docker management with 9 core commands
  - **`scripts/api/`**: Direct API interaction tools with full parameter support
- **`src/`**: Application source code with FastAPI implementation
- **`tests/`**: Complete test suite including API tests and benchmarks
- **`.github/`**: CI/CD workflows for automated testing, deployment, and monitoring

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Bash shell (for CLI tools)

### Using the Unified CLI

This project includes a comprehensive CLI system for Docker operations and API interactions:

```bash
# Build and start the application
./scripts/docker/cli.sh start

# Check application status
./scripts/docker/cli.sh status

# View application logs
./scripts/docker/cli.sh logs
```

The API will be available at `http://localhost:8000`

## CLI Tools

### Docker Operations (`scripts/docker/cli.sh`)

Unified interface for all Docker operations with 9 core commands:

```bash
# Core Commands
./scripts/docker/cli.sh build [--env ENV] [--verbose] [--dry-run]    # Build containers
./scripts/docker/cli.sh start [--env ENV] [--detach] [--build]       # Start services
./scripts/docker/cli.sh stop [--env ENV]                             # Stop services
./scripts/docker/cli.sh tests [--env ENV] [--verbose]                # Run tests
./scripts/docker/cli.sh cleanup [--env ENV] [--force]                # Clean resources
./scripts/docker/cli.sh logs [--env ENV] [--follow] [--lines N]      # View logs
./scripts/docker/cli.sh status [--env ENV]                           # Check status
./scripts/docker/cli.sh bash [--env ENV]                             # Interactive shell
./scripts/docker/cli.sh deploy [--env ENV] [--registry URL]          # Deploy containers
```

**Environment Support:** `dev` (default), `prod`, `test`

### API Interaction Tools (`scripts/api/`)

Direct API interaction tools with comprehensive options:

```bash
# Health Checks
./scripts/api/health.sh [--host HOST] [--port PORT] [--https] [--json] [--verbose]
./scripts/api/healthcheck.sh [--host HOST] [--port PORT] [--timeout SECONDS]

# File Operations
./scripts/api/download.sh --url URL [--output FILE] [--host HOST] [--port PORT]
./scripts/api/download-file.sh URL [OUTPUT_FILE] [HOST] [PORT]

# PDF Summarization
./scripts/api/summarize.sh --file PDF_FILE [--host HOST] [--port PORT] [--https]
./scripts/api/summarize-pdf.sh PDF_FILE [HOST] [PORT]
```

**Environment Variables:**

- `GENAI_SERVER_URL`: Default server URL
- `GENAI_TIMEOUT`: Request timeout (default: 30s)

## API Documentation

Once running, visit:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **Health Check**: `http://localhost:8000/health`

## Endpoints

### POST /download

Download a file from the internet.

**Parameters:**

- `url` (string): URL of the file to download

**Example:**

```bash
curl -X POST "http://localhost:8000/download" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://example.com/file.pdf"}'
```

### POST /summarize

Summarize a PDF document using Google Gemini.

**Parameters:**

- `file` (file): PDF file to upload and summarize

**Example:**

```bash
curl -X POST "http://localhost:8000/summarize" \
     -F "file=@document.pdf"
```

## Development

### Local Development Setup

1. **Clone and setup:**

   ```bash
   git clone <repository-url>
   cd genai-baseline-agent
   ```

2. **Environment configuration:**

   ```bash
   cp .env.example .env
   # Edit .env with your Google Gemini API key
   ```

3. **Start development environment:**

   ```bash
   ./scripts/docker/cli.sh start --env dev --build
   ```

### Testing

```bash
# Run all tests
./scripts/docker/cli.sh tests

# Run tests with verbose output
./scripts/docker/cli.sh tests --verbose

# Test specific environment
./scripts/docker/cli.sh tests --env test
```

### Debugging

```bash
# View real-time logs
./scripts/docker/cli.sh logs --follow

# Access container shell
./scripts/docker/cli.sh bash

# Check service status
./scripts/docker/cli.sh status
```
