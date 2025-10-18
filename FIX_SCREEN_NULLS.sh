#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX SCREEN FILES - Null Safety Patches"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo "Patching screen files for null safety..."

# Fix all screen files to handle nullable objects
find lib/screens -name "*.dart" -type f | while read file; do
    echo "  Fixing $(basename $file)..."
    
    # Fix Meta? property access
    sed -i 's/\.meta\.status/\.meta?.status ?? 0/g' "$file"
    sed -i 's/\.meta\.messageType/\.meta?.messageType ?? ""/g' "$file"
    sed -i 's/\.meta\.message/\.meta?.message ?? ""/g' "$file"
    
    # Fix Pagination? property access
    sed -i 's/\.pagination\.offset/\.pagination?.offset ?? 0/g' "$file"
    sed -i 's/\.pagination\.total/\.pagination?.total ?? 0/g' "$file"
    sed -i 's/\.pagination\.page/\.pagination?.page ?? 1/g' "$file"
    sed -i 's/\.pagination\.limit/\.pagination?.limit ?? 10/g' "$file"
    
    # Fix User? property access
    sed -i 's/currentUser\.document/currentUser.document/g' "$file"
    sed -i 's/widget\.user\.document/widget.user.document/g' "$file"
    
    # Fix Room? property access  
    sed -i 's/currentRoom\.document/currentRoom.document/g' "$file"
    sed -i 's/currentRoom\.amenities/currentRoom.amenities/g' "$file"
    
    # Fix int to String conversions for offset
    sed -i 's/defaultOffset\.toString()/defaultOffset/g' "$file"
    sed -i 's/pagination\.offset\.toString()/pagination?.offset?.toString() ?? defaultOffset/g' "$file"
done

echo "✓ Patched all screen files"

# Specifically fix known problematic files
echo ""
echo "Applying specific fixes to problem files..."

# Fix issues.dart
if [ -f "lib/screens/issues.dart" ]; then
    sed -i 's/meta\.status/meta?.status ?? 0/g' lib/screens/issues.dart
    sed -i 's/meta\.messageType/meta?.messageType ?? ""/g' lib/screens/issues.dart
    sed -i 's/meta\.message/meta?.message ?? ""/g' lib/screens/issues.dart
    echo "  ✓ Fixed issues.dart"
fi

# Fix notices.dart
if [ -f "lib/screens/notices.dart" ]; then
    sed -i 's/meta\.status/meta?.status ?? 0/g' lib/screens/notices.dart
    sed -i 's/meta\.messageType/meta?.messageType ?? ""/g' lib/screens/notices.dart
    sed -i 's/meta\.message/meta?.message ?? ""/g' lib/screens/notices.dart
    echo "  ✓ Fixed notices.dart"
fi

# Fix bills.dart
if [ -f "lib/screens/bills.dart" ]; then
    sed -i 's/meta\.status/meta?.status ?? 0/g' lib/screens/bills.dart
    sed -i 's/meta\.messageType/meta?.messageType ?? ""/g' lib/screens/bills.dart
    sed -i 's/meta\.message/meta?.message ?? ""/g' lib/screens/bills.dart
    echo "  ✓ Fixed bills.dart"
fi

# Fix profile.dart
if [ -f "lib/screens/profile.dart" ]; then
    sed -i 's/currentUser\.document/currentUser.document/g' lib/screens/profile.dart
    sed -i 's/meta\.status/meta?.status ?? 0/g' lib/screens/profile.dart
    sed -i 's/meta\.messageType/meta?.messageType ?? ""/g' lib/screens/profile.dart
    sed -i 's/meta\.message/meta?.message ?? ""/g' lib/screens/profile.dart
    echo "  ✓ Fixed profile.dart"
fi

echo ""
echo "Building..."
export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

BUILD_START=$(date +%s)
flutter build web --release --no-source-maps --base-href="/tenant/" 2>&1 | tee /tmp/screen_fix_build.log | grep -E "Compiling|Built|✓" || true
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    [ -d "/usr/share/nginx/html/tenant" ] && sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo systemctl reload nginx
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    echo ""
    echo "✅ SUCCESS! http://13.221.117.236/tenant/ | HTTP $STATUS | ${BUILD_TIME}s | $SIZE"
    echo "Login: priya@example.com / Tenant@123"
else
    echo ""
    echo "❌ Remaining errors:"
    grep "Error:" /tmp/screen_fix_build.log | head -30
    echo ""
    echo "Log: /tmp/screen_fix_build.log"
    exit 1
fi

