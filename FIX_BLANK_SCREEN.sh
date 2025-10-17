#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING BLANK SCREEN ISSUE"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"

# Check what's currently deployed
echo "STEP 1: Diagnosing Current Deployment"
echo "────────────────────────────────────────────────────────"

echo "Checking /admin/ deployment:"
if [ -f "/usr/share/nginx/html/admin/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h /usr/share/nginx/html/admin/main.dart.js | cut -f1)
    ADMIN_FILES=$(ls -1 /usr/share/nginx/html/admin/ | wc -l)
    echo "  ✓ Admin: $ADMIN_FILES files, main.dart.js: $ADMIN_SIZE"
    
    # Check if it's actually loading
    if grep -q "flutter" /usr/share/nginx/html/admin/index.html 2>/dev/null; then
        echo "  ✓ Admin index.html looks valid"
    else
        echo "  ✗ Admin index.html may be corrupted"
    fi
else
    echo "  ✗ Admin NOT deployed!"
fi

echo ""
echo "Checking /tenant/ deployment:"
if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    TENANT_SIZE=$(du -h /usr/share/nginx/html/tenant/main.dart.js | cut -f1)
    TENANT_FILES=$(ls -1 /usr/share/nginx/html/tenant/ | wc -l)
    echo "  ✓ Tenant: $TENANT_FILES files, main.dart.js: $TENANT_SIZE"
else
    echo "  ✗ Tenant NOT deployed!"
fi

echo ""
echo "Checking Nginx logs for errors:"
if sudo test -f /var/log/nginx/error.log; then
    ERRORS=$(sudo tail -20 /var/log/nginx/error.log | grep -i "error\|failed" | tail -5)
    if [ -n "$ERRORS" ]; then
        echo "  Recent errors found:"
        echo "$ERRORS"
    else
        echo "  ✓ No recent errors"
    fi
fi

echo ""
echo "Testing HTTP responses:"
ADMIN_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo "  Admin:  HTTP $ADMIN_HTTP"
echo "  Tenant: HTTP $TENANT_HTTP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Rebuilding Admin App (Correct Configuration)"
echo "════════════════════════════════════════════════════════"
echo ""

cd /home/ec2-user/pgni/pgworld-master

# Update config with correct IP
echo "Updating config..."
cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "13.221.117.236:8080";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class API {
  static const String URL = "13.221.117.236:8080";
  static const String SEND_OTP = "/api/send-otp";
  static const String VERIFY_OTP = "/api/verify-otp";
  static const String BILL = "/api/bills";
  static const String USER = "/api/users";
  static const String HOSTEL = "/api/hostels";
  static const String ISSUE = "/api/issues";
  static const String NOTICE = "/api/notices";
  static const String ROOM = "/api/rooms";
  static const String SUPPORT = "/api/support";
  static const String SIGNUP = "/api/signup";
}

const String mediaURL = "http://13.221.117.236:8080/uploads/";
EOF

echo "✓ Config updated"

# Clean build
echo ""
echo "Building Admin app (this takes 3-5 minutes)..."
export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

flutter pub get > /dev/null 2>&1

BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/admin/" \
    2>&1 | tee /tmp/admin_build.log | grep -E "Compiling|Built|Error" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILES=$(ls -1 build/web | wc -l)
    echo ""
    echo "✅ Build successful!"
    echo "   Size: $SIZE"
    echo "   Files: $FILES"
    echo "   Time: ${BUILD_TIME}s"
else
    echo ""
    echo "❌ Build failed!"
    echo "Last 30 lines of build log:"
    tail -30 /tmp/admin_build.log
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Deploying with Correct Permissions"
echo "════════════════════════════════════════════════════════"
echo ""

# Backup old deployment
if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s)
    echo "✓ Old admin deployment backed up"
fi

# Deploy
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/

# Fix permissions
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# SELinux
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html 2>/dev/null || true
    echo "✓ SELinux context fixed"
fi

echo "✓ Admin deployed"

# Verify deployment
echo ""
echo "Verifying files:"
ls -lh /usr/share/nginx/html/admin/ | head -15

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Testing & Verification"
echo "════════════════════════════════════════════════════════"
echo ""

# Reload Nginx
sudo systemctl reload nginx
echo "✓ Nginx reloaded"

sleep 2

# Test
ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
echo ""
echo "HTTP Status: $ADMIN_TEST"

if [ "$ADMIN_TEST" = "200" ]; then
    echo "✅ Admin portal responding!"
else
    echo "⚠️  Admin portal status: $ADMIN_TEST"
fi

# Check for JavaScript
if curl -s http://localhost/admin/ | grep -q "main.dart.js"; then
    echo "✅ JavaScript files referenced correctly"
else
    echo "⚠️  JavaScript may not be loading"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ FIX COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access Your Application:"
echo "   http://$PUBLIC_IP/admin/"
echo ""
echo "🔐 Login:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 TROUBLESHOOTING:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "If you still see a blank page:"
echo ""
echo "1. Hard refresh browser:"
echo "   • Windows: Ctrl + Shift + R"
echo "   • Mac: Cmd + Shift + R"
echo ""
echo "2. Clear browser cache or use Incognito mode"
echo ""
echo "3. Check browser console (F12 → Console tab):"
echo "   Look for red errors and share them"
echo ""
echo "4. Check what files are loading:"
echo "   F12 → Network tab → Reload page"
echo "   Look for failed requests (red)"
echo ""
echo "5. Verify from EC2:"
echo "   curl http://localhost/admin/ | head -50"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

