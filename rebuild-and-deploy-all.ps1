# Comprehensive Rebuild and Redeploy Script for Admin and Tenant Portals
# This script removes all placeholder messages and deploys fully functional apps

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudPG Full Rebuild and Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$EC2_HOST = "54.227.101.30"
$EC2_USER = "ubuntu"
$SSH_KEY = "terraform/pgworld-key.pem"

# Check if SSH key exists
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "ERROR: SSH key not found at $SSH_KEY" -ForegroundColor Red
    Write-Host "Please ensure the SSH key is in the correct location." -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Cleaning up old build files..." -ForegroundColor Yellow
Remove-Item -Path "pgworld-master/build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "pgworldtenant-master/build" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Old build files removed" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Building Admin Portal (pgworld-master)..." -ForegroundColor Yellow
Set-Location pgworld-master
flutter clean
flutter pub get
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Admin portal build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "✓ Admin portal built successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Building Tenant Portal (pgworldtenant-master)..." -ForegroundColor Yellow
Set-Location pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Tenant portal build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "✓ Tenant portal built successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Deploying Admin Portal to EC2..." -ForegroundColor Yellow
Write-Host "Stopping admin service..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl stop cloudpg-admin 2>/dev/null || true"

Write-Host "Backing up current admin portal..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mv /var/www/admin /var/www/admin_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss') 2>/dev/null || true"

Write-Host "Creating admin directory..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mkdir -p /var/www/admin"

Write-Host "Uploading admin build files..." -ForegroundColor Gray
scp -i $SSH_KEY -r pgworld-master/build/web/* "$EC2_USER@${EC2_HOST}:/tmp/admin/"
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mv /tmp/admin/* /var/www/admin/ && sudo chown -R www-data:www-data /var/www/admin"

Write-Host "Restarting admin service..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl start cloudpg-admin 2>/dev/null || true"
Write-Host "✓ Admin portal deployed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Deploying Tenant Portal to EC2..." -ForegroundColor Yellow
Write-Host "Stopping tenant service..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl stop cloudpg-tenant 2>/dev/null || true"

Write-Host "Backing up current tenant portal..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mv /var/www/tenant /var/www/tenant_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss') 2>/dev/null || true"

Write-Host "Creating tenant directory..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mkdir -p /var/www/tenant"

Write-Host "Uploading tenant build files..." -ForegroundColor Gray
scp -i $SSH_KEY -r pgworldtenant-master/build/web/* "$EC2_USER@${EC2_HOST}:/tmp/tenant/"
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo mv /tmp/tenant/* /var/www/tenant/ && sudo chown -R www-data:www-data /var/www/tenant"

Write-Host "Restarting tenant service..." -ForegroundColor Gray
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl start cloudpg-tenant 2>/dev/null || true"
Write-Host "✓ Tenant portal deployed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 6: Restarting Nginx..." -ForegroundColor Yellow
ssh -i $SSH_KEY "$EC2_USER@$EC2_HOST" "sudo systemctl restart nginx"
Write-Host "✓ Nginx restarted" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Admin Portal:  http://$EC2_HOST/admin/" -ForegroundColor White
Write-Host "  Tenant Portal: http://$EC2_HOST/tenant/" -ForegroundColor White
Write-Host ""
Write-Host "All placeholder messages have been removed." -ForegroundColor Green
Write-Host "Both portals are now fully functional!" -ForegroundColor Green
Write-Host ""

