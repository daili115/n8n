#!/bin/bash
#
# This script builds and pushes the n8n Docker image to Docker Hub.
#
# Usage:
#   DOCKER_USERNAME=<your-username> DOCKER_PASSWORD=<your-password> ./scripts/deploy-docker.sh
#
# It requires the following environment variables to be set:
#   - DOCKER_USERNAME: Your Docker Hub username.
#   - DOCKER_PASSWORD: Your Docker Hub password or an access token.

set -e # Exit immediately if a command exits with a non-zero status.

# 1. Check for required environment variables
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
  echo "Error: DOCKER_USERNAME and DOCKER_PASSWORD environment variables must be set."
  exit 1
fi

# 2. Get the n8n version from the root package.json
N8N_VERSION=$(node -p "require('./package.json').version")
if [ -z "$N8N_VERSION" ]; then
  echo "Error: Could not determine n8n version from package.json."
  exit 1
fi

echo "--- Building n8n v$N8N_VERSION ---"

# 3. Build the n8n application
# This is equivalent to the 'setup-and-build' step in the GitHub Actions workflow.
pnpm install --frozen-lockfile
pnpm build:n8n

echo "--- Building and Pushing Docker Image ---"

# 4. Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# 5. Define Docker image tags
IMAGE_NAME="$DOCKER_USERNAME/n8n"
TAG_LATEST="$IMAGE_NAME:latest"
TAG_VERSIONED="$IMAGE_NAME:$N8N_VERSION"

# 6. Build the Docker image
# We're using the main Dockerfile for the n8n application.
docker build -t "$TAG_VERSIONED" \
  --build-arg N8N_VERSION="$N8N_VERSION" \
  -f docker/images/n8n/Dockerfile .

# Also tag it as 'latest'
docker tag "$TAG_VERSIONED" "$TAG_LATEST"

# 7. Push the Docker images to Docker Hub
echo "Pushing image to Docker Hub: $TAG_VERSIONED"
docker push "$TAG_VERSIONED"

echo "Pushing image to Docker Hub: $TAG_LATEST"
docker push "$TAG_LATEST"

echo "--- Deployment Complete ---"
