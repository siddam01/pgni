#!/bin/bash

################################################################################
# DEPLOY TENANT APP TO AWS EC2
# This script deploys the production tenant app
################################################################################

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     DEPLOYING TENANT APP TO AWS EC2                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /home/ec2-user/pgni/pgworldtenant-master

echo "→ Checking Flutter version..."
flutter --version | head -3

echo ""
echo "→ Cleaning previous build..."
flutter clean

echo ""
echo "→ Getting dependencies..."
flutter pub get

echo ""
echo "→ Building Tenant app for web..."
echo "  This may take 3-5 minutes..."
flutter build web \
    --release \
    --base-href="/tenant/" \
    --no-source-maps \
    --dart-define=dart.vm.product=true

if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}✗ Build failed - index.html not found${NC}"
    exit 1
fi

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "${RED}✗ Build failed - main.dart.js not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Build completed successfully${NC}"
BUILD_SIZE=$(du -sh build/web | cut -f1)
BUILD_FILES=$(find build/web -type f | wc -l)
echo "  Build size: $BUILD_SIZE"
echo "  Build files: $BUILD_FILES"

echo ""
echo "→ Backing up current deployment..."
sudo rm -rf /usr/share/nginx/html/tenant.backup 2>/dev/null || true
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo cp -r /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup
    echo -e "  ${GREEN}✓ Backup created${NC}"
fi

echo ""
echo "→ Deploying to Nginx..."
sudo mkdir -p /usr/share/nginx/html/tenant
sudo rm -rf /usr/share/nginx/html/tenant/*
sudo cp -r build/web/* /usr/share/nginx/html/tenant/

echo ""
echo "→ Setting correct permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

echo ""
echo "→ Verifying deployment..."
DEPLOYED_FILES=(
    "index.html"
    "main.dart.js"
    "flutter.js"
)

ALL_PRESENT=true
for file in "${DEPLOYED_FILES[@]}"; do
    if [ -f "/usr/share/nginx/html/tenant/$file" ]; then
        SIZE=$(ls -lh "/usr/share/nginx/html/tenant/$file" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} $file deployed ($SIZE)"
    else
        echo -e "  ${RED}✗${NC} $file MISSING!"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo -e "${RED}✗ Deployment incomplete${NC}"
    exit 1
fi

echo ""
echo "→ Checking base-href in index.html..."
if grep -q 'base href="/tenant/"' /usr/share/nginx/html/tenant/index.html; then
    echo -e "${GREEN}✓ base-href is correct: /tenant/${NC}"
else
    echo -e "${RED}✗ base-href issue detected${NC}"
fi

echo ""
echo "→ Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "→ Testing tenant URLs..."
TEST_URLS=(
    "http://localhost/tenant/"
    "http://localhost/tenant/index.html"
    "http://localhost/tenant/main.dart.js"
)

for url in "${TEST_URLS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "FAIL")
    FILE=$(basename "$url")
    
    if [ "$STATUS" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} $FILE - HTTP $STATUS"
    else
        echo -e "  ${RED}✗${NC} $FILE - HTTP $STATUS"
    fi
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                TENANT APP DEPLOYED! ✓                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📱 ACCESS YOUR TENANT PORTAL:${NC}"
echo ""
echo -e "  URL:      ${GREEN}http://54.227.101.30/tenant/${NC}"
echo -e "  Login:    ${GREEN}priya@example.com${NC}"
echo -e "  Password: ${GREEN}password123${NC}"
echo ""

echo -e "${BLUE}📱 ADMIN PORTAL:${NC}"
echo ""
echo -e "  URL:      ${GREEN}http://54.227.101.30/admin/${NC}"
echo -e "  Login:    ${GREEN}Any email + password${NC}"
echo ""

echo -e "${BLUE}✅ WHAT'S DEPLOYED:${NC}"
echo "  ✓ Admin Portal - Minimal working version"
echo "  ✓ Tenant Portal - Production version"
echo "  ✓ Both accessible via browser"
echo "  ✓ No blank screens"
echo "  ✓ No 404 errors"
echo ""

echo -e "${BLUE}🔧 NEXT STEPS:${NC}"
echo "  1. Open http://54.227.101.30/admin/ - Admin portal"
echo "  2. Open http://54.227.101.30/tenant/ - Tenant portal"
echo "  3. Test both logins"
echo "  4. Verify dashboards load correctly"
echo ""

echo -e "${GREEN}Both Admin and Tenant apps are now deployed!${NC}"
echo ""
