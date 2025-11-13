@echo off
REM Batch script to build Docker images for both ARM and Intel architectures
REM Usage: build-docker-images.bat [image-name] [tag]

setlocal

set IMAGE_NAME=%1
if "%IMAGE_NAME%"=="" set IMAGE_NAME=docserver-v9

set TAG=%2
if "%TAG%"=="" set TAG=latest

echo Building Docker images for both architectures...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running or not installed. Please start Docker Desktop.
    exit /b 1
)

REM Build Intel image
echo.
echo Building Intel image...
set INTEL_IMAGE=%IMAGE_NAME%:%TAG%-intel
docker build --platform linux/amd64 -f Dockerfile.intel -t %INTEL_IMAGE% .

if errorlevel 1 (
    echo Error: Failed to build Intel image
    exit /b 1
)

echo Intel image built successfully: %INTEL_IMAGE%

REM Build ARM64 image
echo.
echo Building ARM64 image...
set ARM64_IMAGE=%IMAGE_NAME%:%TAG%-arm64
docker build --platform linux/arm64 -f Dockerfile.arm64 -t %ARM64_IMAGE% .

if errorlevel 1 (
    echo Error: Failed to build ARM64 image
    exit /b 1
)

echo ARM64 image built successfully: %ARM64_IMAGE%

echo.
echo === Build Summary ===
echo Intel Image: %INTEL_IMAGE%
echo ARM64 Image: %ARM64_IMAGE%
echo.
echo To save images to files, use:
echo   docker save %INTEL_IMAGE% -o %IMAGE_NAME%-%TAG%-intel.tar
echo   docker save %ARM64_IMAGE% -o %IMAGE_NAME%-%TAG%-arm64.tar
echo.
echo To load images on target server, use:
echo   docker load -i %IMAGE_NAME%-%TAG%-intel.tar
echo   docker load -i %IMAGE_NAME%-%TAG%-arm64.tar

endlocal

