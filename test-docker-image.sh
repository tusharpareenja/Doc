#!/bin/bash
# Script to test Docker image on a server
# Usage: ./test-docker-image.sh [ssh-user@host] [image-name:tag] [port]

SSH_HOST="${1:-user@server}"
IMAGE="${2:-docserver-v9:latest-intel}"
PORT="${3:-8000}"
CONTAINER_NAME="docserver-test-$(date +%s)"

echo "=== Testing Docker Image ==="
echo "SSH Host: $SSH_HOST"
echo "Image: $IMAGE"
echo "Port: $PORT"
echo "Container: $CONTAINER_NAME"
echo ""

# Run container on server
echo "Starting container..."
ssh "$SSH_HOST" "docker run -d -p ${PORT}:8000 --name $CONTAINER_NAME $IMAGE"

if [ $? -ne 0 ]; then
    echo "Failed to start container!"
    exit 1
fi

echo "Container started. Waiting for health check..."
sleep 10

# Check container status
echo "Checking container status..."
ssh "$SSH_HOST" "docker ps | grep $CONTAINER_NAME"

# Test health endpoint
echo ""
echo "Testing health endpoint..."
HEALTH_STATUS=$(ssh "$SSH_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:${PORT}/healthcheck || echo '000'")

if [ "$HEALTH_STATUS" = "200" ]; then
    echo "✓ Health check passed (HTTP $HEALTH_STATUS)"
    SUCCESS=true
else
    echo "✗ Health check failed (HTTP $HEALTH_STATUS)"
    SUCCESS=false
fi

# Show container logs
echo ""
echo "Container logs (last 20 lines):"
ssh "$SSH_HOST" "docker logs --tail 20 $CONTAINER_NAME"

# Cleanup option
echo ""
read -p "Do you want to stop and remove the test container? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh "$SSH_HOST" "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
    echo "Container removed."
else
    echo "Container left running. To remove manually:"
    echo "  ssh $SSH_HOST 'docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME'"
fi

if [ "$SUCCESS" = true ]; then
    echo ""
    echo "=== Test Summary ==="
    echo "✓ Image test PASSED"
    exit 0
else
    echo ""
    echo "=== Test Summary ==="
    echo "✗ Image test FAILED"
    exit 1
fi



