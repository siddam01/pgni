# PGNi One-Click Deployment Script
# This script will guide you through deploying via AWS CloudShell

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PGNi ONE-CLICK DEPLOYMENT ASSISTANT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Show SSH Key
Write-Host "STEP 1: Get SSH Key" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening SSH key file..." -ForegroundColor Gray

if (Test-Path "ssh-key-for-cloudshell.txt") {
    Write-Host "SSH key file found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ACTION REQUIRED:" -ForegroundColor Yellow
    Write-Host "  1. A notepad window will open with your SSH key" -ForegroundColor White
    Write-Host "  2. Select ALL (Ctrl+A) and COPY (Ctrl+C)" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to open SSH key file"
    notepad ssh-key-for-cloudshell.txt
} else {
    Write-Host "Extracting SSH key..." -ForegroundColor Gray
    Set-Location terraform
    terraform output -raw ssh_private_key > ../ssh-key-for-cloudshell.txt
    Set-Location ..
    Write-Host "SSH key extracted!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to open SSH key file"
    notepad ssh-key-for-cloudshell.txt
}

Write-Host ""
Write-Host "Have you copied the SSH key?" -ForegroundColor Yellow
$copied = Read-Host "Type 'yes' when ready"

if ($copied -ne "yes") {
    Write-Host "Please copy the SSH key first!" -ForegroundColor Red
    exit 1
}

# Step 2: Create CloudShell commands file
Write-Host ""
Write-Host "STEP 2: Creating CloudShell deployment commands..." -ForegroundColor Yellow

$cloudShellCommands = @"
# ========================================
# PGNi CloudShell Deployment Commands
# Copy and paste these into AWS CloudShell
# ========================================

# 1. CREATE SSH KEY
echo "Creating SSH key..."
cat > ec2-key.pem << 'SSHKEY'
[PASTE YOUR SSH KEY HERE - REPLACE THIS ENTIRE LINE]
SSHKEY
chmod 600 ec2-key.pem
echo "SSH key created!"

# 2. CREATE ENVIRONMENT FILE
echo "Creating environment file..."
cat > preprod.env << 'ENVFILE'
DB_HOST=database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=Omsairamdb951#
DB_NAME=pgworld
AWS_REGION=us-east-1
S3_BUCKET=pgni-preprod-698302425856-uploads
PORT=8080
test=false
ENVFILE
echo "Environment file created!"

# 3. UPLOAD TO EC2
echo "Uploading files to EC2..."
EC2_IP="34.227.111.143"
scp -i ec2-key.pem -o StrictHostKeyChecking=no preprod.env ec2-user@`$EC2_IP:~/
echo "Files uploaded!"

# 4. CONNECT AND DEPLOY
echo "Connecting to EC2..."
ssh -i ec2-key.pem -o StrictHostKeyChecking=no ec2-user@`$EC2_IP << 'DEPLOYMENT'

echo "=========================================="
echo "Starting PGNi API Deployment"
echo "=========================================="

# Clone repository
if [ -d "pgni" ]; then
    echo "Updating repository..."
    cd pgni && git pull && cd ..
else
    echo "Cloning repository..."
    git clone https://github.com/siddam01/pgni.git
fi

# Build API
echo "Building API..."
cd pgni/pgworld-api-master
/usr/local/go/bin/go build -o pgworld-api .

if [ ! -f "pgworld-api" ]; then
    echo "ERROR: Build failed!"
    exit 1
fi

echo "Build successful!"

# Deploy
echo "Deploying to /opt/pgworld..."
sudo mkdir -p /opt/pgworld
sudo cp pgworld-api /opt/pgworld/
sudo cp ~/preprod.env /opt/pgworld/.env
sudo chown -R ec2-user:ec2-user /opt/pgworld

# Create service if not exists
if [ ! -f /etc/systemd/system/pgworld-api.service ]; then
    echo "Creating systemd service..."
    sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'SERVICE'
[Unit]
Description=PGWorld API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/pgworld
ExecStart=/opt/pgworld/pgworld-api
EnvironmentFile=/opt/pgworld/.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE
fi

# Start service
echo "Starting PGNi API service..."
sudo systemctl daemon-reload
sudo systemctl enable pgworld-api
sudo systemctl restart pgworld-api

# Wait for startup
echo "Waiting for service to start..."
sleep 5

# Check status
echo ""
echo "=========================================="
echo "Service Status:"
echo "=========================================="
sudo systemctl status pgworld-api --no-pager

