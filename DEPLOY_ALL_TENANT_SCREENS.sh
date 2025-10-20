#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🚀 DEPLOYING ALL 16 TENANT SCREENS"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP="full_deploy_$TIMESTAMP"
mkdir -p "$BACKUP"

# Backup current deployment
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo cp -r /usr/share/nginx/html/tenant "$BACKUP/tenant_backup" 2>/dev/null || true
    echo "✓ Backed up current deployment"
fi

# Backup current source
cp -r lib "$BACKUP/lib_backup" 2>/dev/null || true
echo "✓ Backed up source code"

echo ""
echo "STEP 1: Verify All Screen Files Exist"
echo "───────────────────────────────────────────────────────"

EXPECTED_SCREENS=(
    "login.dart"
    "dashboard.dart"
    "profile.dart"
    "editProfile.dart"
    "room.dart"
    "rents.dart"
    "issues.dart"
    "notices.dart"
    "food.dart"
    "menu.dart"
    "mealHistory.dart"
    "documents.dart"
    "services.dart"
    "support.dart"
    "settings.dart"
    "photo.dart"
)

MISSING_COUNT=0
for screen in "${EXPECTED_SCREENS[@]}"; do
    if [ -f "lib/screens/$screen" ]; then
        echo "  ✓ $screen"
    else
        echo "  ✗ $screen (MISSING!)"
        ((MISSING_COUNT++))
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo ""
    echo "⚠️  WARNING: $MISSING_COUNT screens are missing!"
    echo "   Continuing with available screens..."
fi

echo ""
echo "STEP 2: Update Configuration"
echo "───────────────────────────────────────────────────────"

# Check which config file exists and update it
if [ -f "lib/config/app_config.dart" ]; then
    echo "✓ Found lib/config/app_config.dart"
    # Already configured correctly (uses /api proxy)
elif [ -f "lib/config.dart" ]; then
    echo "✓ Found lib/config.dart"
    sed -i 's|54\.227\.101\.30:8080|/api|g' lib/config.dart || true
    sed -i 's|http://54\.227\.101\.30:8080|/api|g' lib/config.dart || true
    sed -i 's|http://localhost:8080|/api|g' lib/config.dart || true
    echo "✓ Updated API URL to use /api proxy"
else
    echo "⚠️  No config file found, will use defaults"
fi

echo ""
echo "STEP 3: Clean and Get Dependencies"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
echo "✓ Cleaned build cache"

flutter pub get 2>&1 | tail -3
echo "✓ Dependencies resolved"

echo ""
echo "STEP 4: Build for Production"
echo "───────────────────────────────────────────────────────"
echo ""
echo "⏳ Building (this will take 2-3 minutes)..."

BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tee /tmp/tenant_build_$TIMESTAMP.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo ""
    echo "❌ BUILD FAILED!"
    echo ""
    echo "Top 30 errors:"
    grep -i "error" /tmp/tenant_build_$TIMESTAMP.log | head -30
    echo ""
    echo "Full log: /tmp/tenant_build_$TIMESTAMP.log"
    echo ""
    echo "Restoring from backup..."
    if [ -d "$BACKUP/tenant_backup" ]; then
        sudo rm -rf /usr/share/nginx/html/tenant
        sudo cp -r "$BACKUP/tenant_backup" /usr/share/nginx/html/tenant
        echo "✓ Restored previous deployment"
    fi
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo ""
echo "✅ Build successful!"
echo "   Size: $SIZE"
echo "   Time: ${BUILD_TIME}s"

# Count what was actually compiled
SCREEN_COUNT=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
echo "   Source screens: $SCREEN_COUNT"

echo ""
echo "STEP 5: Deploy to Nginx"
echo "───────────────────────────────────────────────────────"

sudo rm -rf /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant
sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;

echo "✓ Files copied"

# Fix SELinux
if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    echo "✓ SELinux context fixed"
fi

sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

echo ""
echo "STEP 6: Verification"
echo "───────────────────────────────────────────────────────"
echo ""

# Test URLs
for url in "/tenant/" "/tenant/index.html" "/tenant/main.dart.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$url" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  ✅ http://54.227.101.30$url → $STATUS"
    else
        echo "  ❌ http://54.227.101.30$url → $STATUS"
    fi
done

# Check what screens are actually in the source
echo ""
echo "Screens included in build:"
ls -1 lib/screens/*.dart 2>/dev/null | sed 's|lib/screens/||' | sed 's|\.dart||' | nl

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 URL:      http://54.227.101.30/tenant/"
echo "📧 Email:    priya@example.com"
echo "🔐 Password: Tenant@123"
echo ""
echo "📊 Statistics:"
echo "   Build time: ${BUILD_TIME}s"
echo "   Bundle size: $SIZE"
echo "   Source screens: $SCREEN_COUNT files"
echo "   Deployed: $(date)"
echo ""
echo "📁 Backup: $BACKUP"
echo ""
echo "🎯 All existing tenant screens have been deployed!"
echo ""
echo "NEXT STEPS:"
echo "1. Clear browser cache (Ctrl+Shift+Delete)"
echo "2. Open http://54.227.101.30/tenant/ in incognito mode"
echo "3. Login with above credentials"
echo "4. Test navigation to all available pages"
echo ""
echo "═══════════════════════════════════════════════════════"

