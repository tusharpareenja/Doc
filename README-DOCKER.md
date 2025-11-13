# Docker Build Instructions

This document explains how to build Docker images for both Intel (AMD64) and ARM architectures.

## Prerequisites

1. **Docker Desktop** installed and running on Windows
2. **Docker Buildx** enabled (usually comes with Docker Desktop)

## Building Images

### Option 1: Using PowerShell Script (Recommended)

```powershell
.\build-docker-images.ps1
```

Or with custom image name and tag:
```powershell
.\build-docker-images.ps1 my-docserver v1.0.0
```

### Option 2: Using Batch Script

```cmd
build-docker-images.bat
```

Or with custom image name and tag:
```cmd
build-docker-images.bat my-docserver v1.0.0
```

### Option 3: Manual Build

Build Intel/AMD64 image:
```bash
docker build --platform linux/amd64 -f Dockerfile.amd64 -t docserver-v9:latest-amd64 .
```

Build ARM64 image:
```bash
docker build --platform linux/arm64 -f Dockerfile.arm64 -t docserver-v9:latest-arm64 .
```

## Exporting Images

After building, you can save the images to tar files for transfer to your servers:

```bash
# Save AMD64 image
docker save docserver-v9:latest-amd64 -o docserver-v9-latest-amd64.tar

# Save ARM64 image
docker save docserver-v9:latest-arm64 -o docserver-v9-latest-arm64.tar
```

## Loading Images on Target Servers

On your Intel server:
```bash
docker load -i docserver-v9-latest-amd64.tar
docker tag docserver-v9:latest-amd64 docserver-v9:latest
```

On your ARM server:
```bash
docker load -i docserver-v9-latest-arm64.tar
docker tag docserver-v9:latest-arm64 docserver-v9:latest
```

## Running the Containers

### Intel/AMD64 Server
```bash
docker run -d \
  --name docserver \
  -p 8000:8000 \
  docserver-v9:latest-amd64
```

### ARM Server
```bash
docker run -d \
  --name docserver \
  -p 8000:8000 \
  docserver-v9:latest-arm64
```

## Important Notes

1. **Core C++ Components**: The Dockerfiles assume that the C++ core components are either:
   - Pre-built and included in the repository
   - Will be built during the Docker build process
   - Need to be built separately and copied into the image

2. **Configuration**: You may need to adjust:
   - Port numbers in the Dockerfile (currently set to 8000)
   - Environment variables
   - Volume mounts for persistent data
   - Network configuration

3. **Dependencies**: The build process installs Node.js dependencies. If you have issues with native modules (like `sharp` or `oracledb`), you may need to:
   - Ensure the correct architecture-specific binaries are available
   - Rebuild native modules during the Docker build

4. **Build Time**: Building these images can take a significant amount of time, especially if compiling C++ components.

## Troubleshooting

### Build fails with architecture mismatch
- Ensure Docker Buildx is enabled: `docker buildx version`
- Try enabling buildx: `docker buildx create --use`

### Native module build errors
- Some Node.js modules have native dependencies that need to be compiled for the target architecture
- The build process should handle this automatically, but you may need to install additional build tools

### Image size is too large
- Consider using multi-stage builds more aggressively
- Remove unnecessary files in the .dockerignore
- Use Alpine-based images if compatible with your requirements

