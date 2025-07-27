# GitHub CI/CD Workflows

This directory contains comprehensive GitHub Actions workflows for the FastAPI File Downloader & PDF Summarizer project. These workflows provide automated testing, building, deployment, security scanning, and performance monitoring.

## 📁 Workflow Files

### 🔄 `ci.yml` - Main CI/CD Pipeline
**Triggers:** Push to main/develop, Pull Requests, Manual dispatch

**Jobs:**
- **Test**: Runs containerized tests using Docker Compose
- **Build**: Builds and pushes Docker images to GitHub Container Registry
- **Security Scan**: Vulnerability scanning with Trivy
- **Deploy Staging**: Automated deployment to staging environment
- **Deploy Production**: Automated deployment to production environment
- **Cleanup**: Resource cleanup after deployment

**Features:**
- Multi-platform Docker builds (AMD64, ARM64)
- Container registry integration
- Environment-specific deployments
- Security scanning integration
- Automated cleanup

### 🔍 `pr-validation.yml` - Pull Request Validation
**Triggers:** Pull Request events (opened, synchronize, reopened)

**Jobs:**
- **Validate**: Comprehensive PR validation
- **Size Check**: PR size analysis and recommendations

**Validation Checks:**
- Code quality and syntax validation
- Docker configuration validation
- Local and containerized test execution
- Security scan for hardcoded secrets
- Project structure validation
- Test coverage analysis
- Automated PR commenting with results

### 📦 `dependency-update.yml` - Dependency Management
**Triggers:** Weekly schedule (Mondays 9 AM UTC), Manual dispatch

**Jobs:**
- **Update Dependencies**: Automated dependency updates using UV
- **Security Audit**: Security vulnerability scanning
- **Docker Image Cleanup**: Cleanup old container images
- **Health Check**: Repository health monitoring

**Features:**
- Automated dependency updates with PR creation
- Security vulnerability detection (Safety, TruffleHog)
- Docker security scanning
- Automated issue creation for security alerts
- Repository health monitoring

### 🚀 `release.yml` - Release Management
**Triggers:** Release published, Manual dispatch

**Jobs:**
- **Validate Release**: Version validation and checks
- **Build Release**: Multi-platform release builds
- **Security Scan Release**: Comprehensive security scanning
- **Deploy Release**: Environment-specific deployment
- **Notify Release**: Success/failure notifications
- **Rollback**: Manual rollback capability

**Features:**
- Semantic version validation
- SBOM (Software Bill of Materials) generation
- Critical vulnerability blocking
- Environment-specific deployments
- Deployment tracking and notifications
- Rollback capabilities

### ⚡ `performance.yml` - Performance Monitoring
**Triggers:** Daily schedule (2 AM UTC), Manual dispatch

**Jobs:**
- **Performance Test**: Load testing with Locust
- **Load Test**: Artillery-based load testing
- **Benchmark**: Performance benchmarking with pytest-benchmark
- **Resource Monitoring**: Container resource usage monitoring

**Features:**
- Automated performance regression detection
- Load testing with configurable parameters
- Performance benchmarking and comparison
- Resource usage monitoring and alerting
- Performance issue creation

## 🔧 Setup Requirements

### 1. Repository Secrets
Configure the following secrets in your GitHub repository:

```bash
# Required for container registry
GITHUB_TOKEN  # Automatically provided by GitHub

# Optional: For notifications
SLACK_WEBHOOK_URL     # Slack notifications
DISCORD_WEBHOOK_URL   # Discord notifications

# Optional: For external deployments
DEPLOY_SSH_KEY        # SSH key for deployment servers
KUBE_CONFIG          # Kubernetes configuration
```

### 2. Environment Configuration
Set up GitHub Environments for deployment protection:

- **staging**: Staging environment with optional reviewers
- **production**: Production environment with required reviewers

### 3. Branch Protection Rules
Configure branch protection for `main` and `develop`:

- Require PR reviews
- Require status checks to pass
- Require branches to be up to date
- Restrict pushes to specific users/teams