echo ""
echo "=========================================="
echo "Recent Logs:"
echo "=========================================="
sudo journalctl -u pgworld-api -n 20 --no-pager

echo ""
echo "=========================================="
echo "Testing API:"
echo "=========================================="
curl -s http://localhost:8080/health || echo "Health check failed"
curl -s http://34.227.111.143:8080/health || echo "Public health check failed"

echo ""
echo "=========================================="
echo "Creating Database:"
echo "=========================================="
mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -pOmsairamdb951# << 'SQL'
CREATE DATABASE IF NOT EXISTS pgworld CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pgworld;
SELECT 'Database created successfully!' as Status;
SQL

echo ""
echo "=========================================="
echo "DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "API URL: http://34.227.111.143:8080"
echo "Health: http://34.227.111.143:8080/health"
echo ""
echo "Test from your browser:"
echo "  http://34.227.111.143:8080/health"
echo ""

DEPLOYMENT

echo ""
echo "=========================================="
echo "FINAL VALIDATION FROM CLOUDSHELL"
echo "=========================================="
curl -s http://34.227.111.143:8080/health
echo ""
echo "If you see a response above, YOUR API IS LIVE!"
"@

$cloudShellCommands | Out-File -FilePath "CLOUDSHELL_COMMANDS.txt" -Encoding UTF8

Write-Host "CloudShell commands created: CLOUDSHELL_COMMANDS.txt" -ForegroundColor Green

# Step 3: Open browser
Write-Host ""
Write-Host "STEP 3: Open AWS CloudShell" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening AWS CloudShell in your browser..." -ForegroundColor Gray
Write-Host ""
Start-Process "https://console.aws.amazon.com/cloudshell/"

Write-Host "Browser opened!" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter when CloudShell is ready (takes ~10 seconds to load)"

# Step 4: Show commands
Write-Host ""
Write-Host "STEP 4: Run Deployment Commands" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening commands file..." -ForegroundColor Gray
notepad CLOUDSHELL_COMMANDS.txt

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  INSTRUCTIONS:" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. In the CLOUDSHELL_COMMANDS.txt file:" -ForegroundColor White
Write-Host "   - Find: [PASTE YOUR SSH KEY HERE]" -ForegroundColor Yellow
Write-Host "   - Replace with your actual SSH key (already in clipboard)" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Copy ALL the commands from the file" -ForegroundColor White
Write-Host ""
Write-Host "3. Paste into AWS CloudShell terminal" -ForegroundColor White
Write-Host ""
Write-Host "4. Press Enter and wait (~2-3 minutes)" -ForegroundColor White
Write-Host ""
Write-Host "5. You will see 'DEPLOYMENT COMPLETE!'" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$done = Read-Host "Have you completed the deployment? (type 'yes')"

if ($done -eq "yes") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  TESTING YOUR DEPLOYED API" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Testing API health endpoint..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "http://34.227.111.143:8080/health" -TimeoutSec 10
        Write-Host ""
        Write-Host "SUCCESS! YOUR API IS LIVE!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Green
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "  YOUR APP DETAILS" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "API URL:" -ForegroundColor Yellow
        Write-Host "  http://34.227.111.143:8080" -ForegroundColor White
        Write-Host ""
        Write-Host "Health Check:" -ForegroundColor Yellow
        Write-Host "  http://34.227.111.143:8080/health" -ForegroundColor White
        Write-Host ""
        Write-Host "Database:" -ForegroundColor Yellow
        Write-Host "  Host: database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" -ForegroundColor White
        Write-Host "  User: admin" -ForegroundColor White
        Write-Host "  Database: pgworld" -ForegroundColor White
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next: Configure mobile apps with this API URL!" -ForegroundColor Yellow
        Write-Host "See: USER_GUIDES folder for complete documentation" -ForegroundColor Yellow
        Write-Host ""
        
    } catch {
        Write-Host ""
        Write-Host "WARNING: Cannot reach API yet" -ForegroundColor Yellow
        Write-Host "This might be normal if deployment just finished" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Please wait 1-2 minutes and test manually:" -ForegroundColor Yellow
        Write-Host "  http://34.227.111.143:8080/health" -ForegroundColor Cyan
        Write-Host ""
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT ASSISTANT COMPLETE!" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the USER_GUIDES folder for complete documentation" -ForegroundColor Yellow
Write-Host ""

