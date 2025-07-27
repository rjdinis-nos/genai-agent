# Security Policy

## Supported Versions

We actively support the following versions of GenAI Agent:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

### 1. Do NOT create a public GitHub issue

### 2. Report privately via one of these methods:
- **GitHub Security Advisories**: Use the "Report a vulnerability" button in the Security tab
- **Email**: Send details to the repository maintainers

### 3. Include the following information:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if available)

### 4. Response Timeline:
- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (Critical: 1-7 days, High: 7-30 days)

## Security Measures

### GitHub Actions Security
- All actions are pinned to specific versions or commit SHAs
- Minimal required permissions for each workflow
- Secret scanning enabled via TruffleHog
- Container vulnerability scanning via Trivy
- Dependency vulnerability monitoring

### Container Security
- Multi-stage Docker builds to minimize attack surface
- Non-root user execution in containers
- Regular base image updates
- Vulnerability scanning in CI/CD pipeline

### Dependency Security
- Automated dependency updates via Dependabot
- Security audit on all dependencies
- Pinned Python package versions
- Regular security scanning

### Code Security
- Branch protection rules enforced
- Required PR reviews before merge
- Automated security scanning on PRs
- Secret detection in commits

## Security Best Practices

### For Contributors:
1. Never commit secrets, API keys, or credentials
2. Use environment variables for sensitive configuration
3. Follow secure coding practices
4. Keep dependencies updated
5. Run security scans locally before submitting PRs

### For Deployments:
1. Use secure environment variable management
2. Enable container security scanning
3. Implement proper access controls
4. Monitor for security alerts
5. Keep runtime environments updated

## Security Contacts

For security-related questions or concerns, please contact the maintainers through the private reporting methods listed above.

## Acknowledgments

We appreciate the security research community and will acknowledge researchers who responsibly disclose vulnerabilities (with their permission).
