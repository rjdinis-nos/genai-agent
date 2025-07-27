# Scripts Directory

This directory contains shell scripts for building, running, and deploying the GenAI Agent application in Docker containers.

## Prerequisites

- Docker installed and running
- `.env` file with `GEMINI_API_KEY` configured

## Scripts Overview

### 🔨 `build.sh`
Builds the Docker image for the application.

```bash
./scripts/build.sh [tag]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)

**Example:**
```bash
./scripts/build.sh          # Build with 'latest' tag
./scripts/build.sh v1.0.0    # Build with 'v1.0.0' tag
```

### 🚀 `run.sh`
Runs the Docker container locally for development/testing.

```bash
./scripts/run.sh [tag] [port]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)
- `port` (optional): Host port to bind to (default: `8000`)

**Example:**
```bash
./scripts/run.sh             # Run latest image on port 8000
./scripts/run.sh latest 3000 # Run latest image on port 3000
```

**Features:**
- Automatically stops existing development container
- Mounts local `downloads` directory
- Loads environment variables from `.env` file
- Provides health check and status information

### 📄 `summarize-pdf.sh`
Comprehensive CLI tool for PDF summarization with error handling and status feedback.

```bash
./scripts/summarize-pdf.sh <pdf_file_path> [server_url]
```

**Parameters:**
- `pdf_file_path` (required): Path to the PDF file to summarize
- `server_url` (optional): GenAI Agent server URL (default: `http://localhost:8000`)

**Environment Variables:**
- `GENAI_SERVER_URL`: Override default server URL
- `GENAI_TIMEOUT`: Request timeout in seconds (default: 60)

**Examples:**
```bash
./scripts/summarize-pdf.sh document.pdf
./scripts/summarize-pdf.sh /path/to/report.pdf http://localhost:8000
GENAI_SERVER_URL=https://genai-agent.example.com ./scripts/summarize-pdf.sh paper.pdf
```

**Features:**
- File validation and PDF format checking
- Server availability verification
- Colored output with status indicators
- Comprehensive error handling
- Timeout configuration
- Help documentation (`-h` or `--help`)

### 📄 `summarize.sh`
Simple one-liner for quick PDF summarization.

```bash
./scripts/summarize.sh <pdf_file_path> [server_url]
```

**Parameters:**
- `pdf_file_path` (required): Path to the PDF file to summarize
- `server_url` (optional): GenAI Agent server URL (default: `http://localhost:8000`)

**Example:**
```bash
./scripts/summarize.sh document.pdf
./scripts/summarize.sh report.pdf http://localhost:3000
```

**Features:**
- Minimal dependencies (curl, jq)
- JSON response parsing
- Quick and simple usage

### 🌐 `deploy.sh`
Deploys the Docker container for production use.

```bash
./scripts/deploy.sh [tag] [port]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)
- `port` (optional): Host port to bind to (default: `80`)

**Example:**
```bash
./scripts/deploy.sh          # Deploy latest image on port 80
./scripts/deploy.sh v1.0.0 8080 # Deploy v1.0.0 image on port 8080
```

**Features:**
- Creates Docker network for container isolation
- Sets up persistent volume for downloads
- Configures resource limits (512MB RAM, 0.5 CPU)
- Automatic restart policy
- Health check validation
- Production-ready configuration

### 📋 `logs.sh`
View and follow container logs.

```bash
./scripts/logs.sh [OPTIONS] [CONTAINER_TYPE]
```

**Parameters:**
- `CONTAINER_TYPE`: `dev` (default) or `prod`

**Options:**
- `-f, --follow`: Follow log output
- `-t, --tail N`: Show last N lines (default: 50)
- `-h, --help`: Show help message

**Examples:**
```bash
./scripts/logs.sh                # Show last 50 lines of dev container
./scripts/logs.sh -f             # Follow dev container logs
./scripts/logs.sh -t 100 prod    # Show last 100 lines of prod container
./scripts/logs.sh --follow prod  # Follow prod container logs
```

### 🧹 `cleanup.sh`
Clean up Docker containers, images, and volumes.

```bash
./scripts/cleanup.sh
```

**Features:**
- Stops and removes all application containers
- Removes Docker images
- Removes Docker network
- Optionally removes persistent volume (with confirmation)
- Cleans up dangling Docker resources

## Quick Start

1. **Build the application:**
   ```bash
   ./scripts/build.sh
   ```

2. **Run for development:**
   ```bash
   ./scripts/run.sh
   ```

3. **Deploy for production:**
   ```bash
   ./scripts/deploy.sh
   ```

4. **View logs:**
   ```bash
   ./scripts/logs.sh -f
   ```

5. **Clean up when done:**
   ```bash
   ./scripts/cleanup.sh
   ```

## Application URLs

After running the container, the application will be available at:

- **API**: `http://localhost:PORT`
- **Interactive Docs**: `http://localhost:PORT/docs`
- **ReDoc**: `http://localhost:PORT/redoc`

## Docker Resources

### Development Container
- **Name**: `fastapi-app`
- **Port**: `8000` (configurable)
- **Volume**: Local `downloads` directory mounted

### Production Container
- **Name**: `fastapi-app-prod`
- **Port**: `80` (configurable)
- **Network**: `fastapi-network`
- **Volume**: `fastapi-downloads` (persistent)
- **Resources**: 512MB RAM, 0.5 CPU
- **Restart**: `unless-stopped`

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
