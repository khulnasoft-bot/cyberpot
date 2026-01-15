# CyberPot CI/CD Setup

## ✅ CI/CD Pipeline Successfully Added!

This repository now includes a comprehensive CI/CD pipeline using GitHub Actions.

## 🚀 What's Included

### Workflows

1. **🐳 Docker Build** (`.github/workflows/docker-build.yml`)
   - Multi-architecture builds (amd64/arm64)
   - Automatic image publishing to GHCR
   - Build caching for faster builds

2. **🧪 Backend CI** (`.github/workflows/backend-ci.yml`)
   - TypeScript compilation checks
   - Linting and testing
   - Docker image validation

3. **🎨 Dashboard CI** (`.github/workflows/dashboard-ci.yml`)
   - React/Vite build verification
   - ESLint checks
   - Lighthouse performance audits

4. **🔒 Security Scanning** (`.github/workflows/security-scan.yml`)
   - Dependency vulnerability scanning
   - CodeQL analysis
   - Trivy container scanning
   - Secret detection
   - Daily automated scans

5. **📦 Release Management** (`.github/workflows/release.yml`)
   - Automated releases on version tags
   - Changelog generation
   - Installer package creation
   - Multi-arch image publishing

6. **✅ Pull Request Checks** (`.github/workflows/pr-checks.yml`)
   - Semantic PR validation
   - Component-specific testing
   - ShellCheck for scripts
   - Automatic PR size labeling

7. **📊 Code Quality** (`.github/workflows/code-quality.yml`)
   - ShellCheck analysis
   - YAML linting
   - Dockerfile linting
   - EditorConfig validation

## 📋 Quick Start

### For Contributors

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/khulnasoft/cyberpot.git
   cd cyberpot
   ```

2. **Make your changes**
   - Follow semantic commit conventions
   - Run tests locally before pushing

3. **Create a pull request**
   - PR title format: `<type>(<scope>): <subject>`
   - Example: `feat(dashboard): add new threat visualization`

### For Maintainers

1. **Creating a Release**
   ```bash
   # Update version file
   echo "24.04.1" > version
   
   # Commit and tag
   git add version
   git commit -m "chore: bump version to 24.04.1"
   git tag v24.04.1
   git push origin main --tags
   ```

2. **Manual Workflow Triggers**
   - Go to Actions tab
   - Select workflow
   - Click "Run workflow"

## 🔧 Configuration Files

- `.github/workflows/` - GitHub Actions workflows
- `.github/lighthouse/lighthouserc.json` - Lighthouse CI config
- `.markdownlint.json` - Markdown linting rules
- `.yamllint.yml` - YAML linting rules

## 📚 Documentation

See [`.github/CI_CD.md`](.github/CI_CD.md) for comprehensive documentation including:
- Detailed workflow descriptions
- Troubleshooting guides
- Best practices
- Performance optimization tips

## 🎯 Next Steps

### Recommended Actions

1. **Enable Branch Protection**
   - Go to Settings → Branches
   - Add rule for `main`/`master`
   - Require status checks to pass

2. **Configure Secrets** (if needed)
   - Settings → Secrets → Actions
   - Add any required secrets

3. **Review Security Settings**
   - Enable Dependabot alerts
   - Enable secret scanning
   - Review CodeQL results

4. **Add Tests**
   - Backend: Add unit tests with Jest or Mocha
   - Dashboard: Add component tests with Vitest or Jest
   - Integration: Add E2E tests with Playwright

### Optional Enhancements

- [ ] Add deployment workflows for staging/production
- [ ] Integrate with monitoring services (Sentry, DataDog)
- [ ] Add performance regression testing
- [ ] Set up automated dependency updates (Dependabot/Renovate)
- [ ] Add code coverage reporting (Codecov)

## 🛠️ Local Testing

### Backend
```bash
cd src/backend
npm ci
npm run build
npm test
```

### Dashboard
```bash
cd src/dashboard
npm ci
npm run lint
npm run build
npm run preview
```

### Docker Images
```bash
# Build all images
./docker-build.sh

# Build specific image
cd docker/<component>
docker build -t test-image .
```

## 📊 Monitoring

### Workflow Status
- Check the Actions tab for workflow runs
- View commit status checks on PRs
- Monitor security alerts in Security tab

### Build Artifacts
- Build outputs: 7 days retention
- Security scans: 30 days retention
- Release assets: Permanent

## 🤝 Contributing

1. Read the [CI/CD Documentation](.github/CI_CD.md)
2. Follow semantic commit conventions
3. Ensure all checks pass before requesting review
4. Keep PRs focused and reasonably sized

## 📞 Support

- **Issues**: Use the `ci` label for CI/CD related issues
- **Discussions**: Ask questions in GitHub Discussions
- **Documentation**: See `.github/CI_CD.md` for detailed info

## 🎉 Features

✅ Multi-architecture Docker builds (amd64/arm64)  
✅ Automated testing and linting  
✅ Security vulnerability scanning  
✅ Automated releases  
✅ PR validation and quality checks  
✅ Performance monitoring  
✅ Code quality analysis  
✅ Comprehensive documentation  

---

**Happy Building! 🚀**
