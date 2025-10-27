#!/bin/bash
###############################################################################
# CloudPG - Validate, Pull Latest, and Deploy
# This script pulls latest code from Git and deploys to EC2
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "CloudPG - Validate & Deploy Latest"
echo "=========================================="
echo ""

# Configuration
REPO_URL="https://github.com/siddam01/pgni.git"
BRANCH="main"
WORK_DIR="/tmp/cloudpg-validate-$(date +%s)"
ADMIN_WEB="/var/www/admin"
TENANT_WEB="/var/www/tenant"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_step() { echo -e "${BLUE}▶${NC} $1"; }

# Step 1: Check current deployment
echo ""
log_step "Step 1: Checking current deployment status..."

if [ -f "$ADMIN_WEB/index.html" ]; then
    ADMIN_DATE=$(stat -c %y "$ADMIN_WEB/index.html" 2>/dev/null || stat -f %Sm "$ADMIN_WEB/index.html" 2>/dev/null)
    log_info "Admin deployed: $ADMIN_DATE"
else
    log_warn "Admin not deployed yet"
fi

if [ -f "$TENANT_WEB/index.html" ]; then
    TENANT_DATE=$(stat -c %y "$TENANT_WEB/index.html" 2>/dev/null || stat -f %Sm "$TENANT_WEB/index.html" 2>/dev/null)
    log_info "Tenant deployed: $TENANT_DATE"
else
    log_warn "Tenant not deployed yet"
fi

