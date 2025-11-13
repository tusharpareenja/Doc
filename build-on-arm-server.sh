#!/bin/bash
# Script to build Docker image directly on ARM server via SSH
# Usage: ./build-on-arm-server.sh [ssh-user@host] [image-name] [tag]

SSH_HOST="${1:-user@arm-server}"
IMAGE_NAME="${2:-docserver-v9}"
TAG="${3:-latest}"
ARM64_IMAGE="${IMAGE_NAME}:${TAG}-arm64"

echo "=== Building on ARM Server ==="
echo "SSH Host: $SSH_HOST"
echo "Image: $ARM64_IMAGE"
echo ""

# Transfer project files to server
echo "Transferring project files to server..."
rsync -avz --exclude 'node_modules' --exclude '.git' --exclude '*.tar' \
    ./ "${SSH_HOST}:/tmp/docserver-build/"

# Build image on server
echo "Building image on server..."
ssh "$SSH_HOST" "cd /tmp/docserver-build && \
    docker build --platform linux/arm64 -f Dockerfile.arm64 -t $ARM64_IMAGE ."

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Image $ARM64_IMAGE is now available on the server."
    echo ""
    echo "To test the image, run on the server:"
    echo "  docker run -d -p 8000:8000 --name docserver-test $ARM64_IMAGE"
else
    echo "Build failed!"
    exit 1
fi



