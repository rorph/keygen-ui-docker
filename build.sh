#!/bin/bash
#
# Docker Build Helper Script for Keygen UI
# This script helps build the Docker image with proper build arguments
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
API_URL="${NEXT_PUBLIC_KEYGEN_API_URL:-https://api.keygen.sh/v1}"
ACCOUNT_ID="${NEXT_PUBLIC_KEYGEN_ACCOUNT_ID}"
IMAGE_TAG="${IMAGE_TAG:-keygen-ui:latest}"

echo "================================================"
echo "  Keygen UI - Docker Build Script"
echo "================================================"
echo ""

# Check if .env file exists
if [ -f .env ]; then
    print_info "Found .env file, loading environment variables..."
    export $(grep -v '^#' .env | xargs)
    API_URL="${NEXT_PUBLIC_KEYGEN_API_URL:-https://api.keygen.sh/v1}"
    ACCOUNT_ID="${NEXT_PUBLIC_KEYGEN_ACCOUNT_ID}"
fi

# Check if ACCOUNT_ID is set
if [ -z "$ACCOUNT_ID" ]; then
    print_error "NEXT_PUBLIC_KEYGEN_ACCOUNT_ID is not set!"
    echo ""
    echo "Please set it in one of the following ways:"
    echo ""
    echo "1. Create a .env file with:"
    echo "   NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id"
    echo ""
    echo "2. Export as environment variable:"
    echo "   export NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id"
    echo ""
    echo "3. Pass as argument:"
    echo "   NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=your-account-id ./build.sh"
    echo ""
    exit 1
fi

# Display build configuration
print_info "Build Configuration:"
echo "  API URL:     $API_URL"
echo "  Account ID:  $ACCOUNT_ID"
echo "  Image Tag:   $IMAGE_TAG"
echo ""

# Confirm before building
read -p "Continue with build? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Build cancelled by user"
    exit 0
fi

# Build the image
print_info "Starting Docker build..."
echo ""

docker build \
    --build-arg NEXT_PUBLIC_KEYGEN_API_URL="$API_URL" \
    --build-arg NEXT_PUBLIC_KEYGEN_ACCOUNT_ID="$ACCOUNT_ID" \
    -t "$IMAGE_TAG" \
    .

if [ $? -eq 0 ]; then
    echo ""
    print_info "Build completed successfully! ✓"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name keygen-ui -p 3000:3000 --env-file .env $IMAGE_TAG"
    echo ""
    echo "To view logs:"
    echo "  docker logs -f keygen-ui"
    echo ""
else
    print_error "Build failed!"
    exit 1
fi
