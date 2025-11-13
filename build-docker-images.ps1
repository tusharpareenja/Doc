# PowerShell script to build Docker images for both ARM and Intel architectures
# Usage: .\build-docker-images.ps1 [image-name] [tag]

param(
    [string]$ImageName = "docserver-v9",
    [string]$Tag = "latest"
)

Write-Host "Building Docker images for both architectures..." -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Error: Docker is not running or not installed. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Build Intel image
Write-Host "`nBuilding Intel image..." -ForegroundColor Yellow
$intelImage = "${ImageName}:${Tag}-intel"
docker build --platform linux/amd64 -f Dockerfile.intel -t $intelImage .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Intel image" -ForegroundColor Red
    exit 1
}

Write-Host "Intel image built successfully: $intelImage" -ForegroundColor Green

# Build ARM64 image
Write-Host "`nBuilding ARM64 image..." -ForegroundColor Yellow
$arm64Image = "${ImageName}:${Tag}-arm64"
docker build --platform linux/arm64 -f Dockerfile.arm64 -t $arm64Image .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build ARM64 image" -ForegroundColor Red
    exit 1
}

Write-Host "ARM64 image built successfully: $arm64Image" -ForegroundColor Green

Write-Host "`n=== Build Summary ===" -ForegroundColor Cyan
Write-Host "Intel Image: $intelImage" -ForegroundColor White
Write-Host "ARM64 Image: $arm64Image" -ForegroundColor White
Write-Host "`nTo save images to files, use:" -ForegroundColor Yellow
Write-Host "  docker save $intelImage -o ${ImageName}-${Tag}-intel.tar" -ForegroundColor Gray
Write-Host "  docker save $arm64Image -o ${ImageName}-${Tag}-arm64.tar" -ForegroundColor Gray
Write-Host "`nTo load images on target server, use:" -ForegroundColor Yellow
Write-Host "  docker load -i ${ImageName}-${Tag}-intel.tar" -ForegroundColor Gray
Write-Host "  docker load -i ${ImageName}-${Tag}-arm64.tar" -ForegroundColor Gray

