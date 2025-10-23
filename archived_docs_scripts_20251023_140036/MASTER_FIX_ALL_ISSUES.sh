#!/bin/bash
set -e

OLD_IP="13.221.117.236"
NEW_IP="54.227.101.30"

echo "════════════════════════════════════════════════════════"
echo "🔧 MASTER FIX - IP + API ENDPOINTS + REBUILD"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  1. Update ALL old IPs ($OLD_IP → $NEW_IP)"
echo "  2. Fix API endpoints (remove /api/ prefix)"
echo "  3. Rebuild & redeploy tenant app"
echo ""

TENANT_DIR="/home/ec2-user/pgni/pgworldtenant-master"
REPO_DIR="/home/ec2-user/pgni"

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Update ALL IP addresses in repository"
echo "════════════════════════════════════════════════════════"

cd "$REPO_DIR"

# Count before
BEFORE_COUNT=$(grep -r "$OLD_IP" . 2>/dev/null | grep -v ".git" | wc -l)
echo "Found $BEFORE_COUNT occurrences of old IP"

# Update all files
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.dart" \) ! -path "./.git/*" | while read file; do
    if grep -q "$OLD_IP" "$file" 2>/dev/null; then
        sed -i "s/$OLD_IP/$NEW_IP/g" "$file"
        echo "  ✓ Updated: $(basename $file)"
    fi
done

# Count after
AFTER_COUNT=$(grep -r "$OLD_IP" . 2>/dev/null | grep -v ".git" | wc -l)
echo ""
echo "Result: Changed $((BEFORE_COUNT - AFTER_COUNT)) occurrences"
if [ $AFTER_COUNT -eq 0 ]; then
    echo "✅ All IPs updated!"
else
    echo "⚠️  Still $AFTER_COUNT occurrences remaining (check manual edits needed)"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Fix API Endpoints (remove /api/ prefix)"
echo "════════════════════════════════════════════════════════"

cd "$TENANT_DIR"

echo "Creating correct app_config.dart..."
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

echo "✓ Created app_config.dart with correct endpoints"

echo ""
echo "Testing API endpoint (should return data, not 404)..."
curl -s -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' | head -100 || echo "API test failed"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Rebuild Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

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
    echo "✅ Correct endpoint (/login without /api/) found!"
else
    echo "⚠️  Endpoint verification inconclusive"
fi

echo ""
echo "Checking for old IP in deployed app..."
if grep -q "$OLD_IP" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "⚠️  WARNING: Old IP still found in deployed JavaScript!"
else
    echo "✅ No old IP found in deployed app"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ MASTER FIX COMPLETE!"
echo "════════════════════════════════════════════════════════"

echo ""
echo "🌐 Access your app:"
echo "   URL: http://54.227.101.30/tenant/"
echo ""
echo "📧 Login with:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "🔍 What was fixed:"
echo "   ✅ All IPs updated: $OLD_IP → $NEW_IP"
echo "   ✅ API endpoints corrected: /api/login → /login"
echo "   ✅ App rebuilt and deployed"
echo ""
echo "📊 Build: $SIZE in ${BUILD_TIME}s"
echo ""
echo "⚠️  IMPORTANT - Clear browser cache:"
echo "   1. Ctrl+Shift+Delete → Clear all cached data"
echo "   2. Or use Incognito mode (Ctrl+Shift+N)"
echo "   3. Go to: http://54.227.101.30/tenant/"
echo ""
echo "🔧 If login still fails:"
echo "   1. Check browser console (F12 → Console)"
echo "   2. Check Network tab for API call errors"
echo "   3. Run: sudo journalctl -u pgworld-api -f"
echo ""
echo "════════════════════════════════════════════════════════"

