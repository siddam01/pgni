# PGNI Windows Deployment Script
# Usage: .\deploy-windows.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2_IP,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyFile,
    
    [Parameter(Mandatory=$true)]
    [string]$S3Bucket,
    
    [Parameter(Mandatory=$false)]
    [string]$RDSEndpoint = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DBUser = "admin",
    
    [Parameter(Mandatory=$false)]
    [string]$DBPassword = ""
)

Write-Host "🚀 PGNI Deployment Script for Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
if (!(Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI not found. Please install it first." -ForegroundColor Red
    Write-Host "Download: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check if Flutter is installed
if (!(Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found. Please install it first." -ForegroundColor Red
    Write-Host "Download: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# Step 1: Deploy Backend
Write-Host "Step 1: Building and Deploying Backend..." -ForegroundColor Yellow
Write-Host ""

Set-Location pgworld-api-master

Write-Host "Building Go binary for Linux..." -ForegroundColor Gray
$env:GOOS="linux"
$env:GOARCH="amd64"
go build -o pgworld-api main.go

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Uploading to EC2..." -ForegroundColor Gray

# Using SCP (requires OpenSSH)
scp -i "..\$KeyFile" pgworld-api ec2-user@${EC2_IP}:~/pgworld-api/

if ($RDSEndpoint -and $DBPassword) {
    Write-Host "Creating .env file..." -ForegroundColor Gray
    
    $envContent = @"
DB_HOST=$RDSEndpoint
DB_PORT=3306
DB_USER=$DBUser
DB_PASSWORD=$DBPassword
DB_NAME=pgworld
PORT=8080
CONNECTION_POOL=10
ENV=production
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding utf8
    scp -i "..\$KeyFile" .env ec2-user@${EC2_IP}:~/pgworld-api/
}

Write-Host "Setting up service..." -ForegroundColor Gray

$setupScript = @'
cd ~/pgworld-api
chmod +x pgworld-api

sudo tee /etc/systemd/system/pgworld-api.service > /dev/null << 'EOF'
[Unit]
Description=PG World API Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/pgworld-api
ExecStart=/home/ec2-user/pgworld-api/pgworld-api
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart pgworld-api
sudo systemctl enable pgworld-api
sudo systemctl status pgworld-api --no-pager
'@

$setupScript | ssh -i "..\$KeyFile" ec2-user@$EC2_IP

Set-Location ..

Write-Host ""
Write-Host "✅ Backend deployed!" -ForegroundColor Green
Write-Host "API URL: http://${EC2_IP}:8080" -ForegroundColor Cyan

# Step 2: Deploy Frontend
Write-Host ""
Write-Host "Step 2: Building and Deploying Frontend..." -ForegroundColor Yellow
Write-Host ""

Set-Location pgworld-master

Write-Host "Updating config..." -ForegroundColor Gray
$configFile = "lib\utils\config.dart"
$configContent = Get-Content $configFile -Raw
$configContent = $configContent -replace 'static const String URL = ".*";', "static const String URL = `"${EC2_IP}:8080`";"
$configContent = $configContent -replace 'static const String BASE_URL = ".*";', "static const String BASE_URL = `"http://${EC2_IP}:8080`";"
$configContent | Set-Content $configFile

Write-Host "Cleaning..." -ForegroundColor Gray
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Gray
flutter pub get

Write-Host "Building for web..." -ForegroundColor Gray
flutter build web --release --no-source-maps

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Uploading to S3..." -ForegroundColor Gray
aws s3 sync build\web\ s3://$S3Bucket/ --delete

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frontend deployed!" -ForegroundColor Green
} else {
    Write-Host "❌ S3 upload failed" -ForegroundColor Red
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend URL: http://$S3Bucket.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
Write-Host "Backend API: http://${EC2_IP}:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing API..." -ForegroundColor Gray
$response = Invoke-WebRequest -Uri "http://${EC2_IP}:8080/" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 200) {
    Write-Host "✅ API is responding" -ForegroundColor Green
} else {
    Write-Host "⚠️  API not responding yet. Check logs." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open frontend URL in browser" -ForegroundColor White
Write-Host "2. Login and test Manager Management" -ForegroundColor White
Write-Host "3. Setup CloudFront (optional)" -ForegroundColor White
Write-Host ""

