#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔧 FIX AND BUILD ORIGINAL TENANT APP"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "STEP 1: Check Current Source"
echo "───────────────────────────────────────────────────────"

SCREEN_COUNT=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
echo "✓ Screen files: $SCREEN_COUNT"

if [ -f "lib/screens/login.dart" ]; then
    LOGIN_LINES=$(wc -l < "lib/screens/login.dart")
    echo "✓ Login: $LOGIN_LINES lines"
    
    if [ $LOGIN_LINES -lt 200 ]; then
        echo "⚠️  Login appears to be placeholder, not original"
        echo "   Run RESTORE_FROM_GITHUB.sh first to get original source"
        exit 1
    fi
fi

echo ""
echo "STEP 2: Attempt Initial Build (to see errors)"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

echo "Building to identify errors..."
flutter build web --release --base-href="/tenant/" 2>&1 | tee /tmp/build_errors_$TIMESTAMP.log

if [ -f "build/web/main.dart.js" ]; then
    echo ""
    echo "✅ Build succeeded on first attempt!"
    echo "   No fixes needed"
else
    echo ""
    echo "❌ Build failed. Analyzing errors..."
    echo ""
    
    # Show top 30 errors
    echo "Top 30 compilation errors:"
    grep -i "error:" /tmp/build_errors_$TIMESTAMP.log | head -30
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "BUILD ERROR SUMMARY"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Full error log saved to: /tmp/build_errors_$TIMESTAMP.log"
    echo ""
    echo "Common issues:"
    echo "1. Missing utils/config.dart"
    echo "2. Missing utils/models.dart"
    echo "3. Missing utils/api.dart"
    echo "4. Missing utils/utils.dart"
    echo "5. Null safety errors"
    echo ""
    echo "To view full errors:"
    echo "  cat /tmp/build_errors_$TIMESTAMP.log | grep -A 2 'Error:' | head -100"
    echo ""
    
    # Try to identify specific missing files
    echo "Checking for missing imports..."
    MISSING_FILES=""
    
    if grep -q "utils/config.dart" /tmp/build_errors_$TIMESTAMP.log; then
        echo "  ❌ utils/config.dart - MISSING"
        MISSING_FILES="$MISSING_FILES config.dart"
    fi
    
    if grep -q "utils/models.dart" /tmp/build_errors_$TIMESTAMP.log; then
        echo "  ❌ utils/models.dart - MISSING"
        MISSING_FILES="$MISSING_FILES models.dart"
    fi
    
    if grep -q "utils/api.dart" /tmp/build_errors_$TIMESTAMP.log; then
        echo "  ❌ utils/api.dart - MISSING"
        MISSING_FILES="$MISSING_FILES api.dart"
    fi
    
    if grep -q "utils/utils.dart" /tmp/build_errors_$TIMESTAMP.log; then
        echo "  ❌ utils/utils.dart - MISSING"
        MISSING_FILES="$MISSING_FILES utils.dart"
    fi
    
    if [ -n "$MISSING_FILES" ]; then
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "MISSING FILES DETECTED"
        echo "════════════════════════════════════════════════════════"
        echo ""
        echo "The original tenant app requires these utility files:"
        echo "$MISSING_FILES"
        echo ""
        echo "These files exist in your LOCAL repository but may not be"
        echo "in the GitHub repository yet."
        echo ""
        echo "SOLUTION:"
        echo "1. From your local machine, push the complete tenant source:"
        echo "   cd C:\\MyFolder\\Mytest\\pgworld-master"
        echo "   git add pgworldtenant-master/"
        echo "   git commit -m \"Add complete tenant source with utils\""
        echo "   git push origin main"
        echo ""
        echo "2. Then run this script again on EC2"
        echo ""
        echo "OR upload directly via SCP:"
        echo "   scp -r pgworldtenant-master/lib/ ec2-user@54.227.101.30:/home/ec2-user/pgni/pgworldtenant-master/"
        echo ""
    fi
    
    echo "════════════════════════════════════════════════════════"
    exit 1
fi

echo ""
echo "STEP 3: Deploy to Nginx"
echo "───────────────────────────────────────────────────────"

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo "Bundle size: $SIZE"

sudo rm -rf /usr/share/nginx/html/tenant
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
fi

sudo systemctl reload nginx
echo "✓ Deployed"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ SUCCESS!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 URL:      http://54.227.101.30/tenant/"
echo "📧 Email:    priya@example.com"
echo "🔐 Password: Tenant@123"
echo ""
echo "Clear browser cache and test!"
echo "═══════════════════════════════════════════════════════"

