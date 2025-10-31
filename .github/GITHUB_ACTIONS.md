# GitHub Actions Workflows Documentation

This document provides detailed information about the GitHub Actions workflows in this repository.

## Overview

This repository uses GitHub Actions for continuous integration and delivery (CI/CD) to automatically build, test, and publish Docker images.

## Workflows

### 1. Docker Build and Push

**File:** `.github/workflows/docker-build.yml`

#### Purpose
Automatically builds the Docker image and publishes it to container registries when code changes are pushed.

#### Triggers
- **Push Events:**
  - `main` branch
  - `master` branch
  - `develop` branch
  - Tags matching `v*.*.*` pattern (e.g., v1.0.0, v2.1.3)

- **Pull Request Events:**
  - Targeting `main`, `master`, or `develop` branches
  - Builds image but does NOT push to registries

- **Manual Trigger:**
  - Via GitHub UI: Actions → Docker Build and Push → Run workflow

#### What It Does

1. **Checkout Code:** Clones the repository including submodules
2. **Setup Docker Buildx:** Prepares Docker with advanced build features
3. **Login to Registries:** Authenticates with Docker Hub and GitHub Container Registry
4. **Extract Metadata:** Generates tags and labels based on git ref
5. **Build Image:**
   - For PRs: Builds only (no push)
   - For branches/tags: Builds and pushes to registries
6. **Generate Summary:** Creates a summary of the build in the Actions tab

#### Image Tags

The workflow automatically generates multiple tags:

| Git Event | Generated Tags |
|-----------|---------------|
| Push to `main` | `latest`, `main`, `main-sha123456` |
| Push to `develop` | `develop`, `develop-sha123456` |
| Tag `v1.2.3` | `v1.2.3`, `v1.2`, `v1`, `1.2.3`, `1.2`, `1` |
| PR #42 | `pr-42` (build only, not pushed) |

#### Registries

**GitHub Container Registry (ghcr.io)**
- Always enabled
- Uses `GITHUB_TOKEN` (automatic)
- URL: `ghcr.io/<owner>/keygen-ui:latest`
- Public or private based on repository settings

**Docker Hub (docker.io)**
- Optional (requires secrets)
- URL: `docker.io/<username>/keygen-ui:latest`
- Public by default

#### Performance Optimizations

- **Layer Caching:** Uses GitHub Actions cache to speed up builds
- **Multi-stage Builds:** Dockerfile uses multi-stage builds for smaller images
- **Buildx:** Leverages Docker Buildx for advanced features

#### Permissions Required

```yaml
permissions:
  contents: read        # Read repository code
  packages: write       # Push to GitHub Container Registry
  id-token: write      # Generate tokens
```

---

### 2. Docker Security Scan

**File:** `.github/workflows/docker-security-scan.yml`

#### Purpose
Scans the Docker image for security vulnerabilities and reports findings to GitHub Security.

#### Triggers
- **Push Events:** `main` or `master` branch
- **Pull Request Events:** Targeting `main` or `master`
- **Schedule:** Every Monday at 00:00 UTC
- **Manual Trigger:** Via GitHub UI

#### What It Does

1. **Checkout Code:** Clones the repository
2. **Setup Docker Buildx:** Prepares Docker build environment
3. **Build Image:** Builds the image with tag `keygen-ui:scan`
4. **Run Trivy Scanner:**
   - Scans for vulnerabilities in OS packages and dependencies
   - Checks against CVE databases
5. **Upload SARIF Results:** Sends findings to GitHub Security tab
6. **Display Table:** Shows vulnerability summary in workflow logs

#### Vulnerability Severities

- **CRITICAL:** Immediate action required
- **HIGH:** Should be addressed soon
- **MEDIUM:** Should be reviewed
- **LOW:** Informational (not reported by default)

#### Viewing Results

**GitHub Security Tab:**
1. Go to repository **Security** tab
2. Click **Code scanning alerts**
3. View Trivy findings with details and remediation

**Workflow Logs:**
- Check the "Run Trivy vulnerability scanner (Table output)" step
- View formatted table of vulnerabilities

#### Permissions Required

```yaml
permissions:
  contents: read          # Read repository code
  security-events: write  # Upload to Security tab
```

---

## Configuration

### Repository Secrets

Set up secrets in **Settings → Secrets and variables → Actions**

#### Required: Keygen Configuration

