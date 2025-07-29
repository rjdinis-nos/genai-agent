# Scripts Directory

This directory contains organized shell scripts and CLI tools for the GenAI Agent application.

## Directory Structure

```text
scripts/
├── api/           # API interaction CLI tools
│   ├── healthcheck.sh     # Comprehensive health monitoring
│   ├── health.sh          # Simple health check
│   ├── download-file.sh   # File download CLI with options
│   ├── download.sh        # Simple download wrapper
│   ├── summarize-pdf.sh   # PDF summarization CLI with options
│   ├── summarize.sh       # Simple summarization wrapper
│   └── README.md          # API tools documentation
├── docker/        # Unified Docker CLI and management scripts
│   ├── cli.sh             # 🎯 MAIN CLI ENTRY POINT
│   ├── _build.sh          # Build Docker images
│   ├── _start.sh          # Start application containers
│   ├── _tests.sh          # Run comprehensive test suite
│   ├── _cleanup.sh        # Clean up Docker resources
│   ├── _logs.sh           # View container logs
│   ├── _status.sh         # Check container status
│   ├── _stop.sh           # Stop running containers
│   ├── _bash.sh           # Open shell in containers
│   ├── _utils.sh          # Utility functions
│   ├── .env.docker        # Auto-generated environment variables
│   └── README.md          # Docker CLI documentation
└── README.md      # This file - overview and quick start
```

## 🚀 Main Entry Points

### Docker Operations (Unified CLI)

**Primary Interface:** `scripts/docker/cli.sh`

All Docker operations are accessed through the unified CLI:

```bash
# Build, start, test, manage containers
./scripts/docker/cli.sh <command> [options]
```

### API Interaction Tools

**Location:** `scripts/api/`

Direct API interaction tools for health checks, downloads, and summarization:

```bash
# Health monitoring, file downloads, PDF summarization
./scripts/api/<tool>.sh [options]
```

## Quick Start

### 🐳 Docker Operations (Unified CLI)

```bash
# Build the application
./scripts/docker/cli.sh build

# Start development environment
./scripts/docker/cli.sh start

# Run tests with coverage
./scripts/docker/cli.sh tests --coverage

# Check application status
./scripts/docker/cli.sh status

# View logs
./scripts/docker/cli.sh logs -f

# Clean up resources
./scripts/docker/cli.sh cleanup
```

### 🔧 API Interaction Tools

```bash
# Health check with system details
./scripts/api/healthcheck.sh -v

# Download a file
./scripts/api/download-file.sh https://example.com/file.pdf

# Summarize a PDF document
./scripts/api/summarize-pdf.sh document.pdf

# Quick summarization
./scripts/api/summarize.sh report.pdf
```

### 🏗️ Development Workflow

```bash
# Complete development setup
./scripts/docker/build.sh
./scripts/docker/run.sh

# Run tests
./scripts/docker/test.sh
```

## Detailed Documentation

- **[CLI Tools](cli/README.md)** - Command-line tools for interacting with GenAI Agent API
- **[Docker Compose](compose/README.md)** - Modern container orchestration with Docker Compose
- **[Docker Scripts](docker/README.md)** - Traditional Docker container management scripts

## Prerequisites

### For CLI Tools
- GenAI Agent server running (locally or remote)
- `curl` command-line tool
- `jq` for JSON parsing (optional)

### For Docker Scripts
- Docker installed and running
- `.env` file with `GEMINI_API_KEY` configured

## Common Usage Examples

### CLI Tools Usage
```bash
# Comprehensive PDF summarization with error handling
./scripts/api/summarize-pdf.sh document.pdf

# Quick PDF summarization
./scripts/api/summarize.sh report.pdf

# Use with remote server
GENAI_SERVER_URL=https://your-server.com ./scripts/api/summarize-pdf.sh paper.pdf

# Get help
./scripts/api/summarize-pdf.sh --help
```

### Docker Compose Usage (Recommended)
```bash
# Development workflow
./scripts/docker/build.sh
./scripts/docker/run.sh
./scripts/docker/test.sh

# Production deployment
./scripts/docker/build.sh v1.0.0
./scripts/docker/deploy.sh 80

# Container management
./scripts/docker/logs.sh -f
./scripts/docker/stop.sh
./scripts/docker/cleanup.sh
```

### Docker Scripts Usage (Traditional)
```bash
# Development workflow
./scripts/docker/build.sh
./scripts/docker/run.sh
./scripts/docker/test.sh

# Production deployment
./scripts/docker/build.sh v1.0.0
./scripts/docker/deploy.sh v1.0.0 80
```

## Application URLs

After starting the server, access:

- **API**: `http://localhost:8000`
- **Interactive Docs**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## Integration with Other Tools

The scripts are designed to work together and integrate with:

- **Docker Compose**: See `scripts/docker/` directory for modern container orchestration
- **GitHub Actions**: Automated CI/CD workflows in `.github/workflows/`
- **Testing**: Comprehensive test suite in `tests/` directory

## Getting Help

For detailed documentation on specific tools:

```bash
# CLI tools help
./scripts/api/summarize-pdf.sh --help

# View specific documentation
cat scripts/api/README.md
cat scripts/docker/README.md
cat scripts/docker/README.md
```

## Contributing

When adding new scripts:

1. **CLI tools** → Place in `scripts/api/` with appropriate documentation
2. **Docker Compose scripts** → Place in `scripts/docker/` with Docker Compose integration
3. **Docker scripts** → Place in `scripts/docker/` with proper error handling
4. **Update documentation** → Update relevant README files
5. **Make executable** → `chmod +x script-name.sh`

For more information, see the project's main README and contributing guidelines.

## Troubleshooting

### Container won't start
1. Check if Docker is running: `docker info`
2. Verify image exists: `docker images genai-agent`
3. Check logs: `./scripts/logs.sh`

### Port already in use
- Change the port: `./scripts/run.sh latest 3000`
- Or stop conflicting services

### Environment variables
- Ensure `.env` file exists with `GEMINI_API_KEY`
- Check container environment: `docker exec fastapi-app env`

### Health check failures
- Wait a few moments for application startup
- Check application logs for errors
- Verify all dependencies are properly installed
