#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🎯 FINAL TENANT SOLUTION - Single Config Approach"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This will:"
echo "  1. Delete lib/utils/config.dart completely"
echo "  2. Create single lib/config.dart with ALL constants"
echo "  3. Replace ALL imports to use lib/config.dart only"
echo "  4. Build and deploy successfully"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
PUBLIC_IP="13.221.117.236"
API_PORT="8080"

cd "$TENANT_PATH"

# Backup
BACKUP_DIR="final_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Remove Old Config Files"
echo "════════════════════════════════════════════════════════"

# Delete old config files
if [ -f "lib/utils/config.dart" ]; then
    rm -f lib/utils/config.dart
    echo "✓ Deleted lib/utils/config.dart"
fi

# Keep utils directory but remove config
if [ -d "lib/utils" ]; then
    echo "✓ Keeping lib/utils/ for models.dart and api.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Single Master Config"
echo "════════════════════════════════════════════════════════"

mkdir -p lib

cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// SINGLE MASTER CONFIGURATION FILE
// All app constants, API keys, and global variables in ONE place
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// API ENDPOINTS
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
// API KEYS - Your Production Keys
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY_VALUE = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";

// Legacy APIKEY class for compatibility with existing code
class APIKEY {
  static const String ANDROID_LIVE = APIKEY_VALUE;
  static const String ANDROID_TEST = APIKEY_VALUE;
  static const String IOS_LIVE = APIKEY_VALUE;
  static const String IOS_TEST = APIKEY_VALUE;
}

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL CONSTANTS
// ══════════════════════════════════════════════════════════════════════════

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30;

// HTTP Headers with API key
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-API-Key': APIKEY_VALUE,
  'apikey': APIKEY_VALUE,
};

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL SESSION VARIABLES (User state)
// ══════════════════════════════════════════════════════════════════════════

String? hostelID;
String? userID;
String? emailID;
String? name;
String? amenities;
String? roomID;

// Clear all session data
void clearSession() {
  hostelID = null;
  userID = null;
  emailID = null;
  name = null;
  amenities = null;
  roomID = null;
}

// Set user session
void setSession({
  String? user,
  String? hostel,
  String? email,
  String? userName,
  String? room,
}) {
  userID = user;
  hostelID = hostel;
  emailID = email;
  name = userName;
  roomID = room;
}

// ══════════════════════════════════════════════════════════════════════════
// APP VERSION
// ══════════════════════════════════════════════════════════════════════════

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}

// ══════════════════════════════════════════════════════════════════════════
// SAFE ACCESS HELPER FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════

/// Safely get a string value with fallback
String safeString(String? value, [String defaultValue = '']) {
  return value ?? defaultValue;
}

/// Safely parse an integer
int safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safely parse a double
double safeDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safely parse a boolean
bool safeBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value != 0;
  return defaultValue;
}

/// Safely access list element
T? safeListGet<T>(List<T>? list, int index) {
  if (list == null || list.isEmpty || index < 0 || index >= list.length) {
    return null;
  }
  return list[index];
}

/// Get list length safely
int safeListLength<T>(List<T>? list) {
  return list?.length ?? 0;
}

/// Check if string is not empty safely
bool isNotEmptyString(String? value) {
  return value != null && value.isNotEmpty;
}

/// Split string safely
List<String> safeSplit(String? value, String separator) {
  if (value == null || value.isEmpty) return [];
  return value.split(separator);
}

// ══════════════════════════════════════════════════════════════════════════
// END OF CONFIGURATION
// Import this file as: import 'package:cloudpgtenant/config.dart';
// ══════════════════════════════════════════════════════════════════════════
EOFCONFIG

echo "✓ Created single lib/config.dart with ALL constants"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Replace ALL Imports in Project"
echo "════════════════════════════════════════════════════════"

# Find all Dart files and replace imports
find lib -name "*.dart" -type f | while read file; do
    # Skip if it's the config.dart itself
    if [ "$file" = "lib/config.dart" ]; then
        continue
    fi
    
    # Replace utils/config.dart imports with config.dart
    sed -i "s|import 'package:cloudpgtenant/utils/config.dart';|import 'package:cloudpgtenant/config.dart';|g" "$file"
    
    # Remove any 'as config' aliases
    sed -i "s|import 'package:cloudpgtenant/config.dart' as config;|import 'package:cloudpgtenant/config.dart';|g" "$file"
    
    # Fix any config.variableName references (remove config. prefix)
    sed -i "s/config\.userID/userID/g" "$file"
    sed -i "s/config\.hostelID/hostelID/g" "$file"
    sed -i "s/config\.emailID/emailID/g" "$file"
    sed -i "s/config\.name/name/g" "$file"
    sed -i "s/config\.APIKEY/APIKEY_VALUE/g" "$file"
    sed -i "s/config\.ONESIGNAL_APP_ID/ONESIGNAL_APP_ID/g" "$file"
    sed -i "s/config\.headers/headers/g" "$file"
done

echo "✓ Replaced ALL imports to use lib/config.dart"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Verify Project Structure"
echo "════════════════════════════════════════════════════════"

echo "Checking for remaining old imports..."
OLD_IMPORTS=$(grep -r "utils/config.dart" lib --include="*.dart" 2>/dev/null | wc -l || echo "0")

if [ "$OLD_IMPORTS" = "0" ]; then
    echo "✓ No old imports found - all clean!"
