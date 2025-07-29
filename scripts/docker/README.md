# Docker CLI - Unified Docker Operations

This directory contains the unified Docker CLI interface and supporting scripts for containerizing and managing the GenAI Agent FastAPI application.

## 🎯 Main Entry Point

**Primary Interface:** `cli.sh` - Centralized command-line interface for all Docker operations

```bash
./cli.sh <command> [options]
```

## 📁 Directory Structure

```text
scripts/docker/
├── cli.sh              # 🎯 MAIN CLI ENTRY POINT
├── _build.sh           # Build Docker images
├── _start.sh           # Start application containers
├── _tests.sh           # Run comprehensive test suite
├── _cleanup.sh         # Clean up Docker resources
├── _logs.sh            # View container logs
├── _status.sh          # Check container status
├── _stop.sh            # Stop running containers
├── _bash.sh            # Open shell in containers
├── _utils.sh           # Utility functions and shared code
├── .env.docker         # Auto-generated environment variables
└── README.md           # This file
```

**Note:** Docker Compose files and Dockerfiles are located in `/.docker/` at project root.

## 🚀 Quick Start

### 1. Build the Application
```bash
./scripts/docker/cli.sh build
```

### 2. Start Development Environment
```bash
./scripts/docker/cli.sh start
```

### 3. Run Tests with Coverage
```bash
./scripts/docker/cli.sh tests --coverage
```

### 4. Check Application Status
```bash
./scripts/docker/cli.sh status
```

### 5. View Logs
```bash
./scripts/docker/cli.sh logs -f
```

### 6. Clean Up Resources
```bash
./scripts/docker/cli.sh cleanup
```

## 📋 Available CLI Commands

All operations are performed through the unified CLI interface: `./cli.sh <command> [options]`

### `build` - Build Docker Images

Builds Docker images for the specified environment.

**Usage:**
```bash
./cli.sh build [OPTIONS] [TAG]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: dev)
- `-t, --tag TAG` - Image tag (default: latest)
- `--no-cache` - Build without using cache
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

**Examples:**
```bash
./cli.sh build                         # Build dev environment with latest tag
./cli.sh build -e prod v1.0            # Build prod environment with v1.0 tag
./cli.sh build --no-cache              # Build without cache
./cli.sh build -v                      # Build with verbose output
```

### `start` - Start Application

Starts the application containers with comprehensive options.

**Usage:**
```bash
./cli.sh start [OPTIONS]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: dev)
- `-p, --port PORT` - Host port to bind (default: 8000)
- `-f, --foreground` - Run in foreground (default: detached)
- `--build` - Build the image before starting
- `-n, --no-health-check` - Skip health check after startup
- `-v, --verbose` - Enable verbose output

**Features:**
- Automatic health checks with 10 retry attempts
- Production .env file validation
- Success messaging with API, Docs, ReDoc URLs
- Container management guidance

**Examples:**
```bash
./cli.sh start                         # Run dev environment
./cli.sh start -e prod -p 80           # Run prod environment on port 80
./cli.sh start -f --verbose            # Run in foreground with verbose output
./cli.sh start -n                      # Skip health check
```

### `tests` - Run Test Suite

Runs comprehensive test suite with multiple options.

**Usage:**
```bash
./cli.sh tests [OPTIONS] [TEST_ARGS]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: test)
- `-v, --verbose` - Enable verbose output
- `-c, --coverage` - Run tests with coverage report
- `-w, --watch` - Watch mode (rebuild and rerun on changes)
- `-f, --filter PATTERN` - Run only tests matching pattern
- `-q, --quick` - Quick test run (skip slow tests)
- `-u, --unit` - Run only unit tests
- `-i, --integration` - Run only integration tests
- `-b, --benchmark` - Run benchmark tests
- `--clean` - Clean test artifacts before running
- `--no-build` - Skip Docker image build

**Examples:**
```bash
./cli.sh tests                         # Run all tests
./cli.sh tests --verbose --coverage    # Verbose run with coverage
./cli.sh tests --filter test_api       # Run tests matching 'test_api'
./cli.sh tests --unit --quick          # Quick unit tests only
./cli.sh tests --env dev --watch       # Watch mode in dev environment
```

### `cleanup` - Clean Docker Resources

Removes all project-created Docker resources safely.

**Usage:**
```bash
./cli.sh cleanup [OPTIONS]
```

**Options:**
- `--dry-run` - Show what would be removed without executing
- `--force` - Skip confirmation prompts
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

**Removes:**
- Containers (dev, prod, test environments)
- Images (project-specific and related)
- Volumes (project downloads)
- Networks (project network)
- Build cache

**Examples:**
```bash
./cli.sh cleanup                       # Interactive cleanup with confirmation
./cli.sh cleanup --dry-run             # Preview what would be removed
./cli.sh cleanup --force               # Remove all resources without prompts
./cli.sh cleanup --verbose --dry-run   # Preview with detailed output
```

### `logs` - View Container Logs

Views and follows container logs with various options.

**Usage:**
```bash
./cli.sh logs [OPTIONS] [ENVIRONMENT]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: dev)
- `-f, --follow` - Follow log output
- `-t, --tail N` - Show last N lines (default: 50)
- `-h, --help` - Show help message

**Examples:**
```bash
./cli.sh logs                          # Show last 50 lines of dev containers
./cli.sh logs -f                       # Follow dev container logs
./cli.sh logs -t 100 prod              # Show last 100 lines of prod containers
./cli.sh logs --follow prod            # Follow prod container logs
```

### `status` - Show Container Status

Checks the status of running containers with health validation.

