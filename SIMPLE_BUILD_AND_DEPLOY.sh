#!/bin/bash
set -e

START_TIME=$(date +%s)

echo "════════════════════════════════════════════════════════"
echo "🚀 FAST BUILD & DEPLOY - No Infrastructure Changes"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Start Time: $(date '+%H:%M:%S')"
echo "Target: <5 minutes"
echo ""

# Quick system check
echo "System Info:"
TOTAL_RAM=$(free -h | awk 'NR==2{print $2}')
AVAIL_DISK=$(df -h / | tail -1 | awk '{print $4}')
CPU_COUNT=$(nproc)
echo "  RAM: $TOTAL_RAM | Disk: $AVAIL_DISK | CPUs: $CPU_COUNT"
echo ""

# Set environment variables
export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache
export FLUTTER_ROOT=/opt/flutter

# ============================================================
# PARALLEL BUILD
# ============================================================

echo "╔════════════════════════════════════════════════════════╗"
echo "║  BUILDING ADMIN & TENANT IN PARALLEL                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

BUILD_START=$(date +%s)

# Build function
build_app() {
    local APP_NAME=$1
    local APP_DIR=$2
    
    cd "$APP_DIR"
    
    echo "[$APP_NAME] Starting..."
    
    # Check for recent build
    if [ -f "build/web/main.dart.js" ]; then
        AGE=$(( $(date +%s) - $(stat -c %Y build/web/main.dart.js 2>/dev/null || echo 0) ))
        if [ $AGE -lt 3600 ]; then
            SIZE=$(du -h build/web/main.dart.js | cut -f1)
            echo "[$APP_NAME] ✓ Recent build exists ($SIZE) - SKIPPING"
            return 0
        fi
    fi
    
    # Clean and build
    flutter clean > /dev/null 2>&1
    rm -rf .dart_tool build
    
    flutter pub get > /dev/null 2>&1
    
    flutter build web \
        --release \
        --no-source-maps \
        --no-tree-shake-icons \
        --dart-define=dart.vm.product=true \
        2>&1 | grep -E "Compiling|Built|Error|Failed" || true
    
    if [ -f "build/web/main.dart.js" ]; then
        SIZE=$(du -h build/web/main.dart.js | cut -f1)
        echo "[$APP_NAME] ✅ SUCCESS ($SIZE)"
        return 0
    else
        echo "[$APP_NAME] ❌ FAILED"
        return 1
    fi
}

export -f build_app
export DART_VM_OPTIONS PUB_CACHE FLUTTER_ROOT

# Fix Tenant config first
echo "[TENANT] Applying code fixes..."
cd /home/ec2-user/pgni/pgworldtenant-master
if [ ! -f "lib/utils/config.dart" ]; then
    mkdir -p lib/utils
    cat > lib/utils/config.dart << 'EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const int timeout = 30;
  static Map<String, String> get headers => {'Content-Type': 'application/json', 'Accept': 'application/json'};
}
class API {
  static const String URL = "34.227.111.143:8080";
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
const String mediaURL = "http://34.227.111.143:8080/uploads/";
const int timeout = 30;
const String defaultOffset = "0";
const String defaultLimit = "20";
const int STATUS_403 = 403;
String hostelID = "";
String userID = "";
Map<String, String> headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
EOF
fi
sed -i 's/String color;/String? color;/g' lib/utils/models.dart 2>/dev/null || true
sed -i 's/IconData icon;/IconData? icon;/g' lib/utils/models.dart 2>/dev/null || true
sed -i 's/String title;/String? title;/g' lib/utils/models.dart 2>/dev/null || true
echo "[TENANT] ✓ Fixes applied"
echo ""

# Launch parallel builds
(build_app "ADMIN" "/home/ec2-user/pgni/pgworld-master" && echo "0" > /tmp/admin.status || echo "1" > /tmp/admin.status) &
ADMIN_PID=$!

(build_app "TENANT" "/home/ec2-user/pgni/pgworldtenant-master" && echo "0" > /tmp/tenant.status || echo "1" > /tmp/tenant.status) &
TENANT_PID=$!

# Wait with progress
echo "Building... (this takes 3-5 minutes)"
while kill -0 $ADMIN_PID 2>/dev/null || kill -0 $TENANT_PID 2>/dev/null; do
    printf "."
    sleep 2
done
echo ""
echo ""

# Check results
ADMIN_OK=$(cat /tmp/admin.status 2>/dev/null || echo 1)
TENANT_OK=$(cat /tmp/tenant.status 2>/dev/null || echo 1)

BUILD_TIME=$(( $(date +%s) - BUILD_START ))
echo "Build Time: ${BUILD_TIME}s"
echo ""

if [ "$ADMIN_OK" != "0" ]; then
    echo "❌ Admin build failed"
    exit 1
fi

# ============================================================
# DEPLOYMENT
# ============================================================

echo "╔════════════════════════════════════════════════════════╗"
echo "║  DEPLOYING TO NGINX                                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Deploy Admin
echo "Deploying Admin..."
sudo rm -rf /usr/share/nginx/html/admin
sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
echo "  ✓ Admin deployed"

# Deploy Tenant if successful
if [ "$TENANT_OK" = "0" ]; then
    echo "Deploying Tenant..."
    sudo rm -rf /usr/share/nginx/html/tenant
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/
    echo "  ✓ Tenant deployed"
else
    echo "⚠️  Tenant build failed - deploying Admin only"
fi

# Set permissions
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html 2>/dev/null || true
fi

sudo systemctl reload nginx
echo "  ✓ Nginx reloaded"
echo ""

# ============================================================
# VERIFICATION
# ============================================================

echo "╔════════════════════════════════════════════════════════╗"
echo "║  VERIFICATION                                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

ADMIN_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
ADMIN_JS=$(ls -lh /usr/share/nginx/html/admin/main.dart.js 2>/dev/null | awk '{print $5}')

echo "Admin Portal:"
echo "  HTTP Status: $ADMIN_HTTP $([ "$ADMIN_HTTP" = "200" ] && echo "✅" || echo "❌")"
echo "  main.dart.js: $ADMIN_JS"

if [ "$TENANT_OK" = "0" ]; then
    TENANT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    TENANT_JS=$(ls -lh /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null | awk '{print $5}')
    
    echo ""
    echo "Tenant Portal:"
    echo "  HTTP Status: $TENANT_HTTP $([ "$TENANT_HTTP" = "200" ] && echo "✅" || echo "❌")"
    echo "  main.dart.js: $TENANT_JS"
fi

echo ""

# ============================================================
# SUMMARY
# ============================================================

TOTAL_TIME=$(( $(date +%s) - START_TIME ))
TOTAL_MIN=$(( TOTAL_TIME / 60 ))
TOTAL_SEC=$(( TOTAL_TIME % 60 ))

echo "════════════════════════════════════════════════════════"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "⏱️  Total Time: ${TOTAL_MIN}m ${TOTAL_SEC}s"
if [ $TOTAL_TIME -lt 300 ]; then
    echo "   Status: ✅ Under 5 minutes!"
else
    echo "   Status: ⚠️  Slower than target (but successful)"
fi
echo ""
echo "🌐 Access Your Applications:"
echo "   Admin:  http://34.227.111.143/admin/"
if [ "$TENANT_OK" = "0" ]; then
    echo "   Tenant: http://34.227.111.143/tenant/"
fi
echo ""
echo "🔐 Login Credentials:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "✅ Done!"
echo ""

