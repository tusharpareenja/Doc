#!/bin/bash

# Deploy to ARM Server
# Usage: ./deploy-arm.sh [user@host] [tag]
# Example: ./deploy-arm.sh root@91.107.191.124 latest

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SSH_USER_HOST="${1:-root@91.107.191.124}"
TAG="${2:-latest}"
BUILD_DIR="/tmp/docserver-build"
REMOTE_DEPLOY_DIR="/root/docserver-deploy"

echo -e "${YELLOW}╔════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Document Server - ARM64 Deployment      ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "SSH Target: $SSH_USER_HOST"
echo "Image Tag: $TAG"
echo ""

# Step 1: Transfer files to ARM server
echo -e "${YELLOW}[1/5] Transferring project files to ARM server...${NC}"
ssh "$SSH_USER_HOST" "mkdir -p $REMOTE_DEPLOY_DIR"

rsync -avz --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.tar' \
    --exclude '.DS_Store' \
    --exclude 'build-docker-images.*' \
    --exclude 'build-on-*' \
    --exclude 'deploy-to-*' \
    ./ "$SSH_USER_HOST:$REMOTE_DEPLOY_DIR/"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to transfer files${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Files transferred successfully${NC}"
echo ""

# Step 2: Stop existing containers
echo -e "${YELLOW}[2/5] Stopping existing containers on ARM server...${NC}"
ssh "$SSH_USER_HOST" "cd $REMOTE_DEPLOY_DIR && docker-compose down || true"
echo -e "${GREEN}[✓] Containers stopped${NC}"
echo ""

# Step 3: Build Docker image on ARM server
echo -e "${YELLOW}[3/5] Building Docker image on ARM server (this may take several minutes)...${NC}"
ssh "$SSH_USER_HOST" "cd $REMOTE_DEPLOY_DIR && \
    docker build --platform linux/arm64 \
    -f Dockerfile.arm64 \
    -t docserver-v9:${TAG}-arm64 \
    ."

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to build Docker image${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Docker image built successfully${NC}"
echo ""

# Step 4: Start services with docker-compose
echo -e "${YELLOW}[4/5] Starting Docker Compose services...${NC}"
ssh "$SSH_USER_HOST" "cd $REMOTE_DEPLOY_DIR && docker-compose up -d"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to start Docker Compose services${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Services started${NC}"
echo ""

# Step 5: Wait for services to be ready and verify
echo -e "${YELLOW}[5/5] Waiting for services to be ready...${NC}"
sleep 10

# Verify services are running
echo ""
echo -e "${YELLOW}Checking service status...${NC}"
ssh "$SSH_USER_HOST" "docker-compose -f $REMOTE_DEPLOY_DIR/docker-compose.yml ps"

echo ""
echo -e "${YELLOW}Checking Document Server health...${NC}"
ssh "$SSH_USER_HOST" "curl -s http://localhost:8000/healthcheck && echo '' || echo 'Health check endpoint not ready yet'"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ ARM Deployment Completed!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Access Document Server at: http://${SSH_USER_HOST%@*}:8000"
echo "RabbitMQ Management UI: http://${SSH_USER_HOST%@*}:15672 (guest/guest)"
echo ""
echo "Useful commands:"
echo "  SSH into server: ssh $SSH_USER_HOST"
echo "  View logs: docker-compose logs -f docserver"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
