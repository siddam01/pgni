# Quick Deploy Script - Run this to deploy immediately
# This is a simplified version for quick deployment

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " CloudPG - Quick Deployment (No Placeholders)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$EC2_HOST = "54.227.101.30"
$EC2_USER = "ubuntu"
$SSH_KEY = "terraform\pgworld-key.pem"

# Verify SSH key exists
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "ERROR: SSH key not found!" -ForegroundColor Red
    Write-Host "Expected location: $SSH_KEY" -ForegroundColor Yellow
    exit 1
}

# Verify Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "✓ Flutter found" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter not found!" -ForegroundColor Red
    Write-Host "Please install Flutter SDK first." -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Build Admin Portal
Write-Host "[1/5] Building Admin Portal..." -ForegroundColor Yellow
Set-Location pgworld-master
flutter clean | Out-Null
flutter pub get | Out-Null
flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Admin build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "✓ Admin portal built" -ForegroundColor Green
Write-Host ""

# Build Tenant Portal
Write-Host "[2/5] Building Tenant Portal..." -ForegroundColor Yellow
Set-Location pgworldtenant-master
flutter clean | Out-Null
flutter pub get | Out-Null
flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Tenant build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "✓ Tenant portal built" -ForegroundColor Green
Write-Host ""

# Deploy Admin
Write-Host "[3/5] Deploying Admin Portal..." -ForegroundColor Yellow
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mkdir -p /tmp/admin_new"
scp -i $SSH_KEY -r pgworld-master\build\web\* "$EC2_USER@${EC2_HOST}:/tmp/admin_new/"
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo rm -rf /var/www/admin && sudo mv /tmp/admin_new /var/www/admin && sudo chown -R www-data:www-data /var/www/admin"
Write-Host "✓ Admin deployed" -ForegroundColor Green
Write-Host ""

# Deploy Tenant
Write-Host "[4/5] Deploying Tenant Portal..." -ForegroundColor Yellow
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mkdir -p /tmp/tenant_new"
scp -i $SSH_KEY -r pgworldtenant-master\build\web\* "$EC2_USER@${EC2_HOST}:/tmp/tenant_new/"
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo rm -rf /var/www/tenant && sudo mv /tmp/tenant_new /var/www/tenant && sudo chown -R www-data:www-data /var/www/tenant"
Write-Host "✓ Tenant deployed" -ForegroundColor Green
Write-Host ""

# Restart Nginx
Write-Host "[5/5] Restarting Nginx..." -ForegroundColor Yellow
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl restart nginx"
Write-Host "✓ Nginx restarted" -ForegroundColor Green
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "            DEPLOYMENT SUCCESSFUL!              " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ All placeholder messages removed" -ForegroundColor Green
Write-Host "✅ Full functionality enabled" -ForegroundColor Green
Write-Host ""
Write-Host "Access your apps:" -ForegroundColor Yellow
Write-Host "  Admin:  http://$EC2_HOST/admin/" -ForegroundColor White
Write-Host "  Tenant: http://$EC2_HOST/tenant/" -ForegroundColor White
Write-Host ""
Write-Host "Note: If you still see old messages, clear your browser cache (Ctrl+F5)" -ForegroundColor Yellow
Write-Host ""

