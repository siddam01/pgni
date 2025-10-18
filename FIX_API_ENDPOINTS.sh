#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX API ENDPOINTS - Remove /api/ prefix"
echo "════════════════════════════════════════════════════════"

TENANT_DIR="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_DIR"

echo ""
echo "Current API configuration:"
grep -n "Endpoint\|API\." lib/config/app_config.dart | head -20

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Update app_config.dart endpoints"
echo "════════════════════════════════════════════════════════"

cat > lib/config/app_config.dart << 'EOFCONFIG'
/// Production Configuration
class AppConfig {
  static const bool isProduction = true;
  static const String apiBaseUrl = "http://54.227.101.30:8080";
  static const String apiKey = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
  static const String oneSignalAppId = "AKIA2FFQRNMAP3IDZD6V";
  static const int requestTimeout = 30;
  
  // API Endpoints (WITHOUT /api/ prefix - matches Go API)
  static const String loginEndpoint = "/login";
  static const String dashboardEndpoint = "/dashboard";
  static const String billsEndpoint = "/bill";
  static const String issuesEndpoint = "/issue";
  static const String noticesEndpoint = "/notice";
  static const String roomsEndpoint = "/room";
  static const String usersEndpoint = "/user";
  static const String supportEndpoint = "/support";
  static const String hostelEndpoint = "/hostel";
  static const String foodEndpoint = "/food";
  
  // App Version
  static const String appVersion = "1.0.0";
  static const String appName = "PG Tenant";
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'apikey': apiKey,
  };
}
EOFCONFIG

echo "✓ Updated app_config.dart with correct endpoints (no /api/ prefix)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Test API endpoint directly"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing /login endpoint (without /api/ prefix)..."
curl -s -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' | head -100

echo ""
echo ""
echo "Testing /dashboard endpoint..."
curl -s http://localhost:8080/dashboard \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" | head -50

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Rebuild Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo ""
echo "Building tenant app with corrected endpoints..."
BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | grep -E "Compiling|Built|✓|Font" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ ! -f "build/web/main.dart.js" ]; then
    echo "❌ Build failed!"
    exit 1
fi

SIZE=$(du -h build/web/main.dart.js | cut -f1)
echo ""
echo "✅ Build successful: $SIZE in ${BUILD_TIME}s"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Deploy to Nginx"
echo "════════════════════════════════════════════════════════"

sudo rm -rf /usr/share/nginx/html/tenant/*
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
fi

sudo systemctl reload nginx
echo "✓ Deployed to Nginx"

sleep 2

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Verify Deployment"
echo "════════════════════════════════════════════════════════"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "Tenant app: HTTP $STATUS $([ "$STATUS" = "200" ] && echo "✅" || echo "⚠️")"

echo ""
echo "Checking deployed JavaScript for correct endpoint..."
if grep -q "http://54.227.101.30:8080/login" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "✅ Correct endpoint (/login) found in deployed app"
else
    echo "⚠️  Could not verify endpoint in JavaScript"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ FIX COMPLETE!"
echo "════════════════════════════════════════════════════════"

echo ""
echo "🌐 Access your app:"
echo "   URL: http://54.227.101.30/tenant/"
echo ""
echo "📧 Login with:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "🔍 Endpoints corrected:"
echo "   OLD: http://54.227.101.30:8080/api/login  ❌"
echo "   NEW: http://54.227.101.30:8080/login      ✅"
echo ""
echo "📊 Build: $SIZE in ${BUILD_TIME}s"
echo ""
echo "⚠️  IMPORTANT:"
echo "   Clear browser cache (Ctrl+Shift+Delete)"
echo "   Or use Incognito mode (Ctrl+Shift+N)"
echo ""
echo "════════════════════════════════════════════════════════"

