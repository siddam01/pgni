# PGNi Deployment from Windows
# Run this script from your project root directory

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PGNi Deployment from Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$EC2_IP = "34.227.111.143"
$SSH_KEY = "pgni-preprod-key.pem"
$ENV_FILE = "preprod.env"
$DEPLOY_SCRIPT = "deploy-api.sh"

# Verify files exist
Write-Host "Checking required files..." -ForegroundColor Yellow
Write-Host ""

$filesOk = $true

if (Test-Path $SSH_KEY) {
    Write-Host "  ✓ SSH Key found: $SSH_KEY" -ForegroundColor Green
} else {
    Write-Host "  ✗ SSH Key not found: $SSH_KEY" -ForegroundColor Red
    $filesOk = $false
}

if (Test-Path $ENV_FILE) {
    Write-Host "  ✓ Environment file found: $ENV_FILE" -ForegroundColor Green
} else {
    Write-Host "  ✗ Environment file not found: $ENV_FILE" -ForegroundColor Red
    $filesOk = $false
}

if (Test-Path $DEPLOY_SCRIPT) {
    Write-Host "  ✓ Deploy script found: $DEPLOY_SCRIPT" -ForegroundColor Green
} else {
    Write-Host "  ✗ Deploy script not found: $DEPLOY_SCRIPT" -ForegroundColor Red
    $filesOk = $false
}

if (-not $filesOk) {
    Write-Host ""
    Write-Host "Error: Required files are missing!" -ForegroundColor Red
    Write-Host "Make sure you're running this from the project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Step 1: Fix SSH Key Permissions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Fix SSH key permissions
    icacls $SSH_KEY /inheritance:r | Out-Null
    icacls $SSH_KEY /grant:r "$env:USERNAME`:R" | Out-Null
    Write-Host "✓ SSH key permissions fixed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Warning: Could not fix key permissions automatically" -ForegroundColor Yellow
    Write-Host "  Run manually if SSH fails:" -ForegroundColor Gray
    Write-Host "  icacls $SSH_KEY /inheritance:r" -ForegroundColor Gray
    Write-Host "  icacls $SSH_KEY /grant:r `"%USERNAME%:R`"" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Step 2: Test EC2 Connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing connection to EC2..." -ForegroundColor Yellow

$testConnection = Test-Connection -ComputerName $EC2_IP -Count 2 -Quiet

if ($testConnection) {
    Write-Host "✓ EC2 instance is reachable" -ForegroundColor Green
} else {
    Write-Host "✗ Cannot reach EC2 instance at $EC2_IP" -ForegroundColor Red
    Write-Host "  Please check:" -ForegroundColor Yellow
    Write-Host "  1. EC2 instance is running" -ForegroundColor Gray
    Write-Host "  2. Security group allows your IP" -ForegroundColor Gray
    Write-Host "  3. Internet connection is working" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Step 3: Upload Files to EC2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if scp is available
$scpAvailable = Get-Command scp -ErrorAction SilentlyContinue

if (-not $scpAvailable) {
    Write-Host "✗ SCP not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install OpenSSH Client:" -ForegroundColor Yellow
    Write-Host "  1. Settings - Apps - Optional Features" -ForegroundColor White
    Write-Host "  2. Add a feature" -ForegroundColor White
    Write-Host "  3. Install OpenSSH Client" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Use WinSCP (GUI)" -ForegroundColor Yellow
    Write-Host "  Download: https://winscp.net/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Manual upload commands:" -ForegroundColor Yellow
    Write-Host "  Host: $EC2_IP" -ForegroundColor Gray
    Write-Host "  Username: ec2-user" -ForegroundColor Gray
    Write-Host "  Private key: $SSH_KEY" -ForegroundColor Gray
    Write-Host "  Files to upload: $ENV_FILE, $DEPLOY_SCRIPT" -ForegroundColor Gray
    exit 1
}

Write-Host "Uploading environment file..." -ForegroundColor Yellow
scp -i $SSH_KEY -o StrictHostKeyChecking=no $ENV_FILE ec2-user@${EC2_IP}:~/

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Environment file uploaded" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to upload environment file" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Uploading deployment script..." -ForegroundColor Yellow
scp -i $SSH_KEY -o StrictHostKeyChecking=no $DEPLOY_SCRIPT ec2-user@${EC2_IP}:~/

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Deployment script uploaded" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to upload deployment script" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Step 4: Execute Deployment on EC2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Connecting to EC2 and running deployment..." -ForegroundColor Yellow
Write-Host ""

# Make script executable and run it
ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x deploy-api.sh && ./deploy-api.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "API is now running at:" -ForegroundColor Cyan
    Write-Host "  http://${EC2_IP}:8080" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Test it:" -ForegroundColor Cyan
    Write-Host "  curl http://${EC2_IP}:8080/health" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or visit in browser:" -ForegroundColor Cyan
    Write-Host "  http://${EC2_IP}:8080/health" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ✗ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs on EC2:" -ForegroundColor Yellow
    Write-Host "  ssh -i $SSH_KEY ec2-user@$EC2_IP" -ForegroundColor Gray
    Write-Host "  sudo journalctl -u pgworld-api -n 50" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Initialize database (see DEPLOY_NOW.md)" -ForegroundColor White
Write-Host "  2. Update Flutter apps with API URL" -ForegroundColor White
Write-Host "  3. Test end-to-end functionality" -ForegroundColor White
Write-Host ""

