# PGNi Deployment Script
# Simplified version for Windows deployment

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PGNi API Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$EC2_IP = "34.227.111.143"
$SSH_KEY = "pgni-preprod-key.pem"
$ENV_FILE = "preprod.env"
$DEPLOY_SCRIPT = "deploy-api.sh"

# Check files
Write-Host "Checking files..." -ForegroundColor Yellow

if (-not (Test-Path $SSH_KEY)) {
    Write-Host "Error: SSH key not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "Error: Environment file not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $DEPLOY_SCRIPT)) {
    Write-Host "Error: Deployment script not found!" -ForegroundColor Red
    exit 1
}

Write-Host "All files found!" -ForegroundColor Green
Write-Host ""

# Fix SSH key permissions
Write-Host "Fixing SSH key permissions..." -ForegroundColor Yellow
try {
    icacls $SSH_KEY /inheritance:r | Out-Null
    icacls $SSH_KEY /grant:r "$env:USERNAME`:R" | Out-Null
    Write-Host "SSH key permissions fixed" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not fix permissions" -ForegroundColor Yellow
}

Write-Host ""

# Test connectivity
Write-Host "Testing EC2 connectivity..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $EC2_IP -Count 2 -Quiet

if ($pingResult) {
    Write-Host "EC2 is reachable" -ForegroundColor Green
} else {
    Write-Host "Warning: Cannot ping EC2" -ForegroundColor Yellow
    Write-Host "Continuing anyway..." -ForegroundColor Gray
}

Write-Host ""

# Check SCP
$scpExists = Get-Command scp -ErrorAction SilentlyContinue

if (-not $scpExists) {
    Write-Host "Error: SCP not found!" -ForegroundColor Red
    Write-Host "Please install OpenSSH Client from Windows Settings" -ForegroundColor Yellow
    exit 1
}

# Upload files
Write-Host "Step 1: Uploading environment file..." -ForegroundColor Cyan
scp -i $SSH_KEY -o StrictHostKeyChecking=no $ENV_FILE ec2-user@${EC2_IP}:~/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to upload environment file" -ForegroundColor Red
    exit 1
}

Write-Host "Environment file uploaded!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Uploading deployment script..." -ForegroundColor Cyan
scp -i $SSH_KEY -o StrictHostKeyChecking=no $DEPLOY_SCRIPT ec2-user@${EC2_IP}:~/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to upload deployment script" -ForegroundColor Red
    exit 1
}

Write-Host "Deployment script uploaded!" -ForegroundColor Green
Write-Host ""

# Execute deployment
Write-Host "Step 3: Executing deployment on EC2..." -ForegroundColor Cyan
Write-Host ""

ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x deploy-api.sh && ./deploy-api.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "API URL: http://${EC2_IP}:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test it now:" -ForegroundColor Yellow
    Write-Host "  curl http://${EC2_IP}:8080/health" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs:" -ForegroundColor Yellow
    Write-Host "  ssh -i $SSH_KEY ec2-user@$EC2_IP" -ForegroundColor Cyan
    Write-Host "  sudo journalctl -u pgworld-api -n 50" -ForegroundColor Cyan
    exit 1
}

