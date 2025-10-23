#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 PATCHING TENANT SCREEN FILES"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This will fix State class getter/setter errors by:"
echo "  • Adding config.dart import to all screens"
echo "  • Replacing 'userID' with global userID from config"
echo "  • Replacing 'hostelID' with global hostelID from config"
echo "  • Adding null-safe access operators"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

# Backup
BACKUP_DIR="screens_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib/screens "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Add Config Import to All Screens"
echo "════════════════════════════════════════════════════════"

# Add import to all screen files if not present
for file in lib/screens/*.dart; do
    if [ -f "$file" ]; then
        if ! grep -q "import 'package:cloudpgtenant/config.dart'" "$file"; then
            # Add after the first import or at the top
            sed -i "1i import 'package:cloudpgtenant/config.dart' as config;" "$file"
            echo "✓ Added import to $(basename $file)"
        fi
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Fix Global Variable Access"
echo "════════════════════════════════════════════════════════"

# Fix food.dart
echo "Fixing food.dart..."
sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/food.dart
sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/food.dart
sed -i "s/\\.length/.length ?? 0/g" lib/screens/food.dart
sed -i "s/\\[0\\]/?.elementAt(0)/g" lib/screens/food.dart
sed -i "s/\\.isNotEmpty/?.isNotEmpty ?? false/g" lib/screens/food.dart
sed -i "s/\\.split(',')/?. split(',') ?? []/g" lib/screens/food.dart

# Fix editProfile.dart
echo "Fixing editProfile.dart..."
sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/editProfile.dart
sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/editProfile.dart
sed -i "s/name = /config.name = /g" lib/screens/editProfile.dart
sed -i "s/prefs.setString('name', name)/prefs.setString('name', config.name ?? '')/g" lib/screens/editProfile.dart

# Fix documents.dart
echo "Fixing documents.dart..."
sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/documents.dart
sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/documents.dart
sed -i "s/widget.user.document.isNotEmpty/widget.user.document?.isNotEmpty ?? false/g" lib/screens/documents.dart
sed -i "s/widget.user.document.split/widget.user.document?.split/g" lib/screens/documents.dart

# Fix profile.dart
echo "Fixing profile.dart..."
if [ -f "lib/screens/profile.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/profile.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/profile.dart
    sed -i "s/currentUser.document/currentUser.document ?? ''/g" lib/screens/profile.dart
fi

# Fix room.dart
echo "Fixing room.dart..."
if [ -f "lib/screens/room.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/room.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/room.dart
    sed -i "s/\\.roomID/?.roomID ?? ''/g" lib/screens/room.dart
    sed -i "s/currentRoom.amenities/currentRoom.amenities ?? ''/g" lib/screens/room.dart
fi

# Fix bills.dart
echo "Fixing bills.dart..."
if [ -f "lib/screens/bills.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/bills.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/bills.dart
fi

# Fix issues.dart
echo "Fixing issues.dart..."
if [ -f "lib/screens/issues.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/issues.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/issues.dart
fi

# Fix notices.dart
echo "Fixing notices.dart..."
if [ -f "lib/screens/notices.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/notices.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/notices.dart
fi

# Fix settings.dart
echo "Fixing settings.dart..."
if [ -f "lib/screens/settings.dart" ]; then
    sed -i "s/name/config.name ?? 'User'/g" lib/screens/settings.dart
    sed -i "s/hostelID = /config.hostelID = /g" lib/screens/settings.dart
    sed -i "s/amenities = /config.amenities = /g" lib/screens/settings.dart
    sed -i "s/hostels.hostels.forEach/hostels.hostels?.forEach/g" lib/screens/settings.dart
fi

# Fix dashboard.dart
echo "Fixing dashboard.dart..."
if [ -f "lib/screens/dashboard.dart" ]; then
    sed -i "s/'id': userID,/'id': config.userID ?? '',/g" lib/screens/dashboard.dart
    sed -i "s/'hostel_id': hostelID,/'hostel_id': config.hostelID ?? '',/g" lib/screens/dashboard.dart
fi

# Fix login.dart
echo "Fixing login.dart..."
if [ -f "lib/screens/login.dart" ]; then
    sed -i "s/name = /config.name = /g" lib/screens/login.dart
    sed -i "s/emailID = /config.emailID = /g" lib/screens/login.dart
    sed -i "s/hostelID = /config.hostelID = /g" lib/screens/login.dart
    sed -i "s/userID = /config.userID = /g" lib/screens/login.dart
    sed -i "s/users.meta.status/users.meta?.status ?? 0/g" lib/screens/login.dart
    sed -i "s/users.users.length/users.users?.length ?? 0/g" lib/screens/login.dart
    sed -i "s/users.users\[0\]/users.users?.elementAt(0)/g" lib/screens/login.dart
fi

# Fix main.dart
echo "Fixing main.dart..."
if [ -f "lib/main.dart" ]; then
    if ! grep -q "import 'package:cloudpgtenant/config.dart' as config;" lib/main.dart; then
        sed -i "1i import 'package:cloudpgtenant/config.dart' as config;" lib/main.dart
    fi
    sed -i "s/ONESIGNAL_APP_ID/config.ONESIGNAL_APP_ID/g" lib/main.dart
    sed -i "s/name = /config.name = /g" lib/main.dart
    sed -i "s/emailID = /config.emailID = /g" lib/main.dart
    sed -i "s/hostelID = /config.hostelID = /g" lib/main.dart
    sed -i "s/userID = /config.userID = /g" lib/main.dart
fi

echo "✓ All screen files patched"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Build Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "Getting dependencies..."
flutter pub get 2>&1 | tail -3

echo ""
echo "Building (this takes 2-4 minutes)..."
BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_patched.log | grep -E "Compiling|Built|✓|Error" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   Size: $SIZE"
    echo "   Time: ${BUILD_TIME}s"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 4: Deploy to Nginx"
    echo "════════════════════════════════════════════════════════"
    
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
    fi
    
    echo "Deploying..."
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    fi
    
    sudo systemctl reload nginx
    
    sleep 2
    
    TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT COMPLETE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 TENANT PORTAL:"
    echo "   URL:      http://13.221.117.236/tenant/"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo "   Status:   $([ "$TEST" = "200" ] && echo "✅ WORKING (HTTP $TEST)" || echo "⚠️  HTTP $TEST")"
    echo ""
    echo "⏱️  Build Time: ${BUILD_TIME}s"
    echo ""
    echo "⚡ CLEAR BROWSER CACHE:"
    echo "   • Hard refresh: Ctrl + Shift + R (Windows) / Cmd + Shift + R (Mac)"
    echo "   • Or use Incognito/Private mode"
    echo ""
    echo "════════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ BUILD STILL FAILED"
    echo ""
    echo "Remaining errors:"
    grep -i "error" /tmp/tenant_patched.log | head -30
    echo ""
    echo "Full log: /tmp/tenant_patched.log"
    echo ""
    echo "This means the Tenant app code has deeper architectural issues."
    echo "Recommendation: Use Admin app for all tenant management."
    echo ""
    echo "Admin app is working at: http://13.221.117.236/admin/"
    exit 1
fi

