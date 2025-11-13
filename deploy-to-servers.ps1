# PowerShell script to deploy Docker images to Intel and ARM servers
# Usage: .\deploy-to-servers.ps1 -IntelHost "user@intel-server" -ArmHost "user@arm-server" -ImageName "docserver-v9" -Tag "latest"

param(
    [Parameter(Mandatory=$true)]
    [string]$IntelHost,
    
    [Parameter(Mandatory=$true)]
    [string]$ArmHost,
    
    [string]$ImageName = "docserver-v9",
    [string]$Tag = "latest"
)

$IntelImage = "${ImageName}:${Tag}-intel"
$Arm64Image = "${ImageName}:${Tag}-arm64"
$IntelTar = "${ImageName}-${Tag}-intel.tar"
$Arm64Tar = "${ImageName}-${Tag}-arm64.tar"

Write-Host "=== Deploying Docker Images to Servers ===" -ForegroundColor Cyan
Write-Host "Intel Server: $IntelHost" -ForegroundColor Yellow
Write-Host "ARM Server: $ArmHost" -ForegroundColor Yellow
Write-Host ""

# Check if images exist locally
Write-Host "Checking for local images..." -ForegroundColor Green
$intelExists = docker images -q $IntelImage
$arm64Exists = docker images -q $Arm64Image

if (-not $intelExists) {
    Write-Host "Error: Intel image $IntelImage not found locally." -ForegroundColor Red
    Write-Host "Please build it first using: .\build-docker-images.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not $arm64Exists) {
    Write-Host "Error: ARM64 image $Arm64Image not found locally." -ForegroundColor Red
    Write-Host "Please build it first using: .\build-docker-images.ps1" -ForegroundColor Yellow
    exit 1
}

# Save images to files
Write-Host "`nSaving images to files..." -ForegroundColor Green
if (-not (Test-Path $IntelTar)) {
    Write-Host "Saving Intel image..." -ForegroundColor Yellow
    docker save $IntelImage -o $IntelTar
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to save Intel image" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Intel image file already exists: $IntelTar" -ForegroundColor Gray
}

if (-not (Test-Path $Arm64Tar)) {
    Write-Host "Saving ARM64 image..." -ForegroundColor Yellow
    docker save $Arm64Image -o $Arm64Tar
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to save ARM64 image" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ARM64 image file already exists: $Arm64Tar" -ForegroundColor Gray
}

# Deploy to Intel server
Write-Host "`n=== Deploying to Intel Server ===" -ForegroundColor Cyan
Write-Host "Transferring $IntelTar to $IntelHost..." -ForegroundColor Yellow
scp $IntelTar "${IntelHost}:/tmp/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to transfer Intel image" -ForegroundColor Red
    exit 1
}

Write-Host "Loading image on Intel server..." -ForegroundColor Yellow
ssh $IntelHost "docker load -i /tmp/$IntelTar && rm /tmp/$IntelTar"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to load image on Intel server" -ForegroundColor Red
    exit 1
}

Write-Host "Intel image deployed successfully!" -ForegroundColor Green

# Deploy to ARM server
Write-Host "`n=== Deploying to ARM Server ===" -ForegroundColor Cyan
Write-Host "Transferring $Arm64Tar to $ArmHost..." -ForegroundColor Yellow
scp $Arm64Tar "${ArmHost}:/tmp/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to transfer ARM64 image" -ForegroundColor Red
    exit 1
}

Write-Host "Loading image on ARM server..." -ForegroundColor Yellow
ssh $ArmHost "docker load -i /tmp/$Arm64Tar && rm /tmp/$Arm64Tar"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to load image on ARM server" -ForegroundColor Red
    exit 1
}

Write-Host "ARM64 image deployed successfully!" -ForegroundColor Green

Write-Host "`n=== Deployment Summary ===" -ForegroundColor Cyan
Write-Host "✓ Intel image deployed to: $IntelHost" -ForegroundColor Green
Write-Host "✓ ARM64 image deployed to: $ArmHost" -ForegroundColor Green
Write-Host "`nTo test the images, run:" -ForegroundColor Yellow
Write-Host "  ssh $IntelHost 'docker run -d -p 8000:8000 --name docserver-test $IntelImage'" -ForegroundColor Gray
Write-Host "  ssh $ArmHost 'docker run -d -p 8000:8000 --name docserver-test $Arm64Image'" -ForegroundColor Gray



