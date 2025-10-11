# ============================================================================
# ONE-COMMAND API DEPLOYMENT
# This PowerShell script deploys your API from Windows to AWS EC2
# No CloudShell needed - runs directly from your PC!
# ============================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  🚀 PGNi API - One-Command Deployment" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$EC2_IP = "34.227.111.143"
$DB_HOST = "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
$DB_PORT = "3306"
$DB_NAME = "pgworld"
$DB_USER = "admin"
$DB_PASS = "Omsairamdb951#"
$REPO_URL = "https://github.com/siddam01/pgni.git"

Write-Host "Target EC2: $EC2_IP" -ForegroundColor Yellow
Write-Host "Repository: $REPO_URL" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Cyan

# Check if SSH key exists
$sshKeyPath = "terraform\pgni-preprod-key.pem"
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "❌ SSH key not found at: $sshKeyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Getting SSH key from Terraform..." -ForegroundColor Yellow
    
    Push-Location terraform
    $sshKey = terraform output -raw ssh_private_key 2>$null
    Pop-Location
    
    if ($sshKey) {
        $sshKey | Out-File -FilePath $sshKeyPath -Encoding ASCII -NoNewline
        Write-Host "✅ SSH key extracted from Terraform" -ForegroundColor Green
    } else {
        Write-Host "❌ Could not get SSH key from Terraform" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please use CloudShell deployment instead:" -ForegroundColor Yellow
        Write-Host "  File: DEPLOY_API_NOW_COMPLETE.txt" -ForegroundColor White
        exit 1
    }
}

Write-Host "✅ SSH key found" -ForegroundColor Green

# Check SSH client
$sshExists = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshExists) {
    Write-Host "❌ SSH client not found" -ForegroundColor Red
    Write-Host "   Please enable OpenSSH client in Windows Features" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ SSH client available" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 2: Test Connectivity
# ============================================================================
Write-Host "Step 2: Testing EC2 connectivity..." -ForegroundColor Cyan

$testConnection = Test-Connection -ComputerName $EC2_IP -Count 1 -Quiet
if ($testConnection) {
    Write-Host "✅ EC2 is reachable" -ForegroundColor Green
} else {
    Write-Host "⚠️  EC2 ping failed (may be blocked by firewall)" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# STEP 3: Deploy API
# ============================================================================
Write-Host "Step 3: Deploying API to EC2..." -ForegroundColor Cyan
Write-Host ""

# Create deployment script
$deployScript = @"
#!/bin/bash
set -e

echo "=========================================="
echo "🚀 PGNi API Deployment"
echo "=========================================="
echo ""

# Install Prerequisites
echo "Installing prerequisites..."
sudo yum install -y git wget > /dev/null 2>&1 || true

# Install Go if needed
if [ ! -f /usr/local/go/bin/go ]; then
    echo "Installing Go..."
    cd /tmp
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
fi

export PATH=\$PATH:/usr/local/go/bin

# Clone and build
echo "Cloning repository..."
rm -rf /tmp/pgni
cd /tmp
git clone $REPO_URL

echo "Building API..."
cd pgni/pgworld-api-master
go mod download > /dev/null 2>&1
go build -o pgworld-api .

if [ ! -f pgworld-api ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful"

# Deploy
echo "Deploying..."
sudo mkdir -p /opt/pgworld/logs
sudo chown -R ec2-user:ec2-user /opt/pgworld

# Stop existing service
sudo systemctl stop pgworld-api 2>/dev/null || true
sleep 2

# Copy binary
cp pgworld-api /opt/pgworld/

# Create .env file
cat > /opt/pgworld/.env << 'ENV'
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_NAME=$DB_NAME
AWS_REGION=us-east-1
S3_BUCKET=pgni-uploads-preprod
PORT=8080
test=false
ENV

chmod 600 /opt/pgworld/.env
chmod +x /opt/pgworld/pgworld-api

# Create systemd service
sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICE'
[Unit]
Description=PGNi API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=10
StandardOutput=append:/opt/pgworld/logs/output.log
StandardError=append:/opt/pgworld/logs/error.log

[Install]
WantedBy=multi-user.target
SERVICE

# Start service
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl start pgworld-api

sleep 5

echo ""
echo "Service Status:"
sudo systemctl status pgworld-api --no-pager | head -15

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Testing API..."
curl -s http://localhost:8080/health || echo "⚠️  Health check pending..."

echo ""
echo "=========================================="
echo "🎉 API Deployed Successfully!"
echo "=========================================="
"@

# Save script temporarily
$deployScript | Out-File -FilePath "deploy_script.sh" -Encoding UTF8

# Copy script to EC2 and execute
Write-Host "Uploading deployment script..." -ForegroundColor Yellow
scp -i $sshKeyPath -o StrictHostKeyChecking=no deploy_script.sh ec2-user@${EC2_IP}:/tmp/deploy_script.sh

Write-Host "Executing deployment on EC2..." -ForegroundColor Yellow
Write-Host ""
ssh -i $sshKeyPath -o StrictHostKeyChecking=no ec2-user@$EC2_IP "chmod +x /tmp/deploy_script.sh && /tmp/deploy_script.sh"

# Cleanup
Remove-Item deploy_script.sh -Force

Write-Host ""

# ============================================================================
# STEP 4: Validate Deployment
# ============================================================================
Write-Host "Step 4: Validating deployment..." -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing API from external..." -ForegroundColor Yellow
$maxAttempts = 5
$success = $false

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "Attempt $i/$maxAttempts..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri "http://${EC2_IP}:8080/health" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host " ✅ SUCCESS!" -ForegroundColor Green
            Write-Host "Response: $($response.Content)" -ForegroundColor White
            $success = $true
            break
        }
    } catch {
        Write-Host " ⏳ Not ready yet" -ForegroundColor Yellow
        if ($i -lt $maxAttempts) {
            Start-Sleep -Seconds 5
        }
    }
}

Write-Host ""

if ($success) {
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your API is now LIVE and accessible!" -ForegroundColor Green
    Write-Host ""
    Write-Host "API URL:" -ForegroundColor Yellow
    Write-Host "  http://${EC2_IP}:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Health Check:" -ForegroundColor Yellow
    Write-Host "  http://${EC2_IP}:8080/health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test in browser:" -ForegroundColor Yellow
    Write-Host "  Opening health check..." -ForegroundColor Gray
    Start-Process "http://${EC2_IP}:8080/health"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. ✅ API is deployed and running" -ForegroundColor Green
    Write-Host "  2. 📱 Update mobile apps with API URL" -ForegroundColor White
    Write-Host "  3. 🏗️  Build and test mobile apps" -ForegroundColor White
    Write-Host "  4. 🚀 Start using your application!" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  ⚠️  API Deployed but not responding yet" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The API is deployed but may need a few more seconds to start." -ForegroundColor White
    Write-Host ""
    Write-Host "Check status:" -ForegroundColor Yellow
    Write-Host "  ssh -i $sshKeyPath ec2-user@$EC2_IP 'sudo systemctl status pgworld-api'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "View logs:" -ForegroundColor Yellow
    Write-Host "  ssh -i $sshKeyPath ec2-user@$EC2_IP 'sudo journalctl -u pgworld-api -n 50'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Try again in 30 seconds:" -ForegroundColor Yellow
    Write-Host "  curl http://${EC2_IP}:8080/health" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

