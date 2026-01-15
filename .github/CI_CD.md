# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for the CyberPot project.

## Overview

The CyberPot CI/CD pipeline is built using GitHub Actions and provides comprehensive automation for:

- 🐳 **Docker Image Building** - Multi-architecture (amd64/arm64) container builds
- 🧪 **Testing** - Backend and frontend testing and validation
- 🔒 **Security Scanning** - Automated vulnerability detection
- 📦 **Release Management** - Automated version releases and artifact publishing
- ✅ **Pull Request Validation** - Automated PR checks and quality gates

## Workflows

### 1. Docker Build (`docker-build.yml`)

**Triggers:**
- Push to `master`, `main`, or `develop` branches
- Pull requests
- Manual workflow dispatch

**What it does:**
- Discovers all Dockerfiles in the `docker/` directory
- Builds multi-architecture images (linux/amd64, linux/arm64)
- Pushes images to GitHub Container Registry (GHCR)
- Uses build caching for faster builds

**Usage:**
```bash
# Images are automatically built on push
# Manual trigger via GitHub UI: Actions → Docker Build → Run workflow

# Images are tagged with:
# - Branch name (e.g., main, develop)
# - Version from version file
# - latest (for default branch)
# - Semver tags (for releases)
```

**Environment Variables:**
- `REGISTRY`: ghcr.io
- `IMAGE_PREFIX`: ghcr.io/khulnasoft-bot

### 2. Backend CI (`backend-ci.yml`)

**Triggers:**
- Changes to `src/backend/**`
- Pull requests affecting backend

**What it does:**
- Runs TypeScript compilation checks
- Executes linting (if configured)
- Runs tests across Node.js 18.x and 20.x
- Builds Docker image for backend
- Uploads build artifacts

**Local Testing:**
```bash
cd src/backend
npm ci
npx tsc --noEmit
npm test
```

### 3. Dashboard CI (`dashboard-ci.yml`)

**Triggers:**
- Changes to `src/dashboard/**`
- Pull requests affecting dashboard

**What it does:**
- Runs ESLint checks
- TypeScript compilation validation
- Production build verification
- Docker image build test
- Lighthouse performance audits

**Local Testing:**
```bash
cd src/dashboard
npm ci
npm run lint
npm run build
npm run preview
```

### 4. Security Scanning (`security-scan.yml`)

**Triggers:**
- Push to main branches
- Pull requests
- Daily at 2 AM UTC (scheduled)
- Manual workflow dispatch

**What it does:**
- **Dependency Scanning**: npm audit for vulnerabilities
- **CodeQL Analysis**: Static code analysis for security issues
- **Trivy Scanning**: Container and filesystem vulnerability scanning
- **Secret Scanning**: TruffleHog for exposed secrets
- **Docker Security**: Image vulnerability scanning

**Viewing Results:**
- Security tab in GitHub repository
- Workflow run artifacts
- SARIF uploads for detailed analysis

### 5. Release (`release.yml`)

**Triggers:**
- Push of version tags (e.g., `v24.04.1`)
- Manual workflow dispatch with version input

**What it does:**
- Creates GitHub release with changelog
- Builds and publishes all Docker images with version tags
- Creates installer package with checksums
- Uploads release artifacts

**Creating a Release:**
```bash
# 1. Update version file
echo "24.04.1" > version

# 2. Commit and tag
git add version
git commit -m "chore: bump version to 24.04.1"
git tag v24.04.1
git push origin main --tags

# Or use GitHub UI:
# Actions → Release → Run workflow → Enter version
```

### 6. Pull Request Checks (`pr-checks.yml`)

**Triggers:**
- Pull request opened, synchronized, or reopened

**What it does:**
- Validates PR title (semantic commits)
- Detects changed components
- Runs component-specific tests
- ShellCheck for bash scripts
- Markdown linting
- Automatic PR size labeling

