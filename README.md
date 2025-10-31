# Keygen UI - Docker Build

This repository contains the Docker configuration to build and run the Keygen UI application in an isolated container.

## Prerequisites

- Docker installed on your system
- Keygen account with API access

## Quick Start

### 1. Configure Environment Variables

Create a `.env` file in this directory with your Keygen instance details:

```bash
cp .env.example .env
```

Edit the `.env` file and update with your actual values:

```env
KEYGEN_API_URL=https://api.keygen.sh/v1
KEYGEN_ACCOUNT_ID=your-account-id
KEYGEN_ADMIN_EMAIL=your-email@example.com
KEYGEN_ADMIN_PASSWORD=your-secure-password
```

### 2. Build the Docker Image

**Important:** Next.js requires certain environment variables at build time. You have two options:

#### Option A: Using the build script (Recommended)

```bash
./build.sh
```

The script will automatically read your `.env` file and build the image with the correct parameters.

#### Option B: Manual build

```bash
docker build \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

Replace `your-account-id` with your actual Keygen account ID.

This will:
- Install dependencies using pnpm
- Build the Next.js application with Turbopack using your instance details
- Create an optimized production image

### 3. Run the Container

```bash
docker run -d \
  --name keygen-ui \
  -p 3000:3000 \
  --env-file .env \
  keygen-ui:latest
