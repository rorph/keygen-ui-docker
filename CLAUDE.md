# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides Docker containerization for the Keygen UI Next.js application. It wraps the upstream `keygen-ui` application (as a git submodule) with Docker build configurations, GitHub Actions CI/CD pipelines, and deployment scripts.

**Architecture**: Docker wrapper repository with git submodule
**Base Application**: Next.js 15 + React 19 + TypeScript (located in `keygen-ui/` subdirectory)
**Container Runtime**: Node.js 18 Alpine with multi-stage build optimization

## Repository Structure

```
.
├── keygen-ui/                    # Git submodule - upstream Keygen UI app (DO NOT MODIFY)
├── Dockerfile                    # Multi-stage Docker build configuration
├── build.sh                      # Interactive build helper script
├── .env.example                  # Environment variable template
├── .dockerignore                 # Docker build exclusions
└── .github/workflows/
    ├── docker-build.yml          # Automated Docker build and registry push
    └── docker-security-scan.yml  # Trivy vulnerability scanning
```

**CRITICAL**: The `keygen-ui/` subdirectory is a git submodule. Never modify files within it directly. All Docker/deployment configuration lives in the repository root.

## Development Commands

### Building the Docker Image

**Option 1: Using build script (Recommended)**
```bash
# Interactive build with .env validation
./build.sh
```

**Option 2: Manual Docker build**
```bash
# Requires NEXT_PUBLIC_KEYGEN_ACCOUNT_ID at build time
docker build \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

### Running the Container

```bash
# Basic run with environment file
docker run -d \
  --name keygen-ui \
  -p 3000:3000 \
  --env-file .env \
  keygen-ui:latest

# Custom port mapping
docker run -d -p 8080:3000 --env-file .env keygen-ui:latest

# View logs
docker logs -f keygen-ui

# Stop/start container
docker stop keygen-ui
docker start keygen-ui

# Remove container and image
docker rm keygen-ui
docker rmi keygen-ui:latest
```

### Git Submodule Management

```bash
# Initialize submodule after clone
git submodule update --init --recursive

# Update submodule to latest upstream
cd keygen-ui && git pull origin main && cd ..
git add keygen-ui
git commit -m "Update keygen-ui submodule"

# Check submodule status
git submodule status
```

## Architecture & Build Process

### Multi-Stage Docker Build

The Dockerfile uses three optimized stages:

1. **deps stage**: Installs Node.js dependencies using pnpm with frozen lockfile
2. **builder stage**: Builds Next.js application with Turbopack, requires build-time environment variables
3. **runner stage**: Minimal production image running as non-root user (nextjs:nodejs)

**Key optimization**: Multi-stage build reduces final image size by excluding build tools and dev dependencies.

### Build-Time vs Runtime Environment Variables

**CRITICAL DISTINCTION**: Next.js requires certain environment variables at build time for static rendering:

**Build-time (required as --build-arg)**:
- `NEXT_PUBLIC_KEYGEN_API_URL` - Keygen API endpoint (default: https://api.keygen.sh/v1)
- `NEXT_PUBLIC_KEYGEN_ACCOUNT_ID` - Keygen account ID (REQUIRED, no default)

**Runtime (provided via --env-file or -e)**:
- `KEYGEN_API_URL` - Runtime API URL
- `KEYGEN_ACCOUNT_ID` - Runtime account ID
- `KEYGEN_ADMIN_EMAIL` - Admin authentication email
- `KEYGEN_ADMIN_PASSWORD` - Admin authentication password

**Why this matters**: Next.js pre-renders pages at build time. If you don't provide `NEXT_PUBLIC_*` variables during docker build, the application will be built with missing/default values and won't connect to your Keygen instance at runtime.

### Security Features

- Container runs as non-root user (UID/GID 1001)
- Alpine Linux base for minimal attack surface
- Production dependencies only in final image
- No interactive prompts via `COREPACK_ENABLE_AUTO_PIN=0`
- Trivy security scanning in CI/CD pipeline

## GitHub Actions CI/CD

### Workflow: docker-build.yml

**Triggers**:
- Push to `main`, `master`, `develop` branches
- Pull requests to these branches
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Outputs**:
- Pushes to GitHub Container Registry (ghcr.io) - automatic, no setup needed
- Optionally pushes to Docker Hub if secrets configured

**Image Tags Generated**:
- `latest` - Latest build from default branch
- `main`, `develop` - Branch-specific tags
- `v1.0.0`, `v1.0`, `v1` - Semantic version tags from git tags
- `main-sha123456` - Commit SHA tags
- `pr-123` - Pull request tags

### Workflow: docker-security-scan.yml

**Triggers**:
- Push to `main`/`master`
- Pull requests to `main`/`master`
- Weekly schedule (Mondays 00:00 UTC)
- Manual dispatch

**Features**:
- Trivy vulnerability scanning
- Reports CRITICAL, HIGH, MEDIUM severity issues
- Uploads results to GitHub Security tab (SARIF format)

### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret | Required | Purpose |
|--------|----------|---------|
| `NEXT_PUBLIC_KEYGEN_ACCOUNT_ID` | **YES** | Build-time Keygen account ID |
| `NEXT_PUBLIC_KEYGEN_API_URL` | No | Build-time API URL (defaults to https://api.keygen.sh/v1) |
| `DOCKERHUB_USERNAME` | No | Docker Hub username for publishing |
| `DOCKERHUB_TOKEN` | No | Docker Hub access token |

**Note**: `GITHUB_TOKEN` is automatically provided for GitHub Container Registry (ghcr.io).

### Pulling Published Images

```bash
# From GitHub Container Registry
docker pull ghcr.io/YOUR_USERNAME/keygen-ui:latest

