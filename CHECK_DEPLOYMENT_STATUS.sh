#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           CHECKING DEPLOYMENT STATUS                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[1] Checking deployed files...${NC}"
echo "Files in /usr/share/nginx/html/admin/:"
ls -lh /usr/share/nginx/html/admin/ | head -20
echo ""
FILE_COUNT=$(find /usr/share/nginx/html/admin/ -type f | wc -l)
echo -e "${GREEN}✓ Total files deployed: $FILE_COUNT${NC}"
echo ""

echo -e "${BLUE}[2] Checking index.html...${NC}"
if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    echo -e "${GREEN}✓ index.html exists${NC}"
    echo "Size: $(ls -lh /usr/share/nginx/html/admin/index.html | awk '{print $5}')"
    echo "Modified: $(ls -l /usr/share/nginx/html/admin/index.html | awk '{print $6, $7, $8}')"
else
    echo -e "${RED}✗ index.html NOT found${NC}"
fi
echo ""

echo -e "${BLUE}[3] Checking main.dart.js...${NC}"
MAIN_JS=$(find /usr/share/nginx/html/admin/ -name "main.dart.js" -o -name "main.dart.*.js" | head -1)
if [ -n "$MAIN_JS" ]; then
    echo -e "${GREEN}✓ Found: $MAIN_JS${NC}"
    echo "Size: $(ls -lh "$MAIN_JS" | awk '{print $5}')"
    echo "Modified: $(ls -l "$MAIN_JS" | awk '{print $6, $7, $8}')"
else
    echo -e "${RED}✗ main.dart.js NOT found${NC}"
fi
echo ""

echo -e "${BLUE}[4] Checking source code (dashboard.dart)...${NC}"
if grep -q "HostelsActivity" /home/ec2-user/pgni/pgworld-master/lib/screens/dashboard.dart; then
    echo -e "${GREEN}✓ HostelsActivity found in source code${NC}"
    echo ""
    echo "Lines containing 'Hostels':"
    grep -n "Hostels" /home/ec2-user/pgni/pgworld-master/lib/screens/dashboard.dart | head -10
else
    echo -e "${RED}✗ HostelsActivity NOT found in source code${NC}"
fi
echo ""

echo -e "${BLUE}[5] Checking Nginx status...${NC}"
sudo systemctl status nginx --no-pager -l | head -10
echo ""

echo -e "${BLUE}[6] Testing HTTP endpoints...${NC}"
echo "Testing: http://54.227.101.30/admin/"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://54.227.101.30/admin/)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ HTTP $HTTP_STATUS - Admin portal accessible${NC}"
else
    echo -e "${RED}✗ HTTP $HTTP_STATUS - Issue detected${NC}"
fi
echo ""

echo -e "${BLUE}[7] Checking browser cache headers...${NC}"
curl -I http://54.227.101.30/admin/ 2>/dev/null | grep -i "cache\|etag\|modified"
echo ""

echo -e "${BLUE}[8] Checking if this is the minimal demo or full app...${NC}"
cd /home/ec2-user/pgni/pgworld-master
MAIN_CONTENT=$(head -20 lib/main.dart)
if echo "$MAIN_CONTENT" | grep -q "MinimalAdminApp"; then
    echo -e "${YELLOW}⚠ FOUND: This is the MINIMAL DEMO version${NC}"
    echo "The current main.dart is using MinimalAdminApp placeholder"
else
    echo -e "${GREEN}✓ This is the FULL PRODUCTION version${NC}"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}📋 DIAGNOSIS:${NC}"
echo ""
echo "If you're still seeing the placeholder screen, it's likely:"
echo ""
echo "1. ${YELLOW}Browser Cache${NC} - Your browser is showing cached version"
echo "   Solution: Hard refresh (Ctrl+Shift+R) or clear cache"
echo ""
echo "2. ${YELLOW}Wrong Version Deployed${NC} - Minimal demo is deployed instead of full app"
echo "   Solution: Run the full production deployment"
echo ""
echo "3. ${YELLOW}CDN/Proxy Cache${NC} - If using CloudFlare or similar"
echo "   Solution: Purge CDN cache"
echo ""
echo "═══════════════════════════════════════════════════════════════"

