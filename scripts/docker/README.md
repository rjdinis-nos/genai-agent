# Docker Scripts

This directory contains shell scripts for building, running, and deploying the GenAI Agent application in Docker containers.

## Prerequisites

- Docker installed and running
- `.env` file with `GEMINI_API_KEY` configured

## Available Scripts

### 🔨 `build.sh`
Builds the Docker image for the application.

```bash
./scripts/docker/build.sh [tag]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)

**Examples:**
```bash
./scripts/docker/build.sh          # Build with 'latest' tag
./scripts/docker/build.sh v1.0.0   # Build with 'v1.0.0' tag
```

**Features:**
- Multi-stage Docker build for optimized image size
- Automatic cleanup of intermediate containers
- Build progress indicators
- Error handling and validation

### 🚀 `run.sh`
Runs the Docker container locally for development/testing.

```bash
./scripts/docker/run.sh [tag] [port]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)
- `port` (optional): Host port to bind to (default: `8000`)

**Examples:**
```bash
./scripts/docker/run.sh             # Run latest image on port 8000
./scripts/docker/run.sh latest 3000 # Run latest image on port 3000
```

**Features:**
- Automatically stops existing development container
- Mounts local `downloads` directory
- Loads environment variables from `.env` file
- Provides health check and status information

### 🌐 `deploy.sh`
Deploys the Docker container for production use.

```bash
./scripts/docker/deploy.sh [tag] [port]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)
- `port` (optional): Host port to bind to (default: `8000`)

**Examples:**
```bash
./scripts/docker/deploy.sh          # Deploy latest image on port 8000
./scripts/docker/deploy.sh v1.0.0   # Deploy specific version
```

**Features:**
- Production-optimized container settings
- Automatic restart policies
- Resource limits and constraints
- Health monitoring
- Persistent volume management

### 🧪 `test.sh`
Runs the test suite inside a Docker container.

```bash
./scripts/docker/test.sh [tag]
```

**Parameters:**
- `tag` (optional): Docker image tag (default: `latest`)

**Examples:**
```bash
./scripts/docker/test.sh        # Run tests with latest image
./scripts/docker/test.sh v1.0.0 # Run tests with specific version
```

**Features:**
- Isolated test environment
- Comprehensive test coverage reporting
- Automatic test result formatting
- Exit code propagation for CI/CD

### 📋 `logs.sh`
Views and follows container logs.

```bash
./scripts/docker/logs.sh [container_name] [options]
```

**Parameters:**
- `container_name` (optional): Container name (default: `genai-agent-dev`)
- `options` (optional): Additional docker logs options

**Examples:**
```bash
./scripts/docker/logs.sh                    # View dev container logs
./scripts/docker/logs.sh genai-agent-prod   # View production logs
./scripts/docker/logs.sh genai-agent-dev -f # Follow logs in real-time
```

**Features:**
- Real-time log streaming
- Colored output for better readability
- Timestamp formatting
- Container status checking

### 🧹 `cleanup.sh`
Cleans up Docker resources (containers, images, volumes).

```bash
./scripts/docker/cleanup.sh [options]
```

**Options:**
- `--containers`: Remove only containers
- `--images`: Remove only images
- `--volumes`: Remove only volumes
- `--all`: Remove everything (default)

**Examples:**
```bash
./scripts/docker/cleanup.sh              # Clean up everything
./scripts/docker/cleanup.sh --containers # Remove only containers
./scripts/docker/cleanup.sh --images     # Remove only images
```

**Features:**
- Safe cleanup with confirmation prompts
- Selective resource removal
- Disk space reporting
- Preservation of important data

## Usage Workflows

### Development Workflow
```bash
# 1. Build the application
./scripts/docker/build.sh

# 2. Run for development
./scripts/docker/run.sh

# 3. Run tests
./scripts/docker/test.sh

# 4. View logs
./scripts/docker/logs.sh -f
```

### Production Deployment
```bash
# 1. Build production image
./scripts/docker/build.sh v1.0.0

# 2. Deploy to production
./scripts/docker/deploy.sh v1.0.0 80

# 3. Monitor logs
./scripts/docker/logs.sh genai-agent-prod -f
```

### Maintenance
```bash
# View container status
docker ps -a

# Clean up old resources
./scripts/docker/cleanup.sh --containers

# Full cleanup (be careful!)
./scripts/docker/cleanup.sh --all
```

## Environment Configuration

Create a `.env` file in the project root:

```bash
# Required
GEMINI_API_KEY=your_google_gemini_api_key_here

# Optional
GENAI_PORT=8000
GENAI_HOST=0.0.0.0
GENAI_WORKERS=1
```

## Container Names

The scripts use these container naming conventions:
- Development: `genai-agent-dev`
- Production: `genai-agent-prod`
- Testing: `genai-agent-test`

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Check what's using the port
sudo lsof -i :8000

# Use a different port
./scripts/docker/run.sh latest 3000
```

**Permission denied:**
```bash
# Make scripts executable
chmod +x scripts/docker/*.sh

# Check Docker permissions
sudo usermod -aG docker $USER
```

**Container won't start:**
```bash
# Check logs
./scripts/docker/logs.sh

# Verify environment file
cat .env

# Check Docker daemon
sudo systemctl status docker
```

### Performance Optimization

**Build optimization:**
```bash
# Use BuildKit for faster builds
DOCKER_BUILDKIT=1 ./scripts/docker/build.sh
```

**Resource limits:**
```bash
# Monitor resource usage
docker stats genai-agent-dev
```

## Integration with CI/CD

These scripts are designed to work with the GitHub Actions workflows in `.github/workflows/`. They provide the foundation for:

- Automated testing
- Container builds
- Deployment automation
- Resource management

For more advanced container orchestration, see the Docker Compose configurations in the `scripts/compose/` directory.
