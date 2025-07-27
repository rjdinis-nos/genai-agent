# Docker Compose Setup for FastAPI File Downloader & PDF Summarizer

This directory contains Docker Compose configurations and scripts for containerizing and managing the FastAPI application using modern Docker Compose workflows.

## 📁 Directory Structure

```
.docker/
├── docker-compose.yml          # Development environment
├── docker-compose.prod.yml     # Production environment
├── docker-compose.test.yml     # Testing environment
├── Dockerfile.test             # Test-specific Dockerfile
├── build.sh                    # Build Docker images
├── run.sh                      # Run development environment
├── deploy.sh                   # Deploy production environment
├── test.sh                     # Run tests in container
├── logs.sh                     # View container logs
├── stop.sh                     # Stop containers
├── cleanup.sh                  # Clean up Docker resources
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Build the Application
```bash
.docker/build.sh
```

### 2. Run for Development
```bash
.docker/run.sh
```

### 3. Run Tests
```bash
.docker/test.sh
```

### 4. Deploy for Production
```bash
.docker/deploy.sh
```

## 📋 Available Scripts

### `build.sh`
Builds the Docker image using Docker Compose.

**Usage:**
```bash
.docker/build.sh [IMAGE_TAG]
```

**Examples:**
```bash
.docker/build.sh                # Build with 'latest' tag
.docker/build.sh v1.0.0         # Build with custom tag
```

### `run.sh`
Runs the application in development mode with hot-reloading and volume mounting.

**Usage:**
```bash
.docker/run.sh [PORT]
```

**Examples:**
```bash
.docker/run.sh                  # Run on default port 8000
.docker/run.sh 3000             # Run on custom port 3000
```

**Features:**
- Volume mounting for live code changes
- Environment variable loading from `.env`
- Health checks
- Automatic container restart

### `deploy.sh`
Deploys the application for production with optimized settings.

**Usage:**
```bash
.docker/deploy.sh [PORT]
```

**Examples:**
```bash
.docker/deploy.sh               # Deploy on port 80
.docker/deploy.sh 8080          # Deploy on port 8080
```

**Features:**
- Resource limits and reservations
- Persistent volume storage
- Production logging configuration
- Health checks with retry logic
- Automatic restart policies

### `test.sh`
Runs the complete test suite inside a Docker container.

**Usage:**
```bash
.docker/test.sh
```

**Features:**
- Isolated test environment
- Automatic cleanup after tests
- Comprehensive test output
- Exit codes for CI/CD integration

### `logs.sh`
Views and follows container logs with various options.

**Usage:**
```bash
.docker/logs.sh [OPTIONS] [ENVIRONMENT]
```

**Options:**
- `-f, --follow`: Follow log output
- `-t, --tail N`: Show last N lines (default: 50)
- `-h, --help`: Show help message

**Examples:**
```bash
.docker/logs.sh                 # Show last 50 lines of dev logs
.docker/logs.sh -f              # Follow dev logs
.docker/logs.sh -t 100 prod     # Show last 100 lines of prod logs
.docker/logs.sh --follow prod   # Follow prod logs
```

### `stop.sh`
Stops running containers for specified environment.

**Usage:**
```bash
.docker/stop.sh [ENVIRONMENT]
```

**Examples:**
```bash
.docker/stop.sh                 # Stop dev containers
.docker/stop.sh prod            # Stop prod containers
.docker/stop.sh all             # Stop all containers
```

### `cleanup.sh`
Comprehensive cleanup of Docker resources with selective options.

**Usage:**
```bash
.docker/cleanup.sh [OPTIONS]
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
.docker/cleanup.sh              # Interactive cleanup of everything
.docker/cleanup.sh --containers # Remove only containers
.docker/cleanup.sh --all --force # Remove everything without prompts
```

## 🐳 Docker Compose Files

### `docker-compose.yml` (Development)
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
.docker/build.sh
.docker/run.sh

# View logs
.docker/logs.sh -f

# Run tests
.docker/test.sh

# Stop when done
.docker/stop.sh
```

### Production Deployment
```bash
# Build and deploy
.docker/build.sh
.docker/deploy.sh

# Monitor logs
.docker/logs.sh -f prod

# Health check
curl http://localhost/docs
```

### Testing Workflow
```bash
# Run tests
.docker/test.sh

# View test results and cleanup automatically
```

### Cleanup Workflow
```bash
# Clean up everything
.docker/cleanup.sh --all

# Or selective cleanup
.docker/cleanup.sh --containers
.docker/cleanup.sh --images --volumes
```

## 🚨 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   .docker/stop.sh all
   .docker/run.sh 3000  # Use different port
   ```

2. **Permission denied**
   ```bash
   chmod +x .docker/*.sh
   ```

3. **Container won't start**
   ```bash
   .docker/logs.sh
   .docker/cleanup.sh --containers
   .docker/build.sh
   ```

4. **Tests failing**
   ```bash
   # Run tests locally first
   uv run pytest -v
   
   # Then in container
   .docker/test.sh
   ```

### Health Check Failures
- Verify `.env` file exists with `GEMINI_API_KEY`
- Check container logs: `.docker/logs.sh`
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