| Secret | Required | Description |
|--------|----------|-------------|
| `NEXT_PUBLIC_KEYGEN_ACCOUNT_ID` | **Yes** | Your Keygen account ID |
| `NEXT_PUBLIC_KEYGEN_API_URL` | No | Your Keygen API URL (defaults to https://api.keygen.sh/v1) |

**Why these are needed:**
- Next.js pre-renders pages at build time
- Pages use these values to connect to your Keygen instance
- They are embedded into the application bundle during the build

**Important:** These values are public (NEXT_PUBLIC_ prefix means they're exposed to the browser). Don't put sensitive information here.

#### Optional: Docker Hub Publishing

| Secret | Required | Description |
|--------|----------|-------------|
| `DOCKERHUB_USERNAME` | No | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | No | Access token from Docker Hub |

**Creating Docker Hub Token:**
1. Log in to [Docker Hub](https://hub.docker.com)
2. Go to **Account Settings → Security**
3. Click **New Access Token**
4. Name: `github-actions`, Permissions: `Read & Write`
5. Copy token and add to GitHub secrets

#### Automatic: GitHub Container Registry

No secrets needed! Uses `GITHUB_TOKEN` automatically.

### Repository Settings

**GitHub Container Registry Package Visibility:**
1. Go to repository **Packages** section
2. Click on `keygen-ui` package
3. **Package settings → Change visibility**
4. Choose Public or Private

---

## Usage Examples

### Pull from GitHub Container Registry

```bash
# Pull latest image
docker pull ghcr.io/YOUR_USERNAME/keygen-ui:latest

# Pull specific version
docker pull ghcr.io/YOUR_USERNAME/keygen-ui:v1.0.0

# Pull from branch
docker pull ghcr.io/YOUR_USERNAME/keygen-ui:develop
```

### Pull from Docker Hub

```bash
# Pull latest image
docker pull YOUR_DOCKERHUB_USERNAME/keygen-ui:latest

# Pull specific version
docker pull YOUR_DOCKERHUB_USERNAME/keygen-ui:v1.0.0
```

### Run from Registry

```bash
# From GitHub Container Registry
docker run -d \
  --name keygen-ui \
  -p 3000:3000 \
  --env-file .env \
  ghcr.io/YOUR_USERNAME/keygen-ui:latest

# From Docker Hub
docker run -d \
  --name keygen-ui \
  -p 3000:3000 \
  --env-file .env \
  YOUR_DOCKERHUB_USERNAME/keygen-ui:latest
```

---

## Troubleshooting

### Build Failures

**Problem:** Workflow fails during build
```bash
ERROR: failed to solve: process "/bin/sh -c pnpm install" did not complete successfully
```

**Solution:**
1. Check if keygen-ui submodule is properly initialized
2. Verify Dockerfile syntax
3. Check if all required files exist in context

### Permission Denied Pushing to GHCR

**Problem:**
```
denied: permission_denied: write_package
```

**Solution:**
1. Go to **Settings → Actions → General**
2. Scroll to **Workflow permissions**
3. Select **Read and write permissions**
4. Save changes

### Docker Hub Authentication Failed

**Problem:**
```
Error: Cannot perform an interactive login from a non TTY device
```

**Solution:**
1. Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are set
2. Ensure token has not expired
3. Regenerate token if needed

### Security Scan Not Appearing

**Problem:** Trivy scan completes but no results in Security tab

**Solution:**
1. Check **Settings → Code security and analysis**
2. Enable **Code scanning**
3. Verify workflow has `security-events: write` permission

---

## Best Practices

### Version Tagging

Use semantic versioning for releases:

```bash
# Create and push a version tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

This automatically triggers:
- Docker build
- Multiple version tags (v1.0.0, v1.0, v1)
- GitHub release (if configured)

### Branch Protection

Recommended branch protection rules:

1. **Settings → Branches → Add rule**
2. Branch name pattern: `main` or `master`
3. Enable:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass
   - ✅ Include administrators

### Security Monitoring

1. Enable **Dependabot alerts** in repository settings
2. Review security scan results weekly
3. Set up notifications for critical vulnerabilities

---

## Customization

### Modify Build Triggers

Edit `.github/workflows/docker-build.yml`:

```yaml
on:
  push:
    branches:
      - main
      - feature/*  # Add pattern for feature branches
```

### Add Multi-Platform Builds

Add platform support in build step:

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64  # Add ARM support
```

### Customize Security Scan Schedule

Edit `.github/workflows/docker-security-scan.yml`:

```yaml
schedule:
  # Run daily at 2:00 AM
  - cron: '0 2 * * *'
```

---

## Monitoring

### Build Status

View all workflow runs:
- Go to **Actions** tab
- See status of recent builds
- Click on run for detailed logs

### Build Metrics

Track:
- Build duration
- Cache hit rate
- Image size
- Push success rate

### Notifications

Set up notifications:
1. **Settings → Notifications**
2. Configure **GitHub Actions** alerts
3. Choose email or Slack integration

---

## Support

For issues with workflows:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Open an issue in the repository
