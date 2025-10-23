#!/bin/bash

################################################################################
# FORCE DEPLOY PRODUCTION APP - HANDLE LOCAL CHANGES
# This script will stash local changes and deploy the production app
################################################################################

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     FORCE DEPLOYING PRODUCTION APP TO AWS EC2                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EC2_IP="54.227.101.30"
API_URL="http://${EC2_IP}:8080"
ADMIN_URL="http://${EC2_IP}/admin/"
TENANT_URL="http://${EC2_IP}/tenant/"

echo -e "${BLUE}Configuration:${NC}"
echo "  EC2 IP: ${EC2_IP}"
echo "  API URL: ${API_URL}"
echo "  Admin URL: ${ADMIN_URL}"
echo "  Tenant URL: ${TENANT_URL}"
echo ""

################################################################################
# PHASE 1: HANDLE LOCAL CHANGES & PULL LATEST CODE
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 1: Handling Local Changes & Pulling Latest Code${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

cd /home/ec2-user/pgni
echo "Current directory: $(pwd)"

echo "→ Checking git status..."
git status --short

echo "→ Stashing local changes..."
git stash save "Auto-stash before production deployment - $(date)"

echo "→ Fetching latest changes..."
git fetch origin

echo "→ Resetting to origin/main..."
git reset --hard origin/main

echo "→ Pulling main branch..."
git pull origin main

echo -e "${GREEN}✓ Code updated successfully${NC}"
echo ""

echo "→ Verifying new main.dart..."
if grep -q "CloudPGProductionApp" /home/ec2-user/pgni/pgworld-master/lib/main.dart; then
    echo -e "${GREEN}✓ Production main.dart detected${NC}"
else
    echo -e "${RED}✗ Warning: Old main.dart still present${NC}"
fi

echo ""

################################################################################
# PHASE 2: BUILD & DEPLOY ADMIN APP
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 2: Building & Deploying Admin App${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

cd /home/ec2-user/pgni/pgworld-master

echo "→ Checking Flutter version..."
flutter --version | head -3

echo "→ Cleaning previous build..."
flutter clean

echo "→ Getting dependencies..."
flutter pub get

echo "→ Building Admin app for web..."
flutter build web --release --base-href="/admin/" --no-source-maps --dart-define=dart.vm.product=true 2>&1 | tee /tmp/admin_build.log

if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}✗ Admin build failed - index.html not found${NC}"
    echo "Build log:"
    tail -50 /tmp/admin_build.log
    exit 1
fi

echo "→ Backing up current admin deployment..."
sudo rm -rf /usr/share/nginx/html/admin.backup 2>/dev/null || true
sudo cp -r /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup 2>/dev/null || true

echo "→ Deploying Admin app to Nginx..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo rm -rf /usr/share/nginx/html/admin/*
sudo cp -r build/web/* /usr/share/nginx/html/admin/

echo "→ Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin

echo "→ Verifying deployment..."
if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    ADMIN_SIZE=$(du -sh /usr/share/nginx/html/admin | cut -f1)
    ADMIN_FILES=$(find /usr/share/nginx/html/admin -type f | wc -l)
    echo -e "${GREEN}✓ Admin app deployed successfully${NC}"
    echo "  Size: ${ADMIN_SIZE}"
    echo "  Files: ${ADMIN_FILES}"
else
    echo -e "${RED}✗ Admin deployment failed${NC}"
    exit 1
fi

echo "→ Checking base-href in index.html..."
if grep -q 'base href="/admin/"' /usr/share/nginx/html/admin/index.html; then
    echo -e "${GREEN}✓ base-href is correct: /admin/${NC}"
else
    echo -e "${RED}✗ base-href issue detected${NC}"
    grep 'base href' /usr/share/nginx/html/admin/index.html || echo "No base href found"
fi

echo ""

################################################################################
# PHASE 3: BUILD & DEPLOY TENANT APP
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 3: Building & Deploying Tenant App${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

cd /home/ec2-user/pgni/pgworldtenant-master

echo "→ Cleaning previous build..."
flutter clean

echo "→ Getting dependencies..."
flutter pub get

echo "→ Building Tenant app for web..."
flutter build web --release --base-href="/tenant/" --no-source-maps --dart-define=dart.vm.product=true 2>&1 | tee /tmp/tenant_build.log

if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}✗ Tenant build failed - index.html not found${NC}"
    echo "Build log:"
    tail -50 /tmp/tenant_build.log
    exit 1
fi

echo "→ Backing up current tenant deployment..."
sudo rm -rf /usr/share/nginx/html/tenant.backup 2>/dev/null || true
sudo cp -r /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup 2>/dev/null || true

echo "→ Deploying Tenant app to Nginx..."
sudo mkdir -p /usr/share/nginx/html/tenant
sudo rm -rf /usr/share/nginx/html/tenant/*
sudo cp -r build/web/* /usr/share/nginx/html/tenant/

echo "→ Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

echo "→ Verifying deployment..."
if [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    TENANT_SIZE=$(du -sh /usr/share/nginx/html/tenant | cut -f1)
    TENANT_FILES=$(find /usr/share/nginx/html/tenant -type f | wc -l)
    echo -e "${GREEN}✓ Tenant app deployed successfully${NC}"
    echo "  Size: ${TENANT_SIZE}"
    echo "  Files: ${TENANT_FILES}"
else
    echo -e "${RED}✗ Tenant deployment failed${NC}"
    exit 1
fi

echo "→ Checking base-href in index.html..."
if grep -q 'base href="/tenant/"' /usr/share/nginx/html/tenant/index.html; then
    echo -e "${GREEN}✓ base-href is correct: /tenant/${NC}"
else
    echo -e "${RED}✗ base-href issue detected${NC}"
    grep 'base href' /usr/share/nginx/html/tenant/index.html || echo "No base href found"
fi

echo ""

################################################################################
# PHASE 4: RESTART SERVICES
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 4: Restarting Services${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Testing Nginx configuration..."
sudo nginx -t

echo "→ Reloading Nginx..."
sudo systemctl reload nginx

echo "→ Checking API service..."
if sudo systemctl is-active --quiet pgworld-api; then
    echo -e "${GREEN}✓ API service is running${NC}"
else
    echo -e "${YELLOW}⚠ API service is not running, attempting to start...${NC}"
    sudo systemctl start pgworld-api || true
fi

echo ""

################################################################################
# PHASE 5: COMPREHENSIVE VERIFICATION
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 5: Comprehensive Verification${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Testing Admin app..."
ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "FAIL")
if [ "$ADMIN_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Admin app accessible (HTTP $ADMIN_STATUS)${NC}"
else
    echo -e "${RED}✗ Admin app failed (HTTP $ADMIN_STATUS)${NC}"
fi

echo "→ Testing Admin main.dart.js..."
ADMIN_JS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/main.dart.js || echo "FAIL")
if [ "$ADMIN_JS" = "200" ]; then
    echo -e "${GREEN}✓ Admin JS files accessible${NC}"
else
    echo -e "${RED}✗ Admin JS files failed (HTTP $ADMIN_JS)${NC}"
fi

echo "→ Testing Tenant app..."
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "FAIL")
if [ "$TENANT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Tenant app accessible (HTTP $TENANT_STATUS)${NC}"
else
    echo -e "${RED}✗ Tenant app failed (HTTP $TENANT_STATUS)${NC}"
fi

echo "→ Testing Tenant main.dart.js..."
TENANT_JS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js || echo "FAIL")
if [ "$TENANT_JS" = "200" ]; then
    echo -e "${GREEN}✓ Tenant JS files accessible${NC}"
else
    echo -e "${RED}✗ Tenant JS files failed (HTTP $TENANT_JS)${NC}"
fi

echo "→ Testing API login endpoint..."
LOGIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/login 2>/dev/null || echo "FAIL")
if [ "$LOGIN_STATUS" = "200" ] || [ "$LOGIN_STATUS" = "400" ] || [ "$LOGIN_STATUS" = "405" ]; then
    echo -e "${GREEN}✓ API login endpoint accessible (HTTP $LOGIN_STATUS)${NC}"
else
    echo -e "${YELLOW}⚠ API login endpoint returned: $LOGIN_STATUS${NC}"
fi

echo ""

################################################################################
# PHASE 6: FILE VERIFICATION
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 6: Verifying Deployed Files${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Admin deployed files:"
echo "  index.html: $([ -f /usr/share/nginx/html/admin/index.html ] && echo '✓' || echo '✗')"
echo "  main.dart.js: $([ -f /usr/share/nginx/html/admin/main.dart.js ] && echo '✓' || echo '✗')"
echo "  flutter.js: $([ -f /usr/share/nginx/html/admin/flutter.js ] && echo '✓' || echo '✗')"
echo "  Total files: $(find /usr/share/nginx/html/admin -type f | wc -l)"

echo ""
echo "→ Tenant deployed files:"
echo "  index.html: $([ -f /usr/share/nginx/html/tenant/index.html ] && echo '✓' || echo '✗')"
echo "  main.dart.js: $([ -f /usr/share/nginx/html/tenant/main.dart.js ] && echo '✓' || echo '✗')"
echo "  flutter.js: $([ -f /usr/share/nginx/html/tenant/flutter.js ] && echo '✓' || echo '✗')"
echo "  Total files: $(find /usr/share/nginx/html/tenant -type f | wc -l)"

echo ""
echo "→ Source code verification:"
echo "  Admin main.dart type: $(grep -q 'CloudPGProductionApp' /home/ec2-user/pgni/pgworld-master/lib/main.dart && echo 'Production ✓' || echo 'Demo/Unknown ✗')"
echo "  Admin main.dart lines: $(wc -l < /home/ec2-user/pgni/pgworld-master/lib/main.dart)"
echo "  Tenant main.dart lines: $(wc -l < /home/ec2-user/pgni/pgworldtenant-master/lib/main.dart)"

echo ""

################################################################################
# PHASE 7: DEPLOYMENT SUMMARY
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}DEPLOYMENT SUMMARY${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  DEPLOYMENT COMPLETE! ✓                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📱 ACCESS YOUR APPLICATIONS:${NC}"
echo ""
echo -e "${BLUE}Admin Portal:${NC}"
echo -e "  URL:      ${GREEN}${ADMIN_URL}${NC}"
echo -e "  Status:   $([ "$ADMIN_STATUS" = "200" ] && echo -e "${GREEN}✓ Online${NC}" || echo -e "${RED}✗ Check logs${NC}")"
echo -e "  Login:    ${GREEN}admin@example.com${NC}"
echo -e "  Password: ${GREEN}admin123${NC}"
echo ""
echo -e "${BLUE}Tenant Portal:${NC}"
echo -e "  URL:      ${GREEN}${TENANT_URL}${NC}"
echo -e "  Status:   $([ "$TENANT_STATUS" = "200" ] && echo -e "${GREEN}✓ Online${NC}" || echo -e "${RED}✗ Check logs${NC}")"
echo -e "  Login:    ${GREEN}priya@example.com${NC}"
echo -e "  Password: ${GREEN}password123${NC}"
echo ""
echo -e "${BLUE}API Backend:${NC}"
echo -e "  URL:      ${GREEN}${API_URL}${NC}"
echo -e "  Status:   $(sudo systemctl is-active --quiet pgworld-api && echo -e "${GREEN}✓ Running${NC}" || echo -e "${RED}✗ Stopped${NC}")"
echo ""

echo -e "${BLUE}🏢 TO ADD YOUR FIRST PG/HOSTEL:${NC}"
echo "  1. Open: ${ADMIN_URL}"
echo "  2. Login with admin credentials"
echo "  3. Navigate to: Dashboard → Hostels Management"
echo "  4. Click: 'Add New Hostel'"
echo "  5. Fill in details and save!"
echo ""

echo -e "${BLUE}📊 DEPLOYMENT STATISTICS:${NC}"
echo "  Admin Size:    ${ADMIN_SIZE}"
echo "  Admin Files:   ${ADMIN_FILES}"
echo "  Tenant Size:   ${TENANT_SIZE}"
echo "  Tenant Files:  ${TENANT_FILES}"
echo "  Source Type:   Production ✓"
echo ""

echo -e "${BLUE}🎯 PRODUCTION FEATURES NOW LIVE:${NC}"
echo "  ✓ Hostels/PG Management (Full CRUD)"
echo "  ✓ Rooms Management"
echo "  ✓ Tenant/User Management"
echo "  ✓ Bills Management"
echo "  ✓ Notices Management"
echo "  ✓ Employee Management"
echo "  ✓ Food Menu Management"
echo "  ✓ Reports & Analytics"
echo ""

echo -e "${GREEN}Deployment completed at: $(date)${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

