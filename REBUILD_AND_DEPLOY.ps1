#############################################################################
# CloudPG - Complete Rebuild and Deployment Script
# This script rebuilds both Admin and Tenant portals and prepares for EC2 deployment
#############################################################################

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CloudPG - Full Rebuild & Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Blue
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
    Write-Host "  ✓ Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Flutter not found!" -ForegroundColor Red
    Write-Host "  Please install Flutter SDK first: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  STEP 1: Clean & Build Admin Portal" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if admin directory exists
if (-not (Test-Path "pgworld-master")) {
    Write-Host "✗ Admin directory not found: pgworld-master" -ForegroundColor Red
    exit 1
}

Write-Host "Building Admin Portal..." -ForegroundColor Yellow
Push-Location "pgworld-master"

try {
    Write-Host "  → Running flutter clean..." -ForegroundColor Gray
    flutter clean | Out-Null
    
    Write-Host "  → Running flutter pub get..." -ForegroundColor Gray
    flutter pub get | Out-Null
    
    Write-Host "  → Building web (this may take 2-3 minutes)..." -ForegroundColor Gray
    flutter build web --release
    
    if (Test-Path "build\web\index.html") {
        Write-Host "  ✓ Admin build successful!" -ForegroundColor Green
    } else {
        throw "Build output not found"
    }
} catch {
    Write-Host "  ✗ Admin build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  STEP 2: Clean & Build Tenant Portal" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if tenant directory exists
if (-not (Test-Path "pgworldtenant-master")) {
    Write-Host "✗ Tenant directory not found: pgworldtenant-master" -ForegroundColor Red
    exit 1
}

Write-Host "Building Tenant Portal..." -ForegroundColor Yellow
Push-Location "pgworldtenant-master"

try {
    Write-Host "  → Running flutter clean..." -ForegroundColor Gray
    flutter clean | Out-Null
    
    Write-Host "  → Running flutter pub get..." -ForegroundColor Gray
    flutter pub get | Out-Null
    
    Write-Host "  → Building web (this may take 2-3 minutes)..." -ForegroundColor Gray
    flutter build web --release
    
    if (Test-Path "build\web\index.html") {
        Write-Host "  ✓ Tenant build successful!" -ForegroundColor Green
    } else {
        throw "Build output not found"
    }
} catch {
    Write-Host "  ✗ Tenant build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  STEP 3: Verify Build Files" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking for placeholder messages..." -ForegroundColor Blue

$adminHasPlaceholders = $false
$tenantHasPlaceholders = $false

# Check admin build
$adminPlaceholders = Select-String -Path "pgworld-master\build\web\*.js" -Pattern "minimal working version|being fixed" -Quiet
if ($adminPlaceholders) {
    Write-Host "  ✗ Admin build contains placeholders!" -ForegroundColor Red
    $adminHasPlaceholders = $true
} else {
    Write-Host "  ✓ Admin build is clean" -ForegroundColor Green
}

# Check tenant build
$tenantPlaceholders = Select-String -Path "pgworldtenant-master\build\web\*.js" -Pattern "coming soon|being fixed" -Quiet
if ($tenantPlaceholders) {
    Write-Host "  ✗ Tenant build contains placeholders!" -ForegroundColor Red
    $tenantHasPlaceholders = $true
} else {
    Write-Host "  ✓ Tenant build is clean" -ForegroundColor Green
}

if ($adminHasPlaceholders -or $tenantHasPlaceholders) {
    Write-Host ""
    Write-Host "✗ ERROR: Build files contain placeholders!" -ForegroundColor Red
    Write-Host "Please check source code and rebuild." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  STEP 4: Create Deployment Package" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$deployDir = "deployment-$timestamp"

Write-Host "Creating deployment package: $deployDir" -ForegroundColor Yellow

# Create deployment directory
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null

# Copy admin build
Write-Host "  → Copying admin build..." -ForegroundColor Gray
Copy-Item -Path "pgworld-master\build\web" -Destination "$deployDir\admin" -Recurse -Force

# Copy tenant build
Write-Host "  → Copying tenant build..." -ForegroundColor Gray
Copy-Item -Path "pgworldtenant-master\build\web" -Destination "$deployDir\tenant" -Recurse -Force

# Create deployment script for EC2
$ec2Script = @'
#!/bin/bash
############################################
# CloudPG - EC2 Deployment Script
############################################

echo ""
echo "=========================================="
echo "  CloudPG Deployment to EC2"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ADMIN_TARGET="/var/www/html/admin"
TENANT_TARGET="/var/www/html/tenant"
BACKUP_DIR="/var/www/backups/deploy-$(date +%Y%m%d_%H%M%S)"

# Step 1: Create backup
echo "Step 1: Creating backup..."
sudo mkdir -p "$BACKUP_DIR"
if [ -d "$ADMIN_TARGET" ]; then
    sudo cp -r "$ADMIN_TARGET" "$BACKUP_DIR/admin"
    echo -e "${GREEN}✓ Admin backed up${NC}"
fi
if [ -d "$TENANT_TARGET" ]; then
    sudo cp -r "$TENANT_TARGET" "$BACKUP_DIR/tenant"
    echo -e "${GREEN}✓ Tenant backed up${NC}"
fi
echo "Backup location: $BACKUP_DIR"
echo ""

# Step 2: Deploy Admin
echo "Step 2: Deploying Admin Portal..."
sudo rm -rf "$ADMIN_TARGET"
sudo mkdir -p "$ADMIN_TARGET"
sudo cp -r admin/* "$ADMIN_TARGET/"

# Set permissions
sudo chown -R nginx:nginx "$ADMIN_TARGET" 2>/dev/null || \
sudo chown -R www-data:www-data "$ADMIN_TARGET" 2>/dev/null || \
sudo chown -R apache:apache "$ADMIN_TARGET" 2>/dev/null || \
sudo chown -R ec2-user:ec2-user "$ADMIN_TARGET"

sudo chmod -R 755 "$ADMIN_TARGET"
echo -e "${GREEN}✓ Admin deployed${NC}"
echo ""

# Step 3: Deploy Tenant
echo "Step 3: Deploying Tenant Portal..."
sudo rm -rf "$TENANT_TARGET"
sudo mkdir -p "$TENANT_TARGET"
sudo cp -r tenant/* "$TENANT_TARGET/"

# Set permissions
sudo chown -R nginx:nginx "$TENANT_TARGET" 2>/dev/null || \
sudo chown -R www-data:www-data "$TENANT_TARGET" 2>/dev/null || \
sudo chown -R apache:apache "$TENANT_TARGET" 2>/dev/null || \
sudo chown -R ec2-user:ec2-user "$TENANT_TARGET"

sudo chmod -R 755 "$TENANT_TARGET"
echo -e "${GREEN}✓ Tenant deployed${NC}"
echo ""

# Step 4: Restart web server
echo "Step 4: Restarting web server..."
sudo systemctl restart nginx 2>/dev/null || \
sudo systemctl restart apache2 2>/dev/null || \
sudo service nginx restart 2>/dev/null || \
sudo service apache2 restart 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Web server restarted${NC}"
else
    echo -e "${YELLOW}⚠ Could not restart web server automatically${NC}"
    echo "Please restart manually: sudo systemctl restart nginx"
fi
echo ""

# Step 5: Verification
echo "Step 5: Verifying deployment..."

ERRORS=0

# Check if files exist
if [ -f "$ADMIN_TARGET/index.html" ]; then
    echo -e "${GREEN}✓ Admin index.html exists${NC}"
else
    echo -e "${RED}✗ Admin index.html NOT found!${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "$TENANT_TARGET/index.html" ]; then
    echo -e "${GREEN}✓ Tenant index.html exists${NC}"
else
    echo -e "${RED}✗ Tenant index.html NOT found!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for placeholders
if grep -rq "minimal working version" "$ADMIN_TARGET"/*.js 2>/dev/null; then
    echo -e "${RED}✗ Admin still has placeholders!${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Admin has no placeholders${NC}"
fi

if grep -rq "coming soon" "$TENANT_TARGET"/*.js 2>/dev/null; then
    echo -e "${RED}✗ Tenant still has placeholders!${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Tenant has no placeholders${NC}"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ DEPLOYMENT SUCCESSFUL!${NC}"
else
    echo -e "${RED}✗ DEPLOYMENT COMPLETED WITH $ERRORS ERROR(S)${NC}"
fi
echo "=========================================="
echo ""

# Get server IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

echo "Access your applications:"
echo "  Admin:  http://$SERVER_IP/admin/"
echo "  Tenant: http://$SERVER_IP/tenant/"
echo ""
echo "CRITICAL: Clear browser cache!"
echo "  1. Press Ctrl+Shift+Delete"
echo "  2. Select 'All time'"
echo "  3. Check 'Cached images and files'"
echo "  4. Click 'Clear data'"
echo "  5. Close browser completely"
echo "  6. Reopen and test"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""

exit $ERRORS
'@

$ec2Script | Out-File -FilePath "$deployDir\deploy.sh" -Encoding UTF8 -NoNewline

# Create README
$readme = @"
# CloudPG Deployment Package
Generated: $timestamp

## Contents
- admin/     - Admin Portal (Flutter Web Build)
- tenant/    - Tenant Portal (Flutter Web Build)
- deploy.sh  - EC2 Deployment Script

## Deployment Steps

### Option 1: WinSCP (Recommended)
1. Open WinSCP and connect to EC2 (54.227.101.30)
2. Upload this entire folder to /tmp/
3. Open Terminal (Ctrl+T)
4. Run:
   cd /tmp/$deployDir
   chmod +x deploy.sh
   sudo ./deploy.sh

### Option 2: SCP from Windows
scp -i your-key.pem -r $deployDir ec2-user@54.227.101.30:/tmp/
ssh -i your-key.pem ec2-user@54.227.101.30
cd /tmp/$deployDir
chmod +x deploy.sh
sudo ./deploy.sh

## Post-Deployment
1. Clear browser cache completely
2. Visit: http://54.227.101.30/admin/
3. Visit: http://54.227.101.30/tenant/
4. Test all navigation links
5. Verify no placeholder messages

## Rollback
If deployment fails, restore from backup:
sudo cp -r /var/www/backups/deploy-YYYYMMDD_HHMMSS/admin /var/www/html/
sudo cp -r /var/www/backups/deploy-YYYYMMDD_HHMMSS/tenant /var/www/html/
sudo systemctl restart nginx

## Support
Contact: support@cloudpg.com
"@

$readme | Out-File -FilePath "$deployDir\README.txt" -Encoding UTF8

Write-Host "  ✓ Deployment package created!" -ForegroundColor Green

# Get sizes
$adminSize = (Get-ChildItem -Path "$deployDir\admin" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$tenantSize = (Get-ChildItem -Path "$deployDir\tenant" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Host "Package Details:" -ForegroundColor Cyan
Write-Host "  Location: $(Get-Location)\$deployDir" -ForegroundColor White
Write-Host "  Admin size: $([math]::Round($adminSize, 2)) MB" -ForegroundColor White
Write-Host "  Tenant size: $([math]::Round($tenantSize, 2)) MB" -ForegroundColor White

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ✓ BUILD COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. COMMIT TO GIT (Optional but recommended):" -ForegroundColor Cyan
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'fix: Full rebuild with all navigation working'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "2. DEPLOY TO EC2 (Choose one method):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   METHOD A: WinSCP (Easiest)" -ForegroundColor Yellow
Write-Host "   • Open WinSCP → Connect to 54.227.101.30" -ForegroundColor White
Write-Host "   • Upload '$deployDir' folder to /tmp/" -ForegroundColor White
Write-Host "   • Press Ctrl+T (Terminal)" -ForegroundColor White
Write-Host "   • Run: cd /tmp/$deployDir && chmod +x deploy.sh && sudo ./deploy.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "   METHOD B: Command Line" -ForegroundColor Yellow
Write-Host "   • scp -i your-key.pem -r $deployDir ec2-user@54.227.101.30:/tmp/" -ForegroundColor Gray
Write-Host "   • ssh -i your-key.pem ec2-user@54.227.101.30" -ForegroundColor Gray
Write-Host "   • cd /tmp/$deployDir && chmod +x deploy.sh && sudo ./deploy.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "3. CLEAR BROWSER CACHE:" -ForegroundColor Cyan
Write-Host "   • Ctrl+Shift+Delete → All time → Clear" -ForegroundColor White
Write-Host "   • Close browser completely" -ForegroundColor White
Write-Host "   • Reopen and visit http://54.227.101.30/admin/" -ForegroundColor White
Write-Host ""
Write-Host "4. TEST ALL FEATURES:" -ForegroundColor Cyan
Write-Host "   • Click each dashboard card (Hostels, Rooms, Tenants, etc.)" -ForegroundColor White
Write-Host "   • Verify navigation works" -ForegroundColor White
Write-Host "   • Confirm no placeholder messages" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Open deployment folder in Explorer
Invoke-Item $deployDir

Write-Host "Deployment folder opened in Explorer!" -ForegroundColor Green
Write-Host ""

