#!/bin/bash

################################################################################
# FIX BLANK ADMIN SCREEN - DIAGNOSTIC & REPAIR
# This script diagnoses and fixes the 404 errors for main.dart.js
################################################################################

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     FIXING BLANK ADMIN SCREEN (404 ERRORS)                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# PHASE 1: DIAGNOSE THE ISSUE
################################################################################
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 1: Diagnosing the Issue${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Checking deployed admin files..."
if [ -d "/usr/share/nginx/html/admin" ]; then
    echo -e "${GREEN}✓ Admin directory exists${NC}"
    FILE_COUNT=$(find /usr/share/nginx/html/admin -type f | wc -l)
    echo "  Total files: $FILE_COUNT"
else
    echo -e "${RED}✗ Admin directory missing!${NC}"
fi

echo ""
echo "→ Checking critical files..."
FILES_TO_CHECK=(
    "/usr/share/nginx/html/admin/index.html"
    "/usr/share/nginx/html/admin/main.dart.js"
    "/usr/share/nginx/html/admin/flutter.js"
    "/usr/share/nginx/html/admin/flutter_bootstrap.js"
)

MISSING_FILES=0
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(ls -lh "$file" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} $(basename $file) - $SIZE"
    else
        echo -e "  ${RED}✗${NC} $(basename $file) - MISSING!"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

echo ""
echo "→ Checking base-href in index.html..."
if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    BASE_HREF=$(grep -o 'base href="[^"]*"' /usr/share/nginx/html/admin/index.html || echo "NOT FOUND")
    echo "  Found: $BASE_HREF"
    
    if [[ "$BASE_HREF" == *'base href="/admin/"'* ]]; then
        echo -e "  ${GREEN}✓ base-href is correct${NC}"
    else
        echo -e "  ${RED}✗ base-href is incorrect or missing${NC}"
    fi
else
    echo -e "  ${RED}✗ index.html not found${NC}"
fi

echo ""
echo "→ Checking Nginx configuration..."
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo -e "  ${GREEN}✓ Nginx config is valid${NC}"
else
    echo -e "  ${RED}✗ Nginx config has errors${NC}"
    sudo nginx -t
fi

echo ""
echo "→ Checking file permissions..."
ADMIN_PERMS=$(ls -ld /usr/share/nginx/html/admin | awk '{print $1, $3, $4}')
echo "  Admin directory: $ADMIN_PERMS"

if [[ "$ADMIN_PERMS" == *"nginx"* ]]; then
    echo -e "  ${GREEN}✓ Ownership is correct (nginx)${NC}"
else
    echo -e "  ${YELLOW}⚠ Ownership might be incorrect${NC}"
fi

echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  Missing files: $MISSING_FILES"
if [ $MISSING_FILES -gt 0 ]; then
    echo -e "  ${RED}Action needed: Rebuild and redeploy Admin app${NC}"
else
    echo -e "  ${YELLOW}Action needed: Check Nginx config and base-href${NC}"
fi

################################################################################
# PHASE 2: FIX THE ISSUE
################################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 2: Rebuilding & Redeploying Admin App${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

cd /home/ec2-user/pgni/pgworld-master

echo "→ Verifying source code..."
if [ -f "lib/main.dart" ]; then
    MAIN_LINES=$(wc -l < lib/main.dart)
    echo "  main.dart exists: $MAIN_LINES lines"
    
    if grep -q "CloudPGProductionApp" lib/main.dart; then
        echo -e "  ${GREEN}✓ Production main.dart detected${NC}"
    else
        echo -e "  ${YELLOW}⚠ Might be old main.dart${NC}"
    fi
else
    echo -e "  ${RED}✗ main.dart not found${NC}"
    exit 1
fi

echo ""
echo "→ Cleaning previous build..."
flutter clean

echo ""
echo "→ Getting dependencies..."
flutter pub get

echo ""
echo "→ Building Admin app for web..."
echo "  This may take 5-7 minutes..."
flutter build web \
    --release \
    --base-href="/admin/" \
    --no-source-maps \
    --dart-define=dart.vm.product=true \
    2>&1 | tee /tmp/admin_build.log

echo ""
echo "→ Verifying build output..."
if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}✗ Build failed - index.html not found${NC}"
    echo "Last 30 lines of build log:"
    tail -30 /tmp/admin_build.log
    exit 1