```

### 4. Access the Application

Open your browser and navigate to:
```
http://localhost:3000
```

## GitHub Actions CI/CD

This repository includes automated Docker builds using GitHub Actions.

### Automated Workflows

#### 1. Docker Build and Push (`.github/workflows/docker-build.yml`)

**Triggers:**
- Push to `main`, `master`, or `develop` branches
- Pull requests to `main`, `master`, or `develop` branches
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Features:**
- Builds Docker image with layer caching
- Pushes to GitHub Container Registry (ghcr.io)
- Optionally pushes to Docker Hub
- Automatic semantic versioning tags
- Build summary in workflow output

**Tags Generated:**
- `latest` (on default branch)
- `main`, `develop` (branch names)
- `v1.0.0`, `v1.0`, `v1` (semantic versions)
- `main-sha123456` (commit SHA)
- `pr-123` (pull request number)

#### 2. Docker Security Scan (`.github/workflows/docker-security-scan.yml`)

**Triggers:**
- Push to `main` or `master`
- Pull requests to `main` or `master`
- Weekly schedule (Mondays at 00:00 UTC)
- Manual workflow dispatch

**Features:**
- Scans for vulnerabilities using Trivy
- Uploads results to GitHub Security tab
- Reports CRITICAL, HIGH, and MEDIUM severity issues

### GitHub Actions Setup

#### Required Secrets

The GitHub Actions workflow requires certain secrets to build the Docker image. Add these to your repository:

1. Go to **Settings → Secrets and variables → Actions**
2. Add the following secrets:

| Secret Name | Required | Description |
|-------------|----------|-------------|
| `NEXT_PUBLIC_KEYGEN_ACCOUNT_ID` | **Yes** | Your Keygen account ID |
| `NEXT_PUBLIC_KEYGEN_API_URL` | No | Your Keygen API URL (defaults to https://api.keygen.sh/v1) |
| `DOCKERHUB_USERNAME` | No | Your Docker Hub username (for Docker Hub publishing) |
| `DOCKERHUB_TOKEN` | No | Docker Hub access token ([create here](https://hub.docker.com/settings/security)) |

**Note:** The `NEXT_PUBLIC_*` variables are needed at build time because Next.js pre-renders pages that use these values.

#### GitHub Container Registry (No Setup Required)

The workflow automatically pushes to GitHub Container Registry (ghcr.io) using `GITHUB_TOKEN`. No additional configuration needed!

### Pulling Images from Registries

#### From GitHub Container Registry
```bash
docker pull ghcr.io/YOUR_USERNAME/keygen-ui:latest
```

#### From Docker Hub (if configured)
```bash
docker pull YOUR_DOCKERHUB_USERNAME/keygen-ui:latest
```

### Manual Workflow Trigger

1. Go to **Actions** tab in your repository
2. Select **Docker Build and Push** workflow
3. Click **Run workflow**
4. Choose the branch and click **Run workflow**

### Build Status Badges

Add these badges to your README to show build status:

```markdown
![Docker Build](https://github.com/YOUR_USERNAME/REPO_NAME/actions/workflows/docker-build.yml/badge.svg)
![Security Scan](https://github.com/YOUR_USERNAME/REPO_NAME/actions/workflows/docker-security-scan.yml/badge.svg)
```

## Docker Commands

### Build the image
```bash
docker build \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

### Run the container
```bash
docker run -d \
  --name keygen-ui \
  -p 3000:3000 \
  --env-file .env \
  keygen-ui:latest
```

### Run with custom port
```bash
docker run -d \
  --name keygen-ui \
  -p 8080:3000 \
  --env-file .env \
  keygen-ui:latest
```

### View logs
```bash
docker logs keygen-ui
```

### Follow logs in real-time
```bash
docker logs -f keygen-ui
```

### Stop the container
```bash
docker stop keygen-ui
```

### Start the container
```bash
docker start keygen-ui
```

### Remove the container
```bash
docker rm keygen-ui
```

### Remove the image
```bash
docker rmi keygen-ui:latest
```

## Environment Variables

The following environment variables are required:

| Variable | Description | Example |
|----------|-------------|---------|
| `KEYGEN_API_URL` | Keygen API endpoint | `https://api.keygen.sh/v1` |
| `KEYGEN_ACCOUNT_ID` | Your Keygen account ID | `aca05a24-461a-4db5-8ed1-c12b6040d1c6` |
| `KEYGEN_ADMIN_EMAIL` | Admin email for authentication | `admin@example.com` |
| `KEYGEN_ADMIN_PASSWORD` | Admin password | `your-secure-password` |

## Multi-Stage Build

This Dockerfile uses a multi-stage build for optimization:

1. **deps** - Installs dependencies
2. **builder** - Builds the Next.js application
3. **runner** - Runs the production server (minimal image)

## Troubleshooting

### Build fails with "Missing required environment variables"

**Error:**
```
Error: Missing required environment variables: NEXT_PUBLIC_KEYGEN_API_URL and NEXT_PUBLIC_KEYGEN_ACCOUNT_ID
```

**Solution:**
You must provide these values as build arguments:
```bash
docker build \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

**Why?** Next.js pre-renders pages at build time that require these variables to connect to your Keygen instance.

### Build fails - general

If the build fails, try cleaning Docker cache:
```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1 \
  --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id \
  -t keygen-ui:latest .
```

### Port already in use

If port 3000 is already in use, change the port mapping:
```bash
docker run -d -p 8080:3000 --env-file .env keygen-ui:latest
```

### Container exits immediately

Check the logs for errors:
```bash
docker logs keygen-ui
```

### Permission issues

The container runs as a non-root user (nextjs:nodejs) for security. All files are properly owned by this user during the build process.

### Interactive prompts from Corepack

If you see prompts about downloading pnpm, rebuild the image with the latest Dockerfile which includes `COREPACK_ENABLE_AUTO_PIN=0` to disable interactive prompts.

## Project Structure

```
.
├── keygen-ui/              # Original keygen-ui repository (not modified)
├── Dockerfile              # Multi-stage Docker build
├── .dockerignore           # Files to exclude from build
├── .env.example            # Environment variables template
└── README.md               # This file
```

## Notes

- The `keygen-ui` folder remains untouched - all Docker configuration is in the parent directory
- The application runs on port 3000 inside the container
- Built with Node.js 18 Alpine for minimal image size
- Uses pnpm as the package manager (as required by the application)
- Includes Turbopack for optimized builds

## Security

- Container runs as non-root user
- Production dependencies only in final image
- Environment variables for sensitive configuration
- Alpine Linux base image for minimal attack surface

## License

See the LICENSE file in the keygen-ui directory for application license details.
