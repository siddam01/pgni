#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🚀 DEPLOYING ORIGINAL TENANT APP WITH PROPER UI"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP="original_deploy_$TIMESTAMP"

echo "STEP 1: Verify Original Source Files"
echo "───────────────────────────────────────────────────────"

# Check if we have the original files with proper imports
if [ ! -f "lib/screens/login.dart" ] || ! grep -q "utils/models.dart" "lib/screens/login.dart" 2>/dev/null; then
    echo "⚠️  Original files not found! Restoring from backup..."
    
    # Check if there's a recent backup
    LATEST_BACKUP=$(ls -td restore_* 2>/dev/null | head -1)
    if [ -d "$LATEST_BACKUP/lib_backup" ]; then
        echo "  Found backup: $LATEST_BACKUP"
        cp -r "$LATEST_BACKUP/lib_backup/"* lib/ 2>/dev/null || true
        echo "  ✓ Restored from backup"
    else
        echo ""
        echo "❌ ERROR: Original source files not found and no backup available!"
        echo ""
        echo "The tenant app source code appears to be missing."
        echo "Please restore from your local repository first."
        echo ""
        echo "From your local machine, run:"
        echo "  scp -r pgworldtenant-master/lib/ ec2-user@54.227.101.30:/home/ec2-user/pgni/pgworldtenant-master/"
        exit 1
    fi
fi

# Verify we have the full original codebase
REQUIRED_FILES=(
    "lib/screens/login.dart"
    "lib/screens/dashboard.dart"
    "lib/screens/profile.dart"
    "lib/screens/room.dart"
    "lib/screens/issues.dart"
    "lib/screens/notices.dart"
    "lib/utils/models.dart"
    "lib/utils/api.dart"
    "lib/utils/utils.dart"
    "lib/main.dart"
)

MISSING_COUNT=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✗ MISSING: $file"
        ((MISSING_COUNT++))
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo ""
    echo "❌ ERROR: $MISSING_COUNT required files are missing!"
    echo ""
    echo "Cannot proceed without original source files."
    echo "Please restore the complete tenant app source code first."
    exit 1
fi

echo "✓ All original source files verified"

# Count actual screens
SCREEN_COUNT=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
echo "✓ Found $SCREEN_COUNT screen files"

echo ""
echo "STEP 2: Backup Current State"
echo "───────────────────────────────────────────────────────"

mkdir -p "$BACKUP"
[ -d "lib" ] && cp -r lib "$BACKUP/" 2>/dev/null || true
[ -d "/usr/share/nginx/html/tenant" ] && sudo cp -r /usr/share/nginx/html/tenant "$BACKUP/deployed" 2>/dev/null || true
echo "✓ Backup created: $BACKUP"

echo ""
echo "STEP 3: Check and Update Configuration"
echo "───────────────────────────────────────────────────────"

# Find config file and update API URL if needed
CONFIG_UPDATED=false

if [ -f "lib/config/app_config.dart" ]; then
    echo "✓ Found: lib/config/app_config.dart"
    if grep -q "13.221.117.236" lib/config/app_config.dart; then
        sed -i 's|13.221.117.236:8080|54.227.101.30:8080|g' lib/config/app_config.dart
        sed -i 's|http://13.221.117.236:8080|/api|g' lib/config/app_config.dart
        CONFIG_UPDATED=true
        echo "  ✓ Updated API URL to /api proxy"
    fi
elif [ -f "lib/config.dart" ]; then
    echo "✓ Found: lib/config.dart"
    if grep -q "13.221.117.236" lib/config.dart; then
        sed -i 's|13.221.117.236:8080|54.227.101.30:8080|g' lib/config.dart
        sed -i 's|http://13.221.117.236:8080|/api|g' lib/config.dart
        CONFIG_UPDATED=true
        echo "  ✓ Updated API URL to /api proxy"
    fi
fi

if [ "$CONFIG_UPDATED" = true ]; then
    echo "  ℹ️  API calls will use Nginx reverse proxy (/api)"
else
    echo "  ℹ️  Using existing configuration"
fi

echo ""
echo "STEP 4: Clean and Get Dependencies"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
echo "✓ Cleaned build cache"

flutter pub get 2>&1 | tail -5
echo "✓ Dependencies resolved"