fi

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "${RED}✗ Build failed - main.dart.js not found${NC}"
    echo "Build output files:"
    ls -lh build/web/ | head -20
    exit 1
fi

echo -e "${GREEN}✓ Build completed successfully${NC}"
BUILD_SIZE=$(du -sh build/web | cut -f1)
BUILD_FILES=$(find build/web -type f | wc -l)
echo "  Build size: $BUILD_SIZE"
echo "  Build files: $BUILD_FILES"

################################################################################
# PHASE 3: DEPLOY TO NGINX
################################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 3: Deploying to Nginx${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Backing up current deployment..."
sudo rm -rf /usr/share/nginx/html/admin.backup 2>/dev/null || true
if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo cp -r /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup
    echo -e "  ${GREEN}✓ Backup created${NC}"
fi

echo ""
echo "→ Removing old deployment..."
sudo rm -rf /usr/share/nginx/html/admin/*

echo ""
echo "→ Copying new build to Nginx..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/

echo ""
echo "→ Setting correct permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin

echo ""
echo "→ Verifying deployment..."
DEPLOYED_FILES=(
    "index.html"
    "main.dart.js"
    "flutter.js"
    "flutter_bootstrap.js"
)

ALL_PRESENT=true
for file in "${DEPLOYED_FILES[@]}"; do
    if [ -f "/usr/share/nginx/html/admin/$file" ]; then
        SIZE=$(ls -lh "/usr/share/nginx/html/admin/$file" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} $file deployed ($SIZE)"
    else
        echo -e "  ${RED}✗${NC} $file MISSING!"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo -e "${RED}✗ Deployment incomplete - restoring backup${NC}"
    sudo rm -rf /usr/share/nginx/html/admin
    sudo cp -r /usr/share/nginx/html/admin.backup /usr/share/nginx/html/admin
    exit 1
fi

################################################################################
# PHASE 4: RESTART NGINX & VERIFY
################################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 4: Restarting Nginx & Verification${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Testing Nginx configuration..."
sudo nginx -t

echo ""
echo "→ Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "→ Waiting for Nginx to settle..."
sleep 2

echo ""
echo "→ Testing admin URLs..."
TEST_URLS=(
    "http://localhost/admin/"
    "http://localhost/admin/index.html"
    "http://localhost/admin/main.dart.js"
    "http://localhost/admin/flutter.js"
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

################################################################################
# PHASE 5: FINAL VERIFICATION
################################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 5: Final Verification${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

echo "→ Checking base-href in deployed index.html..."
BASE_HREF=$(grep -o 'base href="[^"]*"' /usr/share/nginx/html/admin/index.html)
echo "  $BASE_HREF"

echo ""
echo "→ Checking deployed file sizes..."
echo "  index.html:    $(ls -lh /usr/share/nginx/html/admin/index.html | awk '{print $5}')"
echo "  main.dart.js:  $(ls -lh /usr/share/nginx/html/admin/main.dart.js | awk '{print $5}')"
echo "  Total files:   $(find /usr/share/nginx/html/admin -type f | wc -l)"
echo "  Total size:    $(du -sh /usr/share/nginx/html/admin | cut -f1)"

################################################################################
# SUCCESS
################################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  FIX COMPLETED SUCCESSFULLY! ✓                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📱 ADMIN PORTAL ACCESS:${NC}"
echo ""
echo -e "  URL:      ${GREEN}http://54.227.101.30/admin/${NC}"
echo -e "  Login:    ${GREEN}admin@example.com${NC}"
echo -e "  Password: ${GREEN}admin123${NC}"
echo ""

echo -e "${BLUE}✅ NEXT STEPS:${NC}"
echo "  1. Open your browser"
echo "  2. Press Ctrl+Shift+R (or Cmd+Shift+R on Mac) to hard refresh"
echo "  3. Navigate to: http://54.227.101.30/admin/"
echo "  4. You should now see the login screen!"
echo ""

echo -e "${YELLOW}If you still see a blank screen:${NC}"
echo "  1. Clear your browser cache completely"
echo "  2. Try in an incognito/private window"
echo "  3. Check browser console (F12) for any errors"
echo ""

echo -e "${GREEN}Admin app successfully fixed and deployed!${NC}"
echo ""

