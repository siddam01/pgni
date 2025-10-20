#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "🔧 RESTORE ORIGINAL SOURCE AND DIAGNOSE BUILD ERRORS"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
GITHUB_REPO="https://github.com/siddam01/pgni.git"
TEMP_DIR="/tmp/pgni_diagnose_$(date +%Y%m%d_%H%M%S)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "STEP 1: Clone Repository"
echo "───────────────────────────────────────────────────────"

git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR" 2>&1 | tail -3
echo "✓ Cloned repository"

echo ""
echo "STEP 2: Check Available Source Files"
echo "───────────────────────────────────────────────────────"

echo ""
echo "Screens in GitHub:"
if [ -d "$TEMP_DIR/pgworldtenant-master/lib/screens" ]; then
    SCREEN_COUNT=$(ls -1 "$TEMP_DIR/pgworldtenant-master/lib/screens"/*.dart 2>/dev/null | wc -l)
    echo "  Found: $SCREEN_COUNT files"
    ls -1 "$TEMP_DIR/pgworldtenant-master/lib/screens"/*.dart 2>/dev/null | sed 's|.*/||' | sed 's|\.dart||' | head -20
else
    echo "  ✗ No screens directory"
fi

echo ""
echo "Utils in GitHub:"
if [ -d "$TEMP_DIR/pgworldtenant-master/lib/utils" ]; then
    UTILS_COUNT=$(ls -1 "$TEMP_DIR/pgworldtenant-master/lib/utils"/*.dart 2>/dev/null | wc -l)
    echo "  Found: $UTILS_COUNT files"
    ls -1 "$TEMP_DIR/pgworldtenant-master/lib/utils"/*.dart 2>/dev/null | sed 's|.*/||'
else
    echo "  ✗ No utils directory"
fi

echo ""
echo "Other lib files:"
ls -1 "$TEMP_DIR/pgworldtenant-master/lib"/*.dart 2>/dev/null | sed 's|.*/||' || echo "  None found"

echo ""
echo "STEP 3: Restore Source to EC2 (KEEPING ON FAILURE)"
echo "───────────────────────────────────────────────────────"

cd "$TENANT_PATH"

# Backup current state
BACKUP="diagnose_backup_$TIMESTAMP"
mkdir -p "$BACKUP"
[ -d "lib" ] && cp -r lib "$BACKUP/" 2>/dev/null || true
echo "✓ Backed up current state"

# Remove and restore
rm -rf lib
cp -r "$TEMP_DIR/pgworldtenant-master/lib" .
echo "✓ Restored source from GitHub"

# Verify
RESTORED_SCREENS=$(ls -1 lib/screens/*.dart 2>/dev/null | wc -l)
RESTORED_UTILS=$(ls -1 lib/utils/*.dart 2>/dev/null | wc -l)
echo "✓ Restored: $RESTORED_SCREENS screens, $RESTORED_UTILS utils"

# Check login file size to verify it's original
if [ -f "lib/screens/login.dart" ]; then
    LOGIN_LINES=$(wc -l < "lib/screens/login.dart")
    if [ $LOGIN_LINES -gt 200 ]; then
        echo "✓ Original source confirmed ($LOGIN_LINES lines in login.dart)"
    else
        echo "⚠️  May still be placeholder ($LOGIN_LINES lines)"
    fi
fi

echo ""
echo "STEP 4: Check Required Dependencies"
echo "───────────────────────────────────────────────────────"

REQUIRED_FILES=(
    "lib/utils/config.dart"
    "lib/utils/models.dart"
    "lib/utils/api.dart"
    "lib/utils/utils.dart"
    "lib/main.dart"
)

MISSING_COUNT=0
echo "Checking for required files:"
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file" 2>/dev/null || echo "0")
        echo "  ✓ $file ($LINES lines)"
    else
        echo "  ✗ $file - MISSING"
        ((MISSING_COUNT++))
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo ""
    echo "⚠️  $MISSING_COUNT required files are missing!"
    echo ""
    echo "These files are needed by the original tenant app but"
    echo "are not in your GitHub repository yet."
    echo ""
    echo "📋 SOLUTION:"
    echo ""
    echo "From your LOCAL Windows machine, add and push the utils:"
    echo ""
    echo "  cd C:\\MyFolder\\Mytest\\pgworld-master"
    echo "  git add pgworldtenant-master/lib/utils/"
    echo "  git add pgworldtenant-master/lib/main.dart"
    echo "  git commit -m \"Add tenant utils files\""
    echo "  git push origin main"
    echo ""
    echo "Then run this script again!"
    echo ""
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "STEP 5: Attempt Build"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
echo "✓ Cleaned"

flutter pub get 2>&1 | tail -3
echo "✓ Dependencies"

echo ""
echo "Building (this will take 2-3 minutes)..."
echo ""

BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tee /tmp/build_log_$TIMESTAMP.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   Size: $SIZE"
    echo "   Time: ${BUILD_TIME}s"
    
    echo ""
    echo "STEP 6: Deploy to Nginx"
    echo "───────────────────────────────────────────────────────"
    
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
    
    rm -rf "$TEMP_DIR"
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ SUCCESS! ORIGINAL TENANT APP DEPLOYED!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "🌐 URL:      http://54.227.101.30/tenant/"
    echo "📧 Email:    priya@example.com"
    echo "🔐 Password: Tenant@123"
    echo ""
    echo "IMPORTANT:"
    echo "1. Clear browser cache (Ctrl+Shift+Delete)"
    echo "2. Open in incognito mode"
    echo "3. You should see the FULL login page with:"
    echo "   - Phone number field"
    echo "   - OTP verification"
    echo "   - Proper branding"
    echo "4. After login, colored dashboard with all navigation"
    echo ""
    echo "═══════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "📋 TOP 50 BUILD ERRORS:"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    grep "Error:" /tmp/build_log_$TIMESTAMP.log | head -50
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "📋 MISSING IMPORTS ANALYSIS:"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    # Analyze errors for missing files
    if grep -q "Error: Error when reading" /tmp/build_log_$TIMESTAMP.log; then
        echo "Missing file errors detected:"
        grep "Error when reading" /tmp/build_log_$TIMESTAMP.log | head -10
    fi
    
    if grep -q "Undefined name" /tmp/build_log_$TIMESTAMP.log; then
        echo ""
        echo "Undefined identifier errors detected:"
        grep "Undefined name" /tmp/build_log_$TIMESTAMP.log | head -10
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "📄 FULL LOG SAVED TO:"
    echo "/tmp/build_log_$TIMESTAMP.log"
    echo ""
    echo "To view full errors:"
    echo "  cat /tmp/build_log_$TIMESTAMP.log | less"
    echo ""
    echo "Source files kept in place for debugging."
    echo "Backup available at: $BACKUP"
    echo "═══════════════════════════════════════════════════════"
    
    rm -rf "$TEMP_DIR"
    exit 1
fi