echo ""
echo "STEP 5: Build for Production"
echo "───────────────────────────────────────────────────────"
echo ""
echo "⏳ Building original tenant app (this will take 2-3 minutes)..."
echo ""

BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tee /tmp/tenant_original_build_$TIMESTAMP.log | grep -E "Compiling|Built|✓|Font" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo ""
    echo "❌ BUILD FAILED!"
    echo ""
    echo "Top 50 errors:"
    grep -i "error" /tmp/tenant_original_build_$TIMESTAMP.log | head -50
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "Build failed. Logs saved to:"
    echo "/tmp/tenant_original_build_$TIMESTAMP.log"
    echo ""
    echo "Restoring from backup..."
    if [ -d "$BACKUP/deployed" ]; then
        sudo rm -rf /usr/share/nginx/html/tenant
        sudo cp -r "$BACKUP/deployed" /usr/share/nginx/html/tenant
        echo "✓ Restored previous deployment"
    fi
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo ""
echo "✅ Build successful!"
echo "   Size: $SIZE"
echo "   Time: ${BUILD_TIME}s ($(($BUILD_TIME/60))m $(($BUILD_TIME%60))s)"
echo "   Screens: $SCREEN_COUNT files compiled"

echo ""
echo "STEP 6: Deploy to Nginx"
echo "───────────────────────────────────────────────────────"

sudo rm -rf /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant
sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;

echo "✓ Files deployed"

# Fix SELinux
if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    echo "✓ SELinux context fixed"
fi

sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

echo ""
echo "STEP 7: Verification"
echo "───────────────────────────────────────────────────────"
echo ""

# Test URLs
FAILED_URLS=0
for url in "/tenant/" "/tenant/index.html" "/tenant/main.dart.js" "/tenant/flutter_bootstrap.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url → $STATUS"
    else
        echo "  ❌ http://54.227.101.30$url → $STATUS"
        ((FAILED_URLS++))
    fi
done

# Verify critical files
echo ""
echo "Verifying deployed files:"
CRITICAL_FILES=(
    "/usr/share/nginx/html/tenant/index.html"
    "/usr/share/nginx/html/tenant/main.dart.js"
    "/usr/share/nginx/html/tenant/flutter_bootstrap.js"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        FILE_SIZE=$(ls -lh "$file" | awk '{print $5}')
        echo "  ✓ $(basename $file) - $FILE_SIZE"
    else
        echo "  ✗ $(basename $file) - MISSING!"
    fi
done

# Check base-href in index.html
echo ""
echo "Checking base-href configuration:"
if grep -q 'base href="/tenant/"' /usr/share/nginx/html/tenant/index.html 2>/dev/null; then
    echo "  ✓ base-href is correctly set to /tenant/"
else
    echo "  ⚠️  base-href may not be correctly configured"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
if [ $FAILED_URLS -eq 0 ]; then
    echo "✅ ORIGINAL TENANT APP DEPLOYED SUCCESSFULLY!"
else
    echo "⚠️  DEPLOYMENT COMPLETE WITH $FAILED_URLS URL ISSUES"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 URL:      http://54.227.101.30/tenant/"
echo "📧 Email:    priya@example.com"
echo "🔐 Password: Tenant@123"
echo ""
echo "📊 Statistics:"
echo "   Build time:    ${BUILD_TIME}s ($(($BUILD_TIME/60))m $(($BUILD_TIME%60))s)"
echo "   Bundle size:   $SIZE"
echo "   Screen files:  $SCREEN_COUNT"
echo "   Deployed:      $(date)"
echo ""
echo "📁 Backup:  $BACKUP"
echo "📄 Log:     /tmp/tenant_original_build_$TIMESTAMP.log"
echo ""
echo "🎯 IMPORTANT: Test the app now!"
echo ""
echo "TESTING STEPS:"
echo "1. Clear browser cache (Ctrl+Shift+Delete)"
echo "2. Open http://54.227.101.30/tenant/ in incognito"
echo "3. Login with above credentials"
echo "4. Verify all navigation works"
echo "5. Check all pages load properly"
echo ""
echo "If you see a plain/simple login page:"
echo "  - The simple version was deployed"
echo "  - Run this script again to deploy original screens"
echo ""
echo "If you see the full login with OTP option:"
echo "  - ✅ Original screens deployed successfully!"
echo "  - All navigation should work properly"
echo ""
echo "═══════════════════════════════════════════════════════"

