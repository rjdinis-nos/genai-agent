# Docker Compose Setup for GenAI Agent

This directory contains Docker Compose configurations and scripts for containerizing and managing the FastAPI application using modern Docker Compose workflows.

## 📁 Directory Structure

```
scripts/compose/
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
scripts/compose/build.sh
```

### 2. Run for Development
```bash
scripts/compose/run.sh
```

### 3. Run Tests
```bash
scripts/compose/test.sh
```

### 4. Deploy for Production
```bash
scripts/compose/deploy.sh
```

## 📋 Available Scripts

### `build.sh`
Builds the Docker image using Docker Compose.

**Usage:**
```bash
scripts/compose/build.sh [IMAGE_TAG]
```

**Examples:**
```bash
scripts/compose/build.sh                # Build with 'latest' tag
scripts/compose/build.sh v1.0.0         # Build with custom tag
```

### `run.sh`
Runs the application in development mode with hot-reloading and volume mounting.

**Usage:**
```bash
scripts/compose/run.sh [PORT]
```

**Examples:**
```bash
scripts/compose/run.sh                  # Run on default port 8000
scripts/compose/run.sh 3000             # Run on custom port 3000
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
scripts/compose/deploy.sh [PORT]
```

**Examples:**
```bash
scripts/compose/deploy.sh               # Deploy on port 80
scripts/compose/deploy.sh 8080          # Deploy on port 8080
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
scripts/compose/test.sh
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
scripts/compose/logs.sh [OPTIONS] [ENVIRONMENT]
```

**Options:**
- `-f, --follow`: Follow log output
- `-t, --tail N`: Show last N lines (default: 50)
- `-h, --help`: Show help message

**Examples:**
```bash
scripts/compose/logs.sh                 # Show last 50 lines of dev logs
scripts/compose/logs.sh -f              # Follow dev logs
scripts/compose/logs.sh -t 100 prod     # Show last 100 lines of prod logs
scripts/compose/logs.sh --follow prod   # Follow prod logs
```

### `stop.sh`
Stops running containers for specified environment.

**Usage:**
```bash
scripts/compose/stop.sh [ENVIRONMENT]
```

**Examples:**
```bash
scripts/compose/stop.sh                 # Stop dev containers
scripts/compose/stop.sh prod            # Stop prod containers
scripts/compose/stop.sh all             # Stop all containers
```

### `cleanup.sh`
Comprehensive cleanup of Docker resources with selective options.

**Usage:**
```bash
scripts/compose/cleanup.sh [OPTIONS]
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
scripts/compose/cleanup.sh              # Interactive cleanup of everything
scripts/compose/cleanup.sh --containers # Remove only containers
scripts/compose/cleanup.sh --all --force # Remove everything without prompts
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
scripts/compose/build.sh
scripts/compose/run.sh

# View logs
scripts/compose/logs.sh -f

# Run tests
scripts/compose/test.sh

# Stop when done
scripts/compose/stop.sh
```

### Production Deployment
```bash
# Build and deploy
scripts/compose/build.sh
scripts/compose/deploy.sh

# Monitor logs
scripts/compose/logs.sh -f prod

# Health check
curl http://localhost/docs
```

### Testing Workflow
```bash
# Run tests
scripts/compose/test.sh

# View test results and cleanup automatically
```

### Cleanup Workflow
```bash
# Clean up everything
scripts/compose/cleanup.sh --all

# Or selective cleanup
scripts/compose/cleanup.sh --containers
scripts/compose/cleanup.sh --images --volumes
```

## 🚨 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   scripts/compose/stop.sh all
   scripts/compose/run.sh 3000  # Use different port
   ```

2. **Permission denied**
   ```bash
   chmod +x scripts/compose/*.sh
   ```

3. **Container won't start**
   ```bash
   scripts/compose/logs.sh
   scripts/compose/cleanup.sh --containers
   scripts/compose/build.sh
   ```

4. **Tests failing**
   ```bash
   # Run tests locally first
   uv run pytest -v
   
   # Then in container
   scripts/compose/test.sh
   ```

### Health Check Failures
- Verify `.env` file exists with `GEMINI_API_KEY`
- Check container logs: `scripts/compose/logs.sh`
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