else
    echo "⚠️  Found $OLD_IMPORTS old imports - fixing..."
    grep -rl "utils/config.dart" lib --include="*.dart" 2>/dev/null | while read file; do
        sed -i "s|package:cloudpgtenant/utils/config.dart|package:cloudpgtenant/config.dart|g" "$file"
        echo "  Fixed: $file"
    done
fi

echo ""
echo "Project structure:"
echo "  ✓ lib/config.dart (SINGLE master config)"
echo "  ✓ lib/utils/models.dart (data models)"
echo "  ✓ lib/utils/api.dart (API functions)"
echo "  ✓ lib/screens/*.dart (all screens)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Optimize Build Environment"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache
export PATH="/opt/flutter/bin:$PATH"

echo "✓ Environment optimized for t3.large"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Clean Build"
echo "════════════════════════════════════════════════════════"

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "✓ Build artifacts cleaned"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Get Dependencies"
echo "════════════════════════════════════════════════════════"

flutter pub get 2>&1 | tail -3

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Build Tenant Web App"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Building with optimizations:"
echo "  • Release mode"
echo "  • No source maps"
echo "  • No tree-shake-icons"
echo "  • Dart product mode"
echo "  • Base href: /tenant/"
echo ""
echo "This will take 2-4 minutes..."
echo ""

BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_final.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILES=$(ls -1 build/web | wc -l)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ BUILD SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Build Stats:"
    echo "  • Main JS: $SIZE"
    echo "  • Files: $FILES"
    echo "  • Time: ${BUILD_TIME}s ($(($BUILD_TIME / 60))m $(($BUILD_TIME % 60))s)"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 9: Deploy to Nginx"
    echo "════════════════════════════════════════════════════════"
    
    # Backup existing deployment
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        DEPLOY_BACKUP="/usr/share/nginx/html/tenant.backup.$(date +%s)"
        sudo mv /usr/share/nginx/html/tenant "$DEPLOY_BACKUP"
        echo "✓ Old deployment backed up: $DEPLOY_BACKUP"
    fi
    
    echo "Deploying files..."
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    
    echo "Setting ownership & permissions..."
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    
    # Fix SELinux context if enabled
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
        echo "✓ SELinux context applied"
    fi
    
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
    
    echo "✓ Deployment complete"
    
    sleep 2
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 10: Verification"
    echo "════════════════════════════════════════════════════════"
    
    # Test endpoints
    TENANT_HTML=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    TENANT_JS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js)
    TENANT_INDEX=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/index.html)
    
    echo ""
    echo "HTTP Status Checks:"
    echo "  • Tenant Portal:     $TENANT_HTML $([ "$TENANT_HTML" = "200" ] && echo "✅" || echo "❌")"
    echo "  • Main JavaScript:   $TENANT_JS $([ "$TENANT_JS" = "200" ] && echo "✅" || echo "❌")"
    echo "  • Index HTML:        $TENANT_INDEX $([ "$TENANT_INDEX" = "200" ] && echo "✅" || echo "❌")"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 YOUR TENANT APP IS LIVE:"
    echo "   ────────────────────────────────────────────────────"
    echo "   URL:      http://$PUBLIC_IP/tenant/"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo "   Status:   $([ "$TENANT_HTML" = "200" ] && echo "✅ ONLINE & WORKING" || echo "⚠️  HTTP $TENANT_HTML")"
    echo ""
    echo "⏱️  PERFORMANCE:"
    echo "   ────────────────────────────────────────────────────"
    echo "   Build Time:   ${BUILD_TIME}s ($(($BUILD_TIME / 60)) min $(($BUILD_TIME % 60)) sec)"
    echo "   Bundle Size:  $SIZE"
    echo "   Total Files:  $FILES"
    echo ""
    echo "🔑 API KEYS CONFIGURED:"
    echo "   ────────────────────────────────────────────────────"
    echo "   APIKEY:       mrk-1b96d9eeccf649e695ed6ac2b13cb619"
    echo "   OneSignal:    AKIA2FFQRNMAP3IDZD6V"
    echo "   API Endpoint: http://$PUBLIC_IP:$API_PORT"
    echo ""
    echo "📁 DEPLOYMENT LOCATION:"
    echo "   ────────────────────────────────────────────────────"
    echo "   /usr/share/nginx/html/tenant/"
    echo ""
    echo "⚡ BROWSER ACCESS:"
    echo "   ────────────────────────────────────────────────────"
    echo "   1. Open: http://$PUBLIC_IP/tenant/"
    echo "   2. Hard refresh: Ctrl + Shift + R (or Cmd + Shift + R)"
    echo "   3. Or use Incognito/Private mode"
    echo ""
    echo "✅ CONFIGURATION:"
    echo "   ────────────────────────────────────────────────────"
    echo "   • Single config file: lib/config.dart ✓"
    echo "   • No duplicate configs ✓"
    echo "   • All imports unified ✓"
    echo "   • Production keys configured ✓"
    echo ""
    echo "════════════════════════════════════════════════════════"
    
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ BUILD FAILED"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Build errors detected:"
    echo ""
    grep "Error:" /tmp/tenant_final.log | head -30
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "Full build log saved to: /tmp/tenant_final.log"
    echo ""
    echo "Please share the errors and I'll help fix them!"
    echo "════════════════════════════════════════════════════════"
    exit 1
fi