# From Docker Hub (if configured)
docker pull YOUR_DOCKERHUB_USERNAME/keygen-ui:latest
```

## Configuration Files

### .env.example

Template for required environment variables. Copy to `.env` and populate:

```bash
cp .env.example .env
# Edit .env with your Keygen instance details
```

### .dockerignore

Excludes unnecessary files from Docker build context:
- `.git/`, `.github/`
- `node_modules/` (copied from keygen-ui during build)
- `.env*` files (except explicitly included)
- Documentation and CI files

## Troubleshooting

### Build fails: "Missing required environment variables"

**Error**: `Error: Missing required environment variables: NEXT_PUBLIC_KEYGEN_API_URL and NEXT_PUBLIC_KEYGEN_ACCOUNT_ID`

**Cause**: Next.js requires these at build time for static page rendering.

**Solution**: Provide as `--build-arg` during docker build, or use `./build.sh` which reads from `.env`.

### Build fails: General

Clean Docker cache and rebuild:
```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

### Container exits immediately

Check logs for errors:
```bash
docker logs keygen-ui
```

Common causes:
- Missing runtime environment variables in `.env`
- Invalid Keygen credentials
- Port conflicts

### Port 3000 already in use

Change host port mapping:
```bash
docker run -d -p 8080:3000 --env-file .env keygen-ui:latest
# Access at http://localhost:8080
```

### Permission issues

The container runs as non-root user `nextjs:nodejs` (UID/GID 1001). All files are owned correctly during build. If you see permission errors, verify your Docker installation allows non-root containers.

## Important Implementation Notes

### Working with the Submodule

- **NEVER** commit changes inside `keygen-ui/` from this repository
- To update the upstream application: `cd keygen-ui && git pull origin main`
- Commit submodule pointer updates: `git add keygen-ui && git commit -m "Update submodule"`

### Next.js Build Requirements

The application uses:
- **Package Manager**: pnpm (via Corepack) - hardcoded in Dockerfile
- **Bundler**: Turbopack via `next build --turbopack`
- **Node Version**: 18-alpine

Do not change these without testing - they are tightly coupled to the upstream application's requirements.

### Environment Variable Precedence

1. Docker build args (`--build-arg`) - Used during image build
2. Runtime environment (`--env-file` or `-e`) - Used when container starts
3. Default values in Dockerfile - Fallbacks only

Always provide both build-time and runtime variables for consistency.

### GitHub Actions Setup

When setting up a new repository:
1. Add required secret `NEXT_PUBLIC_KEYGEN_ACCOUNT_ID`
2. Workflows will automatically push to ghcr.io (no setup needed)
3. Optionally add Docker Hub secrets for dual-registry publishing
4. Enable GitHub Security tab to view Trivy scan results

### Adding Build Status Badges

```markdown
![Docker Build](https://github.com/YOUR_USERNAME/REPO_NAME/actions/workflows/docker-build.yml/badge.svg)
![Security Scan](https://github.com/YOUR_USERNAME/REPO_NAME/actions/workflows/docker-security-scan.yml/badge.svg)
```

## Development Workflow

1. **Update upstream application** (if needed):
   ```bash
   cd keygen-ui && git pull origin main && cd ..
   git add keygen-ui && git commit -m "Update keygen-ui"
   ```

2. **Test Docker build locally**:
   ```bash
   ./build.sh
   ```

3. **Test container runtime**:
   ```bash
   docker run -d --name test-keygen -p 3000:3000 --env-file .env keygen-ui:latest
   docker logs -f test-keygen
   # Verify at http://localhost:3000
   docker rm -f test-keygen
   ```

4. **Commit and push**:
   ```bash
   git add Dockerfile .github/workflows/
   git commit -m "Update Docker configuration"
   git push origin main
   ```

5. **GitHub Actions automatically builds and publishes** to ghcr.io

## Additional Resources

- **Upstream Application**: The `keygen-ui/` submodule contains a `CLAUDE.md` with Next.js application development details
- **Keygen API Docs**: https://keygen.sh/docs/api/
- **Docker Multi-Stage Builds**: https://docs.docker.com/build/building/multi-stage/
- **GitHub Container Registry**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