**Usage:**
```bash
./cli.sh status [ENVIRONMENT] [OPTIONS]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: dev)
- `-v, --verbose` - Show detailed container information
- `-l, --logs` - Show recent logs for running containers
- `-h, --help` - Show help message

**Features:**
- Service health checks with HTTP endpoint validation
- Container status monitoring
- Resource count display

**Examples:**
```bash
./cli.sh status                        # Check dev containers
./cli.sh status prod                   # Check prod containers
./cli.sh status all -v                 # Check all containers with details
./cli.sh status dev --logs             # Check dev containers and show logs
```

### `stop` - Stop Running Containers

Stops running containers for specified environment.

**Usage:**
```bash
./cli.sh stop [OPTIONS]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test, all (default: dev)
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

**Examples:**
```bash
./cli.sh stop                          # Stop dev containers
./cli.sh stop --env prod               # Stop prod containers
./cli.sh stop --env all                # Stop all containers
```

### `bash` - Open Shell in Container

Opens an interactive bash shell in running containers.

**Usage:**
```bash
./cli.sh bash [ENVIRONMENT] [OPTIONS]
```

**Options:**
- `-e, --env ENV` - Environment: dev, prod, test (default: dev)
- `-v, --verbose` - Show detailed container information
- `-u, --user USER` - User to run as (default: root)
- `-h, --help` - Show help message

**Examples:**
```bash
./cli.sh bash                          # Enter dev container as root
./cli.sh bash prod                     # Enter prod container as root
./cli.sh bash -u app                   # Enter dev container as app user
./cli.sh bash prod -u app              # Enter prod container as app user
scripts/docker/stop.sh prod            # Stop prod containers
scripts/docker/stop.sh all             # Stop all containers
```

### `cleanup.sh`
Comprehensive cleanup of Docker resources with selective options.

**Usage:**
```bash
scripts/docker/cleanup.sh [OPTIONS]
```

**Options:**
- `--containers`: Remove containers only
- `--images`: Remove images only
- `--volumes`: Remove volumes only
- `--networks`: Remove networks only
- `--all`: Remove everything (default)
- `--force`: Skip confirmation prompts

**Examples:**
```bash
scripts/docker/cleanup.sh              # Interactive cleanup of everything
scripts/docker/cleanup.sh --containers # Remove only containers
scripts/docker/cleanup.sh --all --force # Remove everything without prompts
```

## 🐳 Docker Compose Files

### `docker-compose-dev.yml` (Development)
- **Port**: 8000
- **Features**: Volume mounting, environment variables, health checks
- **Use case**: Local development with hot-reloading

### `docker-compose.prod.yml` (Production)
- **Port**: 80
- **Features**: Resource limits, persistent volumes, logging, restart policies
- **Use case**: Production deployment

### `docker-compose.test.yml` (Testing)
- **Features**: Test-specific configuration, isolated environment
- **Use case**: Running automated tests

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the project root with:
```env
GEMINI_API_KEY=your_api_key_here
```

### Port Configuration
- **Development**: Default port 8000 (configurable)
- **Production**: Default port 80 (configurable)
- **Testing**: No external port exposure

### Volume Mounts
- **Development**: Source code mounted for live changes
- **Production**: Persistent volume for downloads
- **Testing**: Test files mounted read-only

## 🌐 Network Configuration

All containers use the `fastapi-network` network for internal communication.

## 💾 Persistent Storage

### Development
- Local `downloads/` directory mounted as volume

### Production
- Named volume `fastapi-downloads` for persistent storage

## 🏥 Health Checks

All environments include health checks that:
- Test the `/docs` endpoint
- Run every 30 seconds
- Timeout after 10 seconds
- Retry 3 times before marking as unhealthy
- Wait 40 seconds before starting checks

## 📊 Resource Management

### Production Limits
- **Memory**: 512MB limit, 256MB reservation
- **CPU**: 0.5 CPU limit, 0.25 CPU reservation

### Logging
- **Driver**: JSON file
- **Max size**: 10MB per file
- **Max files**: 3 files retained

## 🔄 Workflow Examples

### Development Workflow
```bash
# Build and start development environment
scripts/docker/build.sh
scripts/docker/run.sh

# View logs
scripts/docker/logs.sh -f

# Run tests
scripts/docker/test.sh

# Stop when done
scripts/docker/stop.sh
```

### Production Deployment
```bash
# Build and deploy
scripts/docker/build.sh
scripts/docker/deploy.sh

# Monitor logs
scripts/docker/logs.sh -f prod

# Health check
curl http://localhost/docs
```

### Testing Workflow
```bash
# Run tests
scripts/docker/test.sh

# View test results and cleanup automatically
```

### Cleanup Workflow
```bash
# Clean up everything
scripts/docker/cleanup.sh --all

# Or selective cleanup
scripts/docker/cleanup.sh --containers
scripts/docker/cleanup.sh --images --volumes
```

## 🚨 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   scripts/docker/stop.sh all
   scripts/docker/run.sh 3000  # Use different port
   ```

2. **Permission denied**
   ```bash
   chmod +x scripts/docker/*.sh
   ```

3. **Container won't start**
   ```bash
   scripts/docker/logs.sh
   scripts/docker/cleanup.sh --containers
   scripts/docker/build.sh
   ```

4. **Tests failing**
   ```bash
   # Run tests locally first
   uv run pytest -v
   
   # Then in container
   scripts/docker/test.sh
   ```

### Health Check Failures
- Verify `.env` file exists with `GEMINI_API_KEY`
- Check container logs: `scripts/docker/logs.sh`
- Ensure no port conflicts
- Verify Docker daemon is running

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Project Main README](../README.md)

## 🤝 Contributing

When adding new Docker Compose configurations:
1. Update the appropriate compose file
2. Add corresponding script if needed
3. Update this README
4. Test all environments
5. Update the main project documentation
