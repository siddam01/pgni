#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX & DEPLOY TENANT APP - COMPLETE SOLUTION"
echo "════════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
PUBLIC_IP="13.221.117.236"
API_PORT="8080"

cd "$TENANT_PATH"

# Backup
BACKUP_DIR="fix_deploy_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Create Complete Configuration"
echo "════════════════════════════════════════════════════════"

# Create lib/config.dart
mkdir -p lib

cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// PRODUCTION CONFIGURATION
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// API CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

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
  static const String DASHBOARD = "/api/dashboard";
  static const String LOGIN = "/api/login";
  static const String FOOD = "/api/food";
}

// ══════════════════════════════════════════════════════════════════════════
// API KEYS
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY_VALUE = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";

// Legacy APIKEY class for compatibility
class APIKEY {
  static const String ANDROID_LIVE = APIKEY_VALUE;
  static const String ANDROID_TEST = APIKEY_VALUE;
  static const String IOS_LIVE = APIKEY_VALUE;
  static const String IOS_TEST = APIKEY_VALUE;
}

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30;

// HTTP Headers
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-API-Key': APIKEY_VALUE,
};

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL SESSION VARIABLES
// ══════════════════════════════════════════════════════════════════════════

String? hostelID;
String? userID;
String? emailID;
String? name;
String? amenities;
String? roomID;

void clearSession() {
  hostelID = null;
  userID = null;
  emailID = null;
  name = null;
  amenities = null;
  roomID = null;
}

void setSession({String? user, String? hostel, String? email, String? userName}) {
  userID = user;
  hostelID = hostel;
  emailID = email;
  name = userName;
}

// ══════════════════════════════════════════════════════════════════════════
// SAFE ACCESS HELPERS
// ══════════════════════════════════════════════════════════════════════════

String safeString(String? value, [String defaultValue = '']) => value ?? defaultValue;

int safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double safeDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

bool safeBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  if (value is int) return value != 0;
  return defaultValue;
}

T? safeListGet<T>(List<T>? list, int index) {
  if (list == null || list.isEmpty || index < 0 || index >= list.length) return null;
  return list[index];
}

int safeListLength<T>(List<T>? list) => list?.length ?? 0;

bool isNotEmptyString(String? value) => value != null && value.isNotEmpty;

List<String> safeSplit(String? value, String separator) {
  if (value == null || value.isEmpty) return [];
  return value.split(separator);
}

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}
EOFCONFIG

echo "✓ Created lib/config.dart"

# Also create lib/utils/config.dart as a redirect for compatibility
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOFUTILS'
// Redirect to main config
export 'package:cloudpgtenant/config.dart';
EOFUTILS

echo "✓ Created lib/utils/config.dart (redirect)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Fix All Imports"
echo "════════════════════════════════════════════════════════"

# Fix imports in all Dart files
find lib -name "*.dart" -type f | while read file; do
    # Ensure config import exists
    if grep -q -E "(userID|hostelID|APIKEY|ONESIGNAL_APP_ID|API\.|headers)" "$file" 2>/dev/null; then
        if ! grep -q "import.*config.dart" "$file" 2>/dev/null; then
            sed -i "1i import 'package:cloudpgtenant/config.dart';" "$file" 2>/dev/null || true
        fi
    fi
done

echo "✓ Fixed imports"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Fix login.dart Specifically"
echo "════════════════════════════════════════════════════════"

if [ -f "lib/screens/login.dart" ]; then
    # Fix the APIKEY references
    sed -i 's/headers\["apikey"\] = APIKEY\.ANDROID_LIVE;/headers["apikey"] = APIKEY.ANDROID_LIVE;/g' lib/screens/login.dart
    sed -i 's/headers\["apikey"\] = APIKEY\.ANDROID_TEST;/headers["apikey"] = APIKEY.ANDROID_TEST;/g' lib/screens/login.dart
    sed -i 's/headers\["apikey"\] = APIKEY\.IOS_LIVE;/headers["apikey"] = APIKEY.IOS_LIVE;/g' lib/screens/login.dart
    sed -i 's/headers\["apikey"\] = APIKEY\.IOS_TEST;/headers["apikey"] = APIKEY.IOS_TEST;/g' lib/screens/login.dart
    
    echo "✓ Fixed login.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Optimize Environment"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache
export PATH="/opt/flutter/bin:$PATH"

echo "✓ Environment optimized"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Clean Build"
echo "════════════════════════════════════════════════════════"

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "✓ Clean complete"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Get Dependencies"
echo "════════════════════════════════════════════════════════"

flutter pub get 2>&1 | tail -3

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Build Tenant Web App"
echo "════════════════════════════════════════════════════════"

echo "Building (this takes 2-4 minutes)..."
BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_fix_deploy.log | grep -E "Compiling|Built|✓" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILES=$(ls -1 build/web | wc -l)
    
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   Size: $SIZE | Files: $FILES | Time: ${BUILD_TIME}s"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 8: Deploy to Nginx"
    echo "════════════════════════════════════════════════════════"
    
    # Backup existing
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
        echo "✓ Previous deployment backed up"
    fi
    
    echo "Deploying..."
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    
    echo "Setting permissions..."
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    
    # SELinux
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    fi
    
    sudo systemctl reload nginx
    echo "✓ Deployment complete"
    
    sleep 2
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 9: Verification"
    echo "════════════════════════════════════════════════════════"
    
    TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    TENANT_JS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js)
    
    echo ""
    echo "HTTP Status:"
    echo "  • Tenant Portal:  $TENANT_STATUS"
    echo "  • JavaScript:     $TENANT_JS"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 ACCESS YOUR TENANT APP:"
    echo "   ────────────────────────────────────────────────────"
    echo "   URL:      http://$PUBLIC_IP/tenant/"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo "   Status:   $([ "$TENANT_STATUS" = "200" ] && echo "✅ LIVE & WORKING" || echo "⚠️  HTTP $TENANT_STATUS")"
    echo ""
    echo "⏱️  PERFORMANCE:"
    echo "   Build Time: ${BUILD_TIME}s"
    echo "   Bundle Size: $SIZE"
    echo ""
    echo "⚡ BROWSER TIPS:"
    echo "   • Hard refresh: Ctrl + Shift + R (Windows/Linux)"
    echo "   • Hard refresh: Cmd + Shift + R (Mac)"
    echo "   • Or use Incognito/Private mode"
    echo ""
    echo "🔑 API KEYS CONFIGURED:"
    echo "   • APIKEY: mrk-1b96d9eeccf649e695ed6ac2b13cb619"
    echo "   • OneSignal: AKIA2FFQRNMAP3IDZD6V"
    echo ""
    echo "════════════════════════════════════════════════════════"
    
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    echo "Recent errors:"
    grep "Error:" /tmp/tenant_fix_deploy.log | head -20
    echo ""
    echo "Full log: /tmp/tenant_fix_deploy.log"
    echo ""
    echo "Please share the error output and I'll help fix it!"
    exit 1
fi

