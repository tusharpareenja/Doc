#!/bin/bash
# Script to deploy Docker image to ARM server via SSH
# Usage: ./deploy-to-arm-server.sh [ssh-user@host] [image-name] [tag]

SSH_HOST="${1:-user@arm-server}"
IMAGE_NAME="${2:-docserver-v9}"
TAG="${3:-latest}"
ARM64_IMAGE="${IMAGE_NAME}:${TAG}-arm64"

echo "=== Deploying to ARM Server ==="
echo "SSH Host: $SSH_HOST"
echo "Image: $ARM64_IMAGE"
echo ""

# Check if image file exists locally
if [ -f "${IMAGE_NAME}-${TAG}-arm64.tar" ]; then
    echo "Found image file: ${IMAGE_NAME}-${TAG}-arm64.tar"
    echo "Transferring to server..."
    scp "${IMAGE_NAME}-${TAG}-arm64.tar" "${SSH_HOST}:/tmp/"
    
    echo "Loading image on server..."
    ssh "$SSH_HOST" "docker load -i /tmp/${IMAGE_NAME}-${TAG}-arm64.tar && rm /tmp/${IMAGE_NAME}-${TAG}-arm64.tar"
    
    echo "Image loaded successfully!"
else
    echo "Error: Image file ${IMAGE_NAME}-${TAG}-arm64.tar not found."
    echo "Please build and save the image first using:"
    echo "  docker save $ARM64_IMAGE -o ${IMAGE_NAME}-${TAG}-arm64.tar"
    exit 1
fi