# Check for placeholders in current deployment
echo ""
log_step "Checking for placeholders in current deployment..."
if grep -rq "minimal working version" $ADMIN_WEB/*.js 2>/dev/null; then
    log_error "PLACEHOLDERS FOUND in admin files!"
    CURRENT_HAS_PLACEHOLDERS=true
else
    log_info "No placeholders in admin files"
    CURRENT_HAS_PLACEHOLDERS=false
fi

if grep -rq "coming soon" $TENANT_WEB/*.js 2>/dev/null; then
    log_error "PLACEHOLDERS FOUND in tenant files!"
    CURRENT_HAS_PLACEHOLDERS=true
else
    log_info "No placeholders in tenant files"
fi

# Step 2: Clone latest code
echo ""
log_step "Step 2: Cloning latest code from Git..."
git clone --quiet --depth 1 --branch $BRANCH $REPO_URL $WORK_DIR 2>/dev/null || {
    log_error "Failed to clone repository"
    exit 1
}
cd $WORK_DIR
LATEST_COMMIT=$(git rev-parse --short HEAD)
LATEST_MESSAGE=$(git log -1 --pretty=format:"%s")
log_info "Latest commit: $LATEST_COMMIT"
log_info "Commit message: $LATEST_MESSAGE"

# Step 3: Check if build files exist in Git
echo ""
log_step "Step 3: Checking for pre-built files..."

ADMIN_BUILD_EXISTS=false
TENANT_BUILD_EXISTS=false

if [ -f "pgworld-master/build/web/index.html" ]; then
    log_info "Admin pre-built files found in Git"
    ADMIN_BUILD_EXISTS=true
    
    # Check if they have placeholders
    if grep -rq "minimal working version" pgworld-master/build/web/*.js 2>/dev/null; then
        log_error "Admin build files have PLACEHOLDERS!"
        ADMIN_BUILD_CLEAN=false
    else
        log_info "Admin build files are CLEAN ✓"
        ADMIN_BUILD_CLEAN=true
    fi
else
    log_warn "Admin build files NOT in Git"
fi

if [ -f "pgworldtenant-master/build/web/index.html" ]; then
    log_info "Tenant pre-built files found in Git"
    TENANT_BUILD_EXISTS=true
    
    # Check if they have placeholders
    if grep -rq "coming soon" pgworldtenant-master/build/web/*.js 2>/dev/null; then
        log_error "Tenant build files have PLACEHOLDERS!"
        TENANT_BUILD_CLEAN=false
    else
        log_info "Tenant build files are CLEAN ✓"
        TENANT_BUILD_CLEAN=true
    fi
else
    log_warn "Tenant build files NOT in Git"
fi

# Step 4: Check source code for placeholders
echo ""
log_step "Step 4: Checking source code for placeholders..."

if grep -rq "minimal working version" pgworld-master/lib/ 2>/dev/null; then
    log_error "PLACEHOLDERS in admin source code!"
    SOURCE_HAS_PLACEHOLDERS=true
else
    log_info "Admin source code is clean ✓"
    SOURCE_HAS_PLACEHOLDERS=false
fi

if grep -rq "coming soon" pgworldtenant-master/lib/ 2>/dev/null; then
    log_error "PLACEHOLDERS in tenant source code!"
    SOURCE_HAS_PLACEHOLDERS=true
else
    log_info "Tenant source code is clean ✓"
fi

# Step 5: Decision - Deploy or Not?
echo ""
log_step "Step 5: Deployment decision..."

SHOULD_DEPLOY_ADMIN=false
SHOULD_DEPLOY_TENANT=false

if [ "$ADMIN_BUILD_EXISTS" = true ] && [ "$ADMIN_BUILD_CLEAN" = true ]; then
    log_info "Admin: Clean build files available → WILL DEPLOY"
    SHOULD_DEPLOY_ADMIN=true
else
    log_warn "Admin: No clean build files → SKIP DEPLOYMENT"
fi

if [ "$TENANT_BUILD_EXISTS" = true ] && [ "$TENANT_BUILD_CLEAN" = true ]; then
    log_info "Tenant: Clean build files available → WILL DEPLOY"
    SHOULD_DEPLOY_TENANT=true
else
    log_warn "Tenant: No clean build files → SKIP DEPLOYMENT"
fi

# Step 6: Backup current deployment
if [ "$SHOULD_DEPLOY_ADMIN" = true ] || [ "$SHOULD_DEPLOY_TENANT" = true ]; then
    echo ""
    log_step "Step 6: Creating backup..."
    BACKUP_DIR="/var/www/backups/auto-deploy-$(date +%Y%m%d_%H%M%S)"
    sudo mkdir -p $BACKUP_DIR
    
    if [ -d "$ADMIN_WEB" ]; then
        sudo cp -r $ADMIN_WEB $BACKUP_DIR/admin
        log_info "Admin backed up"
    fi
    
    if [ -d "$TENANT_WEB" ]; then
        sudo cp -r $TENANT_WEB $BACKUP_DIR/tenant
        log_info "Tenant backed up"
    fi
    
    log_info "Backup: $BACKUP_DIR"
fi

# Step 7: Deploy Admin
if [ "$SHOULD_DEPLOY_ADMIN" = true ]; then
    echo ""
    log_step "Step 7: Deploying Admin Portal..."
    
    sudo rm -rf $ADMIN_WEB
    sudo mkdir -p $ADMIN_WEB
    sudo cp -r pgworld-master/build/web/* $ADMIN_WEB/
    sudo chown -R nginx:nginx $ADMIN_WEB 2>/dev/null || \
        sudo chown -R www-data:www-data $ADMIN_WEB 2>/dev/null || \
        sudo chown -R ec2-user:ec2-user $ADMIN_WEB
    sudo chmod -R 755 $ADMIN_WEB
    
    log_info "Admin deployed successfully"
fi

# Step 8: Deploy Tenant
if [ "$SHOULD_DEPLOY_TENANT" = true ]; then
    echo ""
    log_step "Step 8: Deploying Tenant Portal..."
    
    sudo rm -rf $TENANT_WEB
    sudo mkdir -p $TENANT_WEB
    sudo cp -r pgworldtenant-master/build/web/* $TENANT_WEB/
    sudo chown -R nginx:nginx $TENANT_WEB 2>/dev/null || \
        sudo chown -R www-data:www-data $TENANT_WEB 2>/dev/null || \
        sudo chown -R ec2-user:ec2-user $TENANT_WEB
    sudo chmod -R 755 $TENANT_WEB
    
    log_info "Tenant deployed successfully"
fi

# Step 9: Restart web server
if [ "$SHOULD_DEPLOY_ADMIN" = true ] || [ "$SHOULD_DEPLOY_TENANT" = true ]; then
    echo ""
    log_step "Step 9: Restarting web server..."
    sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart
    log_info "Nginx restarted"
fi

# Step 10: Verification
echo ""
log_step "Step 10: Post-deployment verification..."

if [ "$SHOULD_DEPLOY_ADMIN" = true ]; then
    if grep -rq "minimal working version" $ADMIN_WEB/*.js 2>/dev/null; then
        log_error "Admin STILL has placeholders!"
    else
        log_info "Admin verified - NO PLACEHOLDERS ✓"
    fi
fi

if [ "$SHOULD_DEPLOY_TENANT" = true ]; then
    if grep -rq "coming soon" $TENANT_WEB/*.js 2>/dev/null; then
        log_error "Tenant STILL has placeholders!"
    else
        log_info "Tenant verified - NO PLACEHOLDERS ✓"
    fi
fi

# Step 11: Cleanup
echo ""
log_step "Step 11: Cleaning up..."
cd /tmp
sudo rm -rf $WORK_DIR
log_info "Temporary files removed"

# Final Report
echo ""
echo "=========================================="
echo "DEPLOYMENT REPORT"
echo "=========================================="
echo ""
echo "📊 Summary:"
echo "  - Latest commit: $LATEST_COMMIT"
echo "  - Admin deployed: $SHOULD_DEPLOY_ADMIN"
echo "  - Tenant deployed: $SHOULD_DEPLOY_TENANT"
echo ""

if [ "$SHOULD_DEPLOY_ADMIN" = true ] || [ "$SHOULD_DEPLOY_TENANT" = true ]; then
    SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
    echo "📱 Access your applications:"
    echo "   Admin:  http://$SERVER_IP/admin/"
    echo "   Tenant: http://$SERVER_IP/tenant/"
    echo ""
    echo "💡 IMPORTANT: Clear browser cache!"
    echo "   Press Ctrl+Shift+Delete → All time → Clear"
    echo ""
    echo "🔄 Backup: $BACKUP_DIR"
else
    echo "⚠️  NO DEPLOYMENT PERFORMED"
    echo ""
    echo "Reasons:"
    [ "$ADMIN_BUILD_EXISTS" = false ] && echo "  - Admin: No build files in Git"
    [ "$ADMIN_BUILD_CLEAN" = false ] && echo "  - Admin: Build files have placeholders"
    [ "$TENANT_BUILD_EXISTS" = false ] && echo "  - Tenant: No build files in Git"
    [ "$TENANT_BUILD_CLEAN" = false ] && echo "  - Tenant: Build files have placeholders"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Rebuild locally with clean source code"
    echo "  2. Add build files to Git"
    echo "  3. Run this script again"
fi

echo "=========================================="

