#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🚀 FIXING BOTH ADMIN & TENANT APPS"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"
START_TIME=$(date +%s)

# Function to show progress
show_progress() {
    echo ""
    echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
    echo "$1"
    echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
    echo ""
}

show_progress "STEP 1/5: Pre-Deployment Diagnostics"

echo "Current deployment status:"
echo "─────────────────────────────────────────────────────"

if [ -f "/usr/share/nginx/html/admin/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h /usr/share/nginx/html/admin/main.dart.js | cut -f1)
    echo "✓ Admin deployed ($ADMIN_SIZE)"
else
    echo "✗ Admin NOT deployed"
fi

if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    TENANT_SIZE=$(du -h /usr/share/nginx/html/tenant/main.dart.js | cut -f1)
    echo "✓ Tenant deployed ($TENANT_SIZE)"
else
    echo "✗ Tenant NOT deployed"
fi

echo ""
echo "HTTP Status Check:"
ADMIN_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/ || echo "FAIL")
TENANT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/ || echo "FAIL")
echo "  Admin:  $ADMIN_HTTP"
echo "  Tenant: $TENANT_HTTP"

# Set up environment
export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache

show_progress "STEP 2/5: Building ADMIN App"

cd /home/ec2-user/pgni/pgworld-master

echo "Updating Admin config..."
cat > lib/utils/config.dart << EOF
class Config {
  static const String URL = "$PUBLIC_IP:$API_PORT";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class API {
  static const String URL = "$PUBLIC_IP:$API_PORT";
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

const String mediaURL = "http://$PUBLIC_IP:$API_PORT/uploads/";
const int STATUS_403 = 403;
EOF

echo "✓ Admin config updated"

echo ""
echo "Cleaning & building Admin app..."
flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

flutter pub get > /dev/null 2>&1

ADMIN_BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/admin/" \
    2>&1 | tee /tmp/admin_build.log | grep -E "Compiling|Built|Error|✓" || true

ADMIN_BUILD_END=$(date +%s)
ADMIN_BUILD_TIME=$((ADMIN_BUILD_END - ADMIN_BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    ADMIN_FILES=$(ls -1 build/web | wc -l)
    echo ""
    echo "✅ Admin build successful!"
    echo "   Size: $ADMIN_SIZE | Files: $ADMIN_FILES | Time: ${ADMIN_BUILD_TIME}s"
else
    echo ""
    echo "❌ Admin build FAILED!"
    tail -30 /tmp/admin_build.log
    exit 1
fi

show_progress "STEP 3/5: Building TENANT App"

cd /home/ec2-user/pgni/pgworldtenant-master

echo "Updating Tenant config..."
mkdir -p lib/utils
cat > lib/utils/config.dart << EOF
class API {
  static const String URL = "$PUBLIC_IP:$API_PORT";
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

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
}

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://$PUBLIC_IP:$API_PORT/uploads/";
EOF

echo "✓ Tenant config updated"

echo ""
echo "Cleaning & building Tenant app..."
flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

flutter pub get > /dev/null 2>&1

TENANT_BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_build.log | grep -E "Compiling|Built|Error|✓" || true

TENANT_BUILD_END=$(date +%s)
TENANT_BUILD_TIME=$((TENANT_BUILD_END - TENANT_BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    TENANT_FILES=$(ls -1 build/web | wc -l)
    echo ""
    echo "✅ Tenant build successful!"
    echo "   Size: $TENANT_SIZE | Files: $TENANT_FILES | Time: ${TENANT_BUILD_TIME}s"
else
    echo ""
    echo "❌ Tenant build FAILED!"
    tail -30 /tmp/tenant_build.log
    exit 1
fi

show_progress "STEP 4/5: Deploying to Nginx"

# Backup old deployments
if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s) 2>/dev/null || true
fi

if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
fi

# Deploy Admin
echo "Deploying Admin app..."
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
echo "✓ Admin deployed"

# Deploy Tenant
echo "Deploying Tenant app..."
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/
echo "✓ Tenant deployed"

# Fix permissions
echo ""
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html/admin -type f -exec chmod 644 {} \;
sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
echo "✓ Permissions set"

# SELinux
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo ""
    echo "Fixing SELinux context..."
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html 2>/dev/null || true
    echo "✓ SELinux fixed"
fi

# Reload Nginx
echo ""
echo "Reloading Nginx..."
sudo systemctl reload nginx
echo "✓ Nginx reloaded"

show_progress "STEP 5/5: Verification & Testing"

sleep 2

# Test URLs
ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo "HTTP Status Check:"
echo "─────────────────────────────────────────────────────"

if [ "$ADMIN_TEST" = "200" ]; then
    echo "✅ Admin:  HTTP $ADMIN_TEST (Working!)"
else
    echo "⚠️  Admin:  HTTP $ADMIN_TEST"
fi

if [ "$TENANT_TEST" = "200" ]; then
    echo "✅ Tenant: HTTP $TENANT_TEST (Working!)"
else
    echo "⚠️  Tenant: HTTP $TENANT_TEST"
fi

echo ""
echo "Checking JavaScript files..."

if curl -s http://localhost/admin/ | grep -q "main.dart.js"; then
    echo "✅ Admin JavaScript loading correctly"
else
    echo "⚠️  Admin JavaScript may have issues"
fi

if curl -s http://localhost/tenant/ | grep -q "main.dart.js"; then
    echo "✅ Tenant JavaScript loading correctly"
else
    echo "⚠️  Tenant JavaScript may have issues"
fi

echo ""
echo "Deployed files:"
echo "─────────────────────────────────────────────────────"
echo "Admin:  $(ls -1 /usr/share/nginx/html/admin | wc -l) files"
echo "Tenant: $(ls -1 /usr/share/nginx/html/tenant | wc -l) files"

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))
SECONDS=$((TOTAL_TIME % 60))

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "⏱️  Total Time: ${MINUTES}m ${SECONDS}s"
echo "   Admin build:  ${ADMIN_BUILD_TIME}s"
echo "   Tenant build: ${TENANT_BUILD_TIME}s"
echo ""
echo "🌐 Access Your Applications:"
echo "─────────────────────────────────────────────────────"
echo ""
echo "   👨‍💼 ADMIN PORTAL:"
echo "      URL:      http://$PUBLIC_IP/admin/"
echo "      Email:    admin@pgworld.com"
echo "      Password: Admin@123"
echo ""
echo "   👤 TENANT PORTAL:"
echo "      URL:      http://$PUBLIC_IP/tenant/"
echo "      Email:    tenant@pgworld.com"
echo "      Password: Tenant@123"
echo ""
echo "   🔌 BACKEND API:"
echo "      URL:      http://$PUBLIC_IP:$API_PORT/"
echo "      Health:   http://$PUBLIC_IP:$API_PORT/health"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 IMPORTANT: After Deployment"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. ⚡ HARD REFRESH your browser:"
echo "   Windows: Ctrl + Shift + R"
echo "   Mac:     Cmd + Shift + R"
echo ""
echo "2. 🔍 Or use Incognito/Private mode to bypass cache"
echo ""
echo "3. 🐛 If you see blank screen:"
echo "   • Press F12 to open Developer Console"
echo "   • Click 'Console' tab"
echo "   • Look for red error messages"
echo "   • Share those errors for help"
echo ""
echo "4. 🌐 Check Network tab (F12 → Network):"
echo "   • Reload page"
echo "   • Look for failed requests (red/404)"
echo "   • Check if main.dart.js is loading"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🛠️  Troubleshooting Commands"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Check Nginx status:"
echo "  sudo systemctl status nginx"
echo ""
echo "Check Nginx logs:"
echo "  sudo tail -50 /var/log/nginx/error.log"
echo ""
echo "Test locally:"
echo "  curl http://localhost/admin/ | head -50"
echo "  curl http://localhost/tenant/ | head -50"
echo ""
echo "View deployed files:"
echo "  ls -lh /usr/share/nginx/html/admin/"
echo "  ls -lh /usr/share/nginx/html/tenant/"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

