# Scripts Directory

This directory contains organized shell scripts and CLI tools for the GenAI Agent application.

## Directory Structure

```
scripts/
├── cli/           # Command-line tools for API interaction
│   ├── summarize-pdf.sh   # Comprehensive PDF summarization CLI
│   ├── summarize.sh       # Simple PDF summarization one-liner
│   └── README.md          # CLI tools documentation
├── docker/        # Docker container management scripts
│   ├── build.sh           # Build Docker images
│   ├── run.sh             # Run development containers
│   ├── deploy.sh          # Deploy production containers
│   ├── test.sh            # Run tests in containers
│   ├── logs.sh            # View container logs
│   ├── cleanup.sh         # Clean up Docker resources
│   └── README.md          # Docker scripts documentation
└── README.md      # This file - overview and quick start
```

## Quick Start

### For API Usage (CLI Tools)
```bash
# Summarize a PDF document
./scripts/cli/summarize-pdf.sh document.pdf

# Quick one-liner summarization
./scripts/cli/summarize.sh report.pdf
```

### For Development (Docker Scripts)
```bash
# Build and run the application
./scripts/docker/build.sh
./scripts/docker/run.sh

# Run tests
./scripts/docker/test.sh
```

## Detailed Documentation

- **[CLI Tools](cli/README.md)** - Command-line tools for interacting with GenAI Agent API
- **[Docker Scripts](docker/README.md)** - Container management and deployment scripts

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
./scripts/cli/summarize-pdf.sh document.pdf

# Quick PDF summarization
./scripts/cli/summarize.sh report.pdf

# Use with remote server
GENAI_SERVER_URL=https://your-server.com ./scripts/cli/summarize-pdf.sh paper.pdf

# Get help
./scripts/cli/summarize-pdf.sh --help
```

### Docker Scripts Usage
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

- **Docker Compose**: See `.docker/` directory for advanced orchestration
- **GitHub Actions**: Automated CI/CD workflows in `.github/workflows/`
- **Testing**: Comprehensive test suite in `tests/` directory

## Getting Help

For detailed documentation on specific tools:

```bash
# CLI tools help
./scripts/cli/summarize-pdf.sh --help

# View specific documentation
cat scripts/cli/README.md
cat scripts/docker/README.md
```

## Contributing

When adding new scripts:

1. **CLI tools** → Place in `scripts/cli/` with appropriate documentation
2. **Docker scripts** → Place in `scripts/docker/` with proper error handling
3. **Update documentation** → Update relevant README files
4. **Make executable** → `chmod +x script-name.sh`

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
