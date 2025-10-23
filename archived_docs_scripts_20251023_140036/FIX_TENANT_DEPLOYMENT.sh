#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX TENANT DEPLOYMENT - Blank Screen Issue"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo ""
echo "STEP 1: Check current deployment"
echo "──────────────────────────────────────────────────────"
if [ -d "/usr/share/nginx/html/tenant" ]; then
    echo "✓ Tenant directory exists"
    ls -lh /usr/share/nginx/html/tenant/index.html 2>/dev/null && echo "✓ index.html found" || echo "✗ index.html missing"
    ls -lh /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null && echo "✓ main.dart.js found" || echo "✗ main.dart.js missing"
    ls -lh /usr/share/nginx/html/tenant/flutter_bootstrap.js 2>/dev/null && echo "✓ flutter_bootstrap.js found" || echo "✗ flutter_bootstrap.js missing"
else
    echo "✗ Tenant directory does not exist"
fi

echo ""
echo "STEP 2: Check index.html base tag"
echo "──────────────────────────────────────────────────────"
if [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    grep -o '<base href="[^"]*"' /usr/share/nginx/html/tenant/index.html || echo "✗ No base tag found"
fi

echo ""
echo "STEP 3: Rebuild with correct base-href"
echo "──────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

BUILD_START=$(date +%s)
flutter build web --release --base-href="/tenant/" --no-source-maps 2>&1 | grep -E "Compiling|Built|✓" || true
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Build failed"
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo "✓ Build complete: $SIZE in ${BUILD_TIME}s"

echo ""
echo "STEP 4: Verify build output"
echo "──────────────────────────────────────────────────────"
if [ -f "build/web/index.html" ]; then
    BASE_TAG=$(grep -o '<base href="[^"]*"' build/web/index.html)
    echo "Base tag in build: $BASE_TAG"
    if [[ "$BASE_TAG" == *'/tenant/'* ]]; then
        echo "✓ Correct base-href in build"
    else
        echo "✗ Wrong base-href in build"
    fi
fi

echo ""
echo "STEP 5: Deploy to Nginx"
echo "──────────────────────────────────────────────────────"

# Backup old deployment
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    echo "✓ Backed up old deployment"
fi

# Deploy new build
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant
sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;

# Fix SELinux if present
if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    echo "✓ Fixed SELinux context"
fi

echo "✓ Deployed to /usr/share/nginx/html/tenant/"

echo ""
echo "STEP 6: Verify deployment"
echo "──────────────────────────────────────────────────────"
ls -lh /usr/share/nginx/html/tenant/ | head -15

echo ""
echo "STEP 7: Check Nginx configuration"
echo "──────────────────────────────────────────────────────"
sudo nginx -t 2>&1 | head -5

echo ""
echo "STEP 8: Reload Nginx"
echo "──────────────────────────────────────────────────────"
sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

echo ""
echo "STEP 9: Test endpoints"
echo "──────────────────────────────────────────────────────"

# Test root tenant URL
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "HTTP /tenant/: $STATUS $([ "$STATUS" = "200" ] && echo "✅" || echo "⚠️")"

# Test index.html directly
STATUS2=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/index.html)
echo "HTTP /tenant/index.html: $STATUS2 $([ "$STATUS2" = "200" ] && echo "✅" || echo "⚠️")"

# Test main.dart.js
STATUS3=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js)
echo "HTTP /tenant/main.dart.js: $STATUS3 $([ "$STATUS3" = "200" ] && echo "✅" || echo "⚠️")"

# Test flutter_bootstrap.js
STATUS4=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/flutter_bootstrap.js)
echo "HTTP /tenant/flutter_bootstrap.js: $STATUS4 $([ "$STATUS4" = "200" ] && echo "✅" || echo "⚠️")"

echo ""
echo "STEP 10: Check browser console instructions"
echo "──────────────────────────────────────────────────────"

# Get first few lines of index.html
echo "First 20 lines of index.html:"
head -20 /usr/share/nginx/html/tenant/index.html

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 URL: http://13.221.117.236/tenant/"
echo "📧 Email: priya@example.com"
echo "🔐 Password: Tenant@123"
echo ""
echo "📋 Troubleshooting:"
echo "1. Open http://13.221.117.236/tenant/ in browser"
echo "2. Press F12 to open Developer Console"
echo "3. Go to Console tab"
echo "4. Look for any RED errors"
echo "5. Go to Network tab"
echo "6. Refresh page (Ctrl+F5)"
echo "7. Look for any FAILED (red) requests"
echo ""
echo "Common issues:"
echo "• Red 404 errors → files not loading correctly"
echo "• CORS errors → backend API issue"
echo "• JavaScript errors → code compilation issue"
echo ""
echo "Share the console errors if page is still blank!"
echo "════════════════════════════════════════════════════════"

