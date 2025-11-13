#!/bin/bash
# Script to deploy Docker image to Intel server via SSH
# Usage: ./deploy-to-intel-server.sh [ssh-user@host] [image-name] [tag]

SSH_HOST="${1:-user@intel-server}"
IMAGE_NAME="${2:-docserver-v9}"
TAG="${3:-latest}"
INTEL_IMAGE="${IMAGE_NAME}:${TAG}-intel"

echo "=== Deploying to Intel Server ==="
echo "SSH Host: $SSH_HOST"
echo "Image: $INTEL_IMAGE"
echo ""

# Check if image file exists locally
if [ -f "${IMAGE_NAME}-${TAG}-intel.tar" ]; then
    echo "Found image file: ${IMAGE_NAME}-${TAG}-intel.tar"
    echo "Transferring to server..."
    scp "${IMAGE_NAME}-${TAG}-intel.tar" "${SSH_HOST}:/tmp/"
    
    echo "Loading image on server..."
    ssh "$SSH_HOST" "docker load -i /tmp/${IMAGE_NAME}-${TAG}-intel.tar && rm /tmp/${IMAGE_NAME}-${TAG}-intel.tar"
    
    echo "Image loaded successfully!"
else
    echo "Error: Image file ${IMAGE_NAME}-${TAG}-intel.tar not found."
    echo "Please build and save the image first using:"
    echo "  docker save $INTEL_IMAGE -o ${IMAGE_NAME}-${TAG}-intel.tar"
    exit 1
fi



