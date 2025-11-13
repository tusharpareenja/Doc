# Docker Image Build and Deployment Guide

This guide explains how to build and deploy Docker images for both Intel and ARM servers.

## Overview

You have two options for building images:
1. **Build locally** (using Docker Desktop with emulation) - Slower but convenient
2. **Build on each server** (native builds) - Faster and more reliable

## Prerequisites

- Docker installed on your local machine (Docker Desktop for Windows)
- Docker installed on both Intel and ARM servers
- SSH access to both servers
- Project files ready for deployment

## Option 1: Build Locally and Deploy

### Step 1: Build Images Locally

On your Windows machine, run:

```powershell
# Build both images
.\build-docker-images.ps1

# Or with custom name/tag
.\build-docker-images.ps1 docserver-v9 v1.0.0
```

This will create:
- `docserver-v9:latest-intel` (for Intel server)
- `docserver-v9:latest-arm64` (for ARM server)

### Step 2: Save Images to Files

```powershell
# Save Intel image
docker save docserver-v9:latest-intel -o docserver-v9-latest-intel.tar

# Save ARM64 image
docker save docserver-v9:latest-arm64 -o docserver-v9-latest-arm64.tar
```

### Step 3: Deploy to Servers

**For Intel Server:**
```bash
# Copy and load image
scp docserver-v9-latest-intel.tar user@intel-server:/tmp/
ssh user@intel-server "docker load -i /tmp/docserver-v9-latest-intel.tar"
```

**For ARM Server:**
```bash
# Copy and load image
scp docserver-v9-latest-arm64.tar user@arm-server:/tmp/
ssh user@arm-server "docker load -i /tmp/docserver-v9-latest-arm64.tar"
```

Or use the deployment scripts:
```bash
./deploy-to-intel-server.sh user@intel-server
./deploy-to-arm-server.sh user@arm-server
```

## Option 2: Build Directly on Servers (Recommended)

This is faster and more reliable since it builds natively on each architecture.

### Build on Intel Server

```bash
# Transfer files and build
./build-on-intel-server.sh user@intel-server docserver-v9 latest
```

Or manually:
```bash
# Transfer project files
rsync -avz --exclude 'node_modules' --exclude '.git' \
    ./ user@intel-server:/tmp/docserver-build/

# Build on server
ssh user@intel-server "cd /tmp/docserver-build && \
    docker build --platform linux/amd64 -f Dockerfile.intel -t docserver-v9:latest-intel ."
```

### Build on ARM Server

```bash
# Transfer files and build
./build-on-arm-server.sh user@arm-server docserver-v9 latest
```

Or manually:
```bash
# Transfer project files
rsync -avz --exclude 'node_modules' --exclude '.git' \
    ./ user@arm-server:/tmp/docserver-build/

# Build on server
ssh user@arm-server "cd /tmp/docserver-build && \
    docker build --platform linux/arm64 -f Dockerfile.arm64 -t docserver-v9:latest-arm64 ."
```

## Testing Images

### Test on Intel Server

```bash
# Run test container
ssh user@intel-server "docker run -d -p 8000:8000 --name docserver-test docserver-v9:latest-intel"

# Check health
ssh user@intel-server "curl http://localhost:8000/healthcheck"

# View logs
ssh user@intel-server "docker logs docserver-test"

# Stop and remove
ssh user@intel-server "docker stop docserver-test && docker rm docserver-test"
```

### Test on ARM Server

```bash
# Run test container
ssh user@arm-server "docker run -d -p 8000:8000 --name docserver-test docserver-v9:latest-arm64"

# Check health
ssh user@arm-server "curl http://localhost:8000/healthcheck"

# View logs
ssh user@arm-server "docker logs docserver-test"

# Stop and remove
ssh user@arm-server "docker stop docserver-test && docker rm docserver-test"
```

### Using Test Script

```bash
# Test Intel image
./test-docker-image.sh user@intel-server docserver-v9:latest-intel 8000

# Test ARM image
./test-docker-image.sh user@arm-server docserver-v9:latest-arm64 8000
```

## Production Deployment

Once tested, deploy to production:

### Intel Server
```bash
ssh user@intel-server "docker run -d \
    --name docserver \
    -p 8000:8000 \
    --restart unless-stopped \
    -v /var/lib/onlyoffice/documentserver:/var/lib/onlyoffice/documentserver \
    docserver-v9:latest-intel"
```

### ARM Server
```bash
ssh user@arm-server "docker run -d \
    --name docserver \
    -p 8000:8000 \
    --restart unless-stopped \
    -v /var/lib/onlyoffice/documentserver:/var/lib/onlyoffice/documentserver \
    docserver-v9:latest-arm64"
```

## Troubleshooting

### Check Docker is running
```bash
ssh user@server "docker info"
```

### Check image architecture
```bash
ssh user@server "docker inspect docserver-v9:latest-intel | grep Architecture"
```

### View build logs
If build fails, check logs:
```bash
ssh user@server "docker build --platform linux/amd64 -f Dockerfile.intel -t test . 2>&1 | tail -50"
```

### Common Issues

1. **Out of disk space**: Clean up Docker
   ```bash
   ssh user@server "docker system prune -a"
   ```

2. **Permission denied**: Ensure user is in docker group
   ```bash
   ssh user@server "sudo usermod -aG docker $USER"
   ```

3. **Network issues**: Check firewall and port availability
   ```bash
   ssh user@server "netstat -tuln | grep 8000"
   ```

## Quick Reference

| Task | Intel Server | ARM Server |
|------|-------------|------------|
| Build | `docker build -f Dockerfile.intel -t docserver-v9:latest-intel .` | `docker build -f Dockerfile.arm64 -t docserver-v9:latest-arm64 .` |
| Test | `docker run -d -p 8000:8000 docserver-v9:latest-intel` | `docker run -d -p 8000:8000 docserver-v9:latest-arm64` |
| Health Check | `curl http://localhost:8000/healthcheck` | `curl http://localhost:8000/healthcheck` |