**PR Title Format:**
```
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Example: feat(dashboard): add AI threat analysis component
```

## Secrets and Configuration

### Required Secrets

The following secrets are automatically available via GitHub:
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

### Optional Secrets

For enhanced functionality, you may configure:
- Docker Hub credentials (if pushing to Docker Hub)
- Slack/Discord webhooks for notifications
- Additional security scanning tokens

## Branch Protection

Recommended branch protection rules for `main`/`master`:

1. ✅ Require pull request reviews (1+ approvals)
2. ✅ Require status checks to pass:
   - Backend CI (if backend changed)
   - Dashboard CI (if dashboard changed)
   - Security Scanning
   - PR Checks
3. ✅ Require branches to be up to date
4. ✅ Require signed commits (recommended)
5. ✅ Include administrators

## Caching Strategy

The pipeline uses GitHub Actions cache for:
- Docker layer caching (buildx)
- npm dependencies (node_modules)
- Build artifacts

**Cache Keys:**
- Docker: `type=gha` (GitHub Actions cache)
- npm: Based on `package-lock.json` hash

## Multi-Architecture Support

All Docker images are built for:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Raspberry Pi)

This enables deployment on:
- Standard x86 servers
- Raspberry Pi 4 (8GB)
- ARM-based cloud instances
- Apple Silicon (development)

## Monitoring and Notifications

### Workflow Status

Monitor workflow status:
1. GitHub repository → Actions tab
2. Commit status checks
3. Pull request checks

### Build Artifacts

Artifacts are retained for:
- Build outputs: 7 days
- Security scan results: 30 days
- Release assets: Indefinitely

## Troubleshooting

### Common Issues

**1. Docker Build Fails**
```bash
# Check Dockerfile syntax
docker build -f docker/<component>/Dockerfile docker/<component>

# Verify buildx is available
docker buildx version
```

**2. npm ci Fails**
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm ci
```

**3. Permission Denied for GHCR**
- Ensure `GITHUB_TOKEN` has `packages: write` permission
- Check repository settings → Actions → General → Workflow permissions

**4. Security Scan Failures**
- Review Security tab for details
- Check SARIF uploads in workflow artifacts
- Address critical/high vulnerabilities

### Debug Mode

Enable debug logging:
1. Repository Settings → Secrets → Actions
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Add secret: `ACTIONS_RUNNER_DEBUG` = `true`

## Performance Optimization

### Build Time Optimization

1. **Parallel Jobs**: Workflows run jobs in parallel when possible
2. **Build Cache**: Docker layer caching reduces rebuild time
3. **Conditional Execution**: Jobs only run when relevant files change
4. **Matrix Strategy**: Tests run concurrently across Node versions

### Resource Usage

- **Concurrent Workflows**: GitHub free tier allows 20 concurrent jobs
- **Build Minutes**: Monitor usage in Settings → Billing
- **Storage**: Clean up old artifacts regularly

## Best Practices

### For Contributors

1. ✅ Run tests locally before pushing
2. ✅ Follow semantic commit conventions
3. ✅ Keep PRs focused and small
4. ✅ Update tests with code changes
5. ✅ Review security scan results

### For Maintainers

1. ✅ Review and approve workflow changes carefully
2. ✅ Monitor security scan results regularly
3. ✅ Keep dependencies updated
4. ✅ Test releases in staging before production
5. ✅ Document breaking changes in releases

## Continuous Improvement

The CI/CD pipeline is continuously improved. Suggestions for enhancements:

1. **Testing**: Add integration and E2E tests
2. **Performance**: Implement performance regression testing
3. **Deployment**: Add automated deployment to staging/production
4. **Monitoring**: Integrate with monitoring and alerting systems
5. **Documentation**: Keep this document updated with changes

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Support

For CI/CD related issues:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Open an issue with the `ci` label
4. Contact maintainers in discussions

---

**Last Updated**: 2026-01-15
**Maintained By**: CyberPot Team
