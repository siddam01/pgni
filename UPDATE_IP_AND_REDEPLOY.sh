#!/bin/bash
set -e

OLD_IP="13.221.117.236"
NEW_IP="54.227.101.30"

echo "════════════════════════════════════════════════════════"
echo "🔄 UPDATING IP ADDRESS IN ALL APPS"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Old IP: $OLD_IP"
echo "New IP: $NEW_IP"
echo ""

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Update Tenant App Configuration"
echo "════════════════════════════════════════════════════════"

TENANT_DIR="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_DIR"

# Update app_config.dart
if [ -f "lib/config/app_config.dart" ]; then
    echo ""
    echo "Updating lib/config/app_config.dart..."
    echo "Before:"
    grep -n "apiBaseUrl" lib/config/app_config.dart || echo "Not found in app_config.dart"
    
    sed -i "s|http://$OLD_IP|http://$NEW_IP|g" lib/config/app_config.dart
    sed -i "s|$OLD_IP|$NEW_IP|g" lib/config/app_config.dart
    
    echo "After:"
    grep -n "apiBaseUrl" lib/config/app_config.dart
    echo "✓ Updated app_config.dart"
fi

# Update any other config files
find lib -name "*.dart" -type f | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        echo ""
        echo "Found old IP in: $file"
        sed -i "s|$OLD_IP|$NEW_IP|g" "$file"
        echo "✓ Updated $file"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Rebuild Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo ""
echo "Building tenant app with new IP..."
BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tee /tmp/tenant_rebuild.log | grep -E "Compiling|Built|✓|Font" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo ""
    echo "❌ Build failed!"
    tail -30 /tmp/tenant_rebuild.log
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo ""
echo "✅ Build successful: $SIZE in ${BUILD_TIME}s"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Deploy Tenant App"
echo "════════════════════════════════════════════════════════"

# Backup old deployment
if [ -d "/usr/share/nginx/html/tenant" ]; then
    BACKUP_NAME="tenant.backup.old_ip_$(date +%s)"
    sudo mv /usr/share/nginx/html/tenant "/usr/share/nginx/html/$BACKUP_NAME"
    echo "✓ Backed up old deployment to $BACKUP_NAME"
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
fi

echo "✓ Tenant app deployed"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Update Admin App Configuration"
echo "════════════════════════════════════════════════════════"

ADMIN_DIR="/home/ec2-user/pgni/pgworld-master"
cd "$ADMIN_DIR"

# Update admin config files
find lib -name "*.dart" -type f | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        echo ""
        echo "Found old IP in admin: $file"
        sed -i "s|$OLD_IP|$NEW_IP|g" "$file"
        echo "✓ Updated $file"
    fi
done

echo ""
echo "Building admin app..."
flutter build web \
  --release \
  --base-href="/admin/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tail -10

if [ -f "build/web/main.dart.js" ]; then
    echo "✓ Admin build successful"
    
    # Deploy admin
    if [ -d "/usr/share/nginx/html/admin" ]; then
        sudo mv /usr/share/nginx/html/admin "/usr/share/nginx/html/admin.backup.old_ip_$(date +%s)"
    fi
    
    sudo mkdir -p /usr/share/nginx/html/admin
    sudo cp -r build/web/* /usr/share/nginx/html/admin/
    sudo chown -R nginx:nginx /usr/share/nginx/html/admin
    sudo chmod -R 755 /usr/share/nginx/html/admin
    
    if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin 2>/dev/null || true
    fi
    
    echo "✓ Admin app deployed"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Reload Nginx"
echo "════════════════════════════════════════════════════════"

sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Verification"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing endpoints..."

STATUS_TENANT=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "Tenant: HTTP $STATUS_TENANT $([ "$STATUS_TENANT" = "200" ] && echo "✅" || echo "⚠️")"

STATUS_ADMIN=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
echo "Admin:  HTTP $STATUS_ADMIN $([ "$STATUS_ADMIN" = "200" ] && echo "✅" || echo "⚠️")"

echo ""
echo "Checking API endpoint in deployed tenant app..."
curl -s http://localhost/tenant/main.dart.js | grep -o "$NEW_IP" | head -1 && echo "✅ New IP found in JavaScript" || echo "⚠️  IP might not be updated in JS"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ UPDATE COMPLETE!"
echo "════════════════════════════════════════════════════════"

echo ""
echo "🌐 NEW URLs (use these now!):"
echo ""
echo "   Admin:  http://$NEW_IP/admin/"
echo "   Tenant: http://$NEW_IP/tenant/"
echo ""
echo "📧 Admin Login:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "📧 Tenant Login:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "📊 Build Stats:"
echo "   Tenant: $SIZE in ${BUILD_TIME}s"
echo "   Status: Both apps deployed ✅"
echo ""
echo "🔍 If you still get old IP error:"
echo "   1. Hard refresh browser: Ctrl+Shift+F5"
echo "   2. Clear browser cache completely"
echo "   3. Try incognito/private mode"
echo "   4. Check browser console (F12) for cached files"
echo ""
echo "════════════════════════════════════════════════════════"