## 🚀 Workflow Usage

### Development Workflow
1. **Create Feature Branch**: `git checkout -b feature/new-feature`
2. **Make Changes**: Develop your feature
3. **Create PR**: Pull request triggers validation workflow
4. **Review & Merge**: After approval, merge triggers CI/CD pipeline

### Release Workflow
1. **Create Release**: Use GitHub releases or manual workflow dispatch
2. **Automated Build**: Release workflow builds and scans images
3. **Deploy**: Automatic deployment to specified environment
4. **Monitor**: Performance monitoring tracks deployment health

### Hotfix Workflow
1. **Create Hotfix Branch**: `git checkout -b hotfix/critical-fix`
2. **Quick Fix**: Make necessary changes
3. **Emergency Release**: Use manual workflow dispatch for quick deployment
4. **Rollback**: Use rollback job if issues occur

## 📊 Monitoring & Alerts

### Automated Issue Creation
Workflows automatically create GitHub issues for:
- Security vulnerabilities
- Performance degradation
- Deployment failures
- Dependency update failures

### Performance Monitoring
- Daily performance tests
- Resource usage tracking
- Benchmark comparisons
- Threshold-based alerting

### Security Monitoring
- Weekly dependency audits
- Container vulnerability scanning
- Secret detection
- SBOM generation for releases

## 🔧 Customization

### Deployment Targets
Update deployment commands in workflows:

```yaml
# Example: Kubernetes deployment
- name: Deploy to production
  run: |
    kubectl set image deployment/fastapi-app fastapi-app=${{ needs.build.outputs.image-tag }}
    kubectl rollout status deployment/fastapi-app

# Example: Docker Compose deployment
- name: Deploy to production
  run: |
    docker-compose -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.prod.yml up -d
```

### Notification Channels
Add notification integrations:

```yaml
# Slack notification
- name: Notify Slack
  run: |
    curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"🚀 Deployment successful!"}' \
      ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Performance Thresholds
Adjust performance thresholds in `performance.yml`:

```yaml
# Response time threshold (milliseconds)
RESPONSE_TIME_THRESHOLD: 2000

# Failure rate threshold (percentage)
FAILURE_RATE_THRESHOLD: 5

# Resource usage thresholds
CPU_THRESHOLD: 80
MEMORY_THRESHOLD: 400
```

## 🐛 Troubleshooting

### Common Issues

1. **Docker Build Failures**
   - Check Dockerfile syntax
   - Verify base image availability
   - Review dependency installation

2. **Test Failures**
   - Check test environment setup
   - Verify mock configurations
   - Review test data and fixtures

3. **Deployment Issues**
   - Verify environment secrets
   - Check deployment target availability
   - Review network connectivity

4. **Performance Test Failures**
   - Check target endpoint availability
   - Verify test duration and load parameters
   - Review resource constraints

### Debug Commands

```bash
# Local workflow testing
act -j test  # Run test job locally

# Docker build debugging
docker build --progress=plain .

# Performance test debugging
locust --host=http://localhost:8000 --users=1 --spawn-rate=1 --run-time=30s
```

## 📚 Best Practices

### Workflow Design
- Keep jobs focused and atomic
- Use appropriate triggers for each workflow
- Implement proper error handling and cleanup
- Use caching to improve performance

### Security
- Never hardcode secrets in workflows
- Use least-privilege access principles
- Regularly update action versions
- Implement security scanning at multiple stages

### Performance
- Use build caches effectively
- Parallelize independent jobs
- Optimize Docker builds with multi-stage builds
- Monitor workflow execution times

### Maintenance
- Regularly review and update workflows
- Monitor workflow success rates
- Keep action versions up to date
- Document workflow changes

## 🔗 Related Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Setup](../../.docker/README.md)
- [Project Main README](../../README.md)
- [Testing Documentation](../../tests/README.md)

## 🤝 Contributing

When modifying workflows:
1. Test changes in a fork first
2. Update this documentation
3. Consider backward compatibility
4. Add appropriate error handling
5. Update related scripts if necessary
