#!/bin/bash

# ============================================================================
# HOSTELS MODULE - COMPLETE DEPLOYMENT & TESTING SCRIPT
# ============================================================================

set -e  # Exit on error

echo "============================================"
echo "🚀 HOSTELS MODULE DEPLOYMENT & TESTING"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# STEP 1: PULL LATEST CODE
# ============================================================================
echo -e "${BLUE}[1/7] Pulling latest code from Git...${NC}"
cd /home/ec2-user/pgworld-master || { echo -e "${RED}❌ Project directory not found${NC}"; exit 1; }

git stash > /dev/null 2>&1 || true
git pull origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Code pulled successfully${NC}"
else
    echo -e "${RED}❌ Failed to pull code${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 2: CHECK FLUTTER VERSION
# ============================================================================
echo -e "${BLUE}[2/7] Checking Flutter version...${NC}"
cd pgworld-master
flutter --version | head -3

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter is available${NC}"
else
    echo -e "${RED}❌ Flutter not found${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 3: CLEAN & GET DEPENDENCIES
# ============================================================================
echo -e "${BLUE}[3/7] Installing dependencies...${NC}"
flutter clean
flutter pub get

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 4: BUILD FOR WEB
# ============================================================================
echo -e "${BLUE}[4/7] Building Admin app for web...${NC}"
flutter build web --release --base-href="/admin/" --no-source-maps

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful${NC}"
    
    # Check if build artifacts exist
    if [ -f "build/web/index.html" ]; then
        echo -e "${GREEN}✅ index.html found${NC}"
    else
        echo -e "${RED}❌ index.html not found${NC}"
        exit 1
    fi
    
    if [ -f "build/web/main.dart.js" ]; then
        echo -e "${GREEN}✅ main.dart.js found${NC}"
    else
        echo -e "${YELLOW}⚠️  main.dart.js not found (might be using newer Flutter)${NC}"
    fi
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 5: DEPLOY TO NGINX
# ============================================================================
echo -e "${BLUE}[5/7] Deploying to Nginx...${NC}"

# Backup existing deployment
if [ -d "/usr/share/nginx/html/admin" ]; then
    echo "Creating backup..."
    sudo cp -r /usr/share/nginx/html/admin /usr/share/nginx/html/admin_backup_$(date +%Y%m%d_%H%M%S) || true
fi

# Deploy new build
echo "Copying build files..."
sudo rm -rf /usr/share/nginx/html/admin/*
sudo cp -r build/web/* /usr/share/nginx/html/admin/

# Set permissions
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin

# Fix SELinux context (if SELinux is enabled)
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo "Fixing SELinux context..."
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin/ || true
fi

echo -e "${GREEN}✅ Deployed to Nginx${NC}"
echo ""

# ============================================================================
# STEP 6: RELOAD NGINX
# ============================================================================
echo -e "${BLUE}[6/7] Reloading Nginx...${NC}"
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Nginx reloaded${NC}"
else
    echo -e "${RED}❌ Failed to reload Nginx${NC}"
    exit 1
fi
echo ""

# ============================================================================
# STEP 7: VERIFICATION & TESTING
# ============================================================================
echo -e "${BLUE}[7/7] Running verification tests...${NC}"
echo ""

# Test 1: Check if Nginx is running
echo -n "Test 1: Nginx Status... "
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 2: Check if admin directory exists
echo -n "Test 2: Admin Directory... "
if [ -d "/usr/share/nginx/html/admin" ]; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 3: Check if index.html exists
echo -n "Test 3: index.html... "
if [ -f "/usr/share/nginx/html/admin/index.html" ]; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 4: Check HTTP access to /admin/
echo -n "Test 4: HTTP Access (/admin/)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ PASS (200)${NC}"
else
    echo -e "${RED}❌ FAIL ($HTTP_CODE)${NC}"
fi

# Test 5: Check if base-href is correct
echo -n "Test 5: base-href tag... "
if grep -q 'base href="/admin/"' /usr/share/nginx/html/admin/index.html; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING (base-href might be missing)${NC}"
fi

# Test 6: Check file count
echo -n "Test 6: File Count... "
FILE_COUNT=$(find /usr/share/nginx/html/admin -type f | wc -l)
if [ "$FILE_COUNT" -gt 10 ]; then
    echo -e "${GREEN}✅ PASS ($FILE_COUNT files)${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING (Only $FILE_COUNT files)${NC}"
fi

echo ""
echo "============================================"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo "============================================"
echo ""
echo "📍 Access URLs:"
echo "   Admin Portal: http://54.227.101.30/admin/"
echo "   API Health:   http://54.227.101.30:8080/health"
echo ""
echo "🧪 Next Steps:"
echo "   1. Open browser: http://54.227.101.30/admin/"
echo "   2. Login with admin credentials"
echo "   3. Click 'Hostels' card (orange icon)"
echo "   4. Test add/edit/delete operations"
echo ""
echo "📋 Files Deployed:"
ls -lh /usr/share/nginx/html/admin/ | head -10
echo ""
echo "✅ Deployment script completed successfully!"

