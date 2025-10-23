#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "📥 RESTORING TENANT APP SOURCE FROM GITHUB"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
GITHUB_REPO="https://github.com/siddam01/pgni.git"
TEMP_DIR="/tmp/pgni_restore_$(date +%Y%m%d_%H%M%S)"

echo "STEP 1: Backup Current State"
echo "───────────────────────────────────────────────────────"

BACKUP="github_restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TENANT_PATH/$BACKUP"
[ -d "$TENANT_PATH/lib" ] && cp -r "$TENANT_PATH/lib" "$TENANT_PATH/$BACKUP/" 2>/dev/null || true
echo "✓ Backed up current state to: $BACKUP"

echo ""
echo "STEP 2: Clone Repository"
echo "───────────────────────────────────────────────────────"

git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR"
echo "✓ Cloned repository"

echo ""
echo "STEP 3: Check for Tenant Source"
echo "───────────────────────────────────────────────────────"

if [ -d "$TEMP_DIR/pgworldtenant-master/lib" ]; then
    SOURCE_SCREENS=$(find "$TEMP_DIR/pgworldtenant-master/lib/screens" -name "*.dart" 2>/dev/null | wc -l)
    echo "✓ Found tenant source in GitHub"
    echo "  Screens: $SOURCE_SCREENS files"
    
    # Check if these are original files (>100 lines)
    if [ -f "$TEMP_DIR/pgworldtenant-master/lib/screens/login.dart" ]; then
        LOGIN_LINES=$(wc -l < "$TEMP_DIR/pgworldtenant-master/lib/screens/login.dart")
        if [ $LOGIN_LINES -gt 200 ]; then
            echo "  ✓ Original source code confirmed ($LOGIN_LINES lines in login.dart)"
        else
            echo "  ⚠️  Source may be simplified ($LOGIN_LINES lines in login.dart)"
        fi
    fi
else
    echo "❌ Tenant source not found in GitHub repository!"
    echo ""
    echo "The repository doesn't contain the tenant source code."
    echo "You need to:"
    echo "1. Push your local pgworldtenant-master/lib/ to GitHub first"
    echo "2. Then run this script again"
    echo ""
    echo "OR use SCP to upload directly from your machine:"
    echo "  scp -r pgworldtenant-master/lib/ ec2-user@54.227.101.30:/home/ec2-user/pgni/pgworldtenant-master/"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "STEP 4: Restore Source Files"
echo "───────────────────────────────────────────────────────"

# Remove current (placeholder) source
rm -rf "$TENANT_PATH/lib"

# Copy original source from GitHub
cp -r "$TEMP_DIR/pgworldtenant-master/lib" "$TENANT_PATH/"
echo "✓ Restored source files"

# Verify restoration
RESTORED_SCREENS=$(find "$TENANT_PATH/lib/screens" -name "*.dart" 2>/dev/null | wc -l)
echo "✓ Verified: $RESTORED_SCREENS screen files"

# Check key files
echo ""
echo "Checking key files:"
for file in "login.dart" "dashboard.dart" "profile.dart" "room.dart" "issues.dart"; do
    if [ -f "$TENANT_PATH/lib/screens/$file" ]; then
        LINES=$(wc -l < "$TENANT_PATH/lib/screens/$file")
        echo "  ✓ $file ($LINES lines)"
    else
        echo "  ✗ $file MISSING"
    fi
done

echo ""
echo "STEP 5: Build and Deploy"
echo "───────────────────────────────────────────────────────"

cd "$TENANT_PATH"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
echo "✓ Cleaned"

flutter pub get 2>&1 | tail -3
echo "✓ Dependencies"

echo ""
echo "Building (2-3 minutes)..."
BUILD_START=$(date +%s)

flutter build web --release --base-href="/tenant/" --no-source-maps 2>&1 | grep -E "Compiling|Built|✓" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Build failed!"
    echo "Restoring backup..."
    rm -rf lib
    cp -r "$BACKUP/lib" .
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo "✅ Built: $SIZE in ${BUILD_TIME}s"

echo ""
echo "Deploying..."
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

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ RESTORATION COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 URL:      http://54.227.101.30/tenant/"
echo "📧 Email:    priya@example.com"
echo "🔐 Password: Tenant@123"
echo ""
echo "📊 Restored: $RESTORED_SCREENS screen files"
echo "⏱️  Build:    ${BUILD_TIME}s"
echo "📦 Size:     $SIZE"
echo ""
echo "IMPORTANT: Clear browser cache before testing!"
echo "  Windows: Ctrl + Shift + Delete"
echo "  Or use incognito mode"
echo ""
echo "═══════════════════════════════════════════════════════"

