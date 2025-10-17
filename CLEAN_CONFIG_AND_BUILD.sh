#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🧹 CLEAN CONFIG & BUILD TENANT APP"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This will:"
echo "  1. Remove duplicate config files"
echo "  2. Create single lib/config.dart with all constants"
echo "  3. Update all imports to use lib/config.dart"
echo "  4. Fix null-safety issues"
echo "  5. Build and deploy successfully"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Clean Up Duplicate Config Files"
echo "════════════════════════════════════════════════════════"

# Backup everything first
BACKUP_DIR="config_cleanup_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

# Remove duplicate config files
if [ -f "lib/utils/config.dart" ]; then
    rm -f lib/utils/config.dart
    echo "✓ Removed lib/utils/config.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Single Master Config File"
echo "════════════════════════════════════════════════════════"

# Create the ONE AND ONLY config.dart in lib/
cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// MASTER CONFIGURATION FILE - lib/config.dart
// Single source of truth for all app constants and global variables
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// API CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

class API {
  static const String URL = "13.221.117.236:8080";
  
  // API Endpoints
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
// GLOBAL CONSTANTS
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY = "YOUR_API_KEY_HERE";
const String ONESIGNAL_APP_ID = "YOUR_ONESIGNAL_APP_ID_HERE";
const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30; // timeout in seconds

// HTTP Headers
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-API-Key': APIKEY,
};

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL USER SESSION VARIABLES (Mutable)
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
// EXPORT - Import this file as: import 'package:cloudpgtenant/config.dart';
// ══════════════════════════════════════════════════════════════════════════
EOFCONFIG

echo "✓ Created master lib/config.dart"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Update All Screen Imports"
echo "════════════════════════════════════════════════════════"

# Fix all imports across the project
find lib -name "*.dart" -type f | while read file; do
    # Remove old imports
    sed -i "/import.*utils\/config.dart/d" "$file"
    sed -i "/import.*config.dart.*as config/d" "$file"
    
    # Add correct import if file uses config (check if it references config variables)
    if grep -q -E "(userID|hostelID|emailID|name|APIKEY|ONESIGNAL_APP_ID|headers|timeout|API\.|safeString|safeInt)" "$file"; then
        # Add import at the top if not already present
        if ! grep -q "import 'package:cloudpgtenant/config.dart';" "$file"; then
            sed -i "1i import 'package:cloudpgtenant/config.dart';" "$file"
        fi
    fi
done

echo "✓ Updated all imports to use lib/config.dart"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Fix Null Safety Issues in Screens"
echo "════════════════════════════════════════════════════════"

# Create a comprehensive sed script for null safety fixes
cat > /tmp/null_safety_fixes.sed << 'EOFSED'
# Fix list length access
s/users\.users\.length/safeListLength(users.users)/g
s/bills\.bills\.length/safeListLength(bills.bills)/g
s/issues\.issues\.length/safeListLength(issues.issues)/g
s/notices\.notices\.length/safeListLength(notices.notices)/g
s/rooms\.rooms\.length/safeListLength(rooms.rooms)/g
s/hostels\.hostels\.length/safeListLength(hostels.hostels)/g

# Fix list element access
s/users\.users\[0\]/safeListGet(users.users, 0)/g
s/bills\.bills\[0\]/safeListGet(bills.bills, 0)/g

# Fix string isNotEmpty checks
s/\.document\.isNotEmpty/document != null \&\& document!.isNotEmpty/g
s/widget\.user\.document\.isNotEmpty/isNotEmptyString(widget.user.document)/g

# Fix string split calls
s/\.document\.split/document?.split/g
s/widget\.user\.document\.split/safeSplit(widget.user.document, /g

# Fix nullable property access
s/currentUser\.document/currentUser.document ?? ''/g
s/currentRoom\.amenities/currentRoom.amenities ?? ''/g
s/users\.meta\.status/users.meta?.status ?? 0/g
s/users\.meta\.message/users.meta?.message ?? ''/g

# Fix forEach on nullable lists
s/hostels\.hostels\.forEach/hostels.hostels?.forEach ?? () {}/g
s/users\.users\.forEach/users.users?.forEach ?? () {}/g
EOFSED

# Apply fixes to all screen files
for file in lib/screens/*.dart; do
    if [ -f "$file" ]; then
        sed -i -f /tmp/null_safety_fixes.sed "$file"
        echo "✓ Fixed $(basename $file)"
    fi
done

# Fix main.dart specifically
if [ -f "lib/main.dart" ]; then
    sed -i -f /tmp/null_safety_fixes.sed lib/main.dart
    echo "✓ Fixed main.dart"
fi

rm /tmp/null_safety_fixes.sed

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Update models.dart"
echo "════════════════════════════════════════════════════════"

# Ensure models.dart imports config and uses safe helpers
if [ -f "lib/utils/models.dart" ]; then
    # Add import at the top if not present
    if ! grep -q "import 'package:cloudpgtenant/config.dart';" lib/utils/models.dart; then
        sed -i "1i import 'package:cloudpgtenant/config.dart';" lib/utils/models.dart
        echo "✓ Added config import to models.dart"
    fi
    
    # Replace all string conversions with safeString helper
    sed -i "s/json\['[^']*'\]\.toString()/safeString(json['\0'])/g" lib/utils/models.dart
    sed -i "s/?\.toString() ?? ''/), '')/g" lib/utils/models.dart
    
    echo "✓ Updated models.dart to use safe helpers"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Update api.dart"
echo "════════════════════════════════════════════════════════"

if [ -f "lib/utils/api.dart" ]; then
    # Add import if not present
    if ! grep -q "import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart; then
        sed -i "1i import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart
    fi
    
    # Remove any standalone variable declarations that conflict with config
    sed -i "/^String? userID/d" lib/utils/api.dart
    sed -i "/^String? hostelID/d" lib/utils/api.dart
    sed -i "/^Map<String, String> headers/d" lib/utils/api.dart
    sed -i "/^const int timeout/d" lib/utils/api.dart
    
    echo "✓ Updated api.dart to use lib/config.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Clean Build"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo "Cleaning build artifacts..."
flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "✓ Clean complete"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Get Dependencies"
echo "════════════════════════════════════════════════════════"

flutter pub get 2>&1 | tail -5

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 9: Build Tenant Web App"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Building with:"
echo "  • Release mode"
echo "  • No source maps"
echo "  • No tree-shake-icons"
echo "  • Dart product mode"
echo "  • Base href: /tenant/"
echo ""

BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_clean_build.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILE_COUNT=$(ls -1 build/web | wc -l)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ BUILD SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Build Stats:"
    echo "  • Size: $SIZE"
    echo "  • Files: $FILE_COUNT"
    echo "  • Time: ${BUILD_TIME}s"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 10: Deploy to Nginx"
    echo "════════════════════════════════════════════════════════"
    
    # Backup existing deployment
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        DEPLOY_BACKUP="/usr/share/nginx/html/tenant.backup.$(date +%s)"
        sudo mv /usr/share/nginx/html/tenant "$DEPLOY_BACKUP"
        echo "✓ Old deployment backed up to $DEPLOY_BACKUP"
    fi
    
    echo "Deploying to Nginx..."
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    
    echo "Setting permissions..."
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
    
    sleep 2
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 11: Verification"
    echo "════════════════════════════════════════════════════════"
    
    # Test URLs
    TENANT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    TENANT_JS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js)
    
    echo ""
    echo "HTTP Status Check:"
    echo "  • Tenant Portal: $TENANT_HTTP"
    echo "  • Main JS File:  $TENANT_JS"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT COMPLETE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 TENANT WEB APP:"
    echo "   ───────────────────────────────────────────────────"
    echo "   URL:      http://13.221.117.236/tenant/"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo "   Status:   $([ "$TENANT_HTTP" = "200" ] && echo "✅ ONLINE" || echo "⚠️  HTTP $TENANT_HTTP")"
    echo ""
    echo "⏱️  PERFORMANCE:"
    echo "   ───────────────────────────────────────────────────"
    echo "   Build Time: ${BUILD_TIME}s"
    echo "   Bundle Size: $SIZE"
    echo "   Files: $FILE_COUNT"
    echo ""
    echo "⚡ BROWSER TIPS:"
    echo "   ───────────────────────────────────────────────────"
    echo "   • Hard refresh: Ctrl + Shift + R (Windows/Linux)"
    echo "   • Hard refresh: Cmd + Shift + R (Mac)"
    echo "   • Or use Incognito/Private browsing mode"
    echo ""
    echo "📁 DEPLOYMENT LOCATION:"
    echo "   /usr/share/nginx/html/tenant/"
    echo ""
    echo "════════════════════════════════════════════════════════"
    
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "❌ BUILD FAILED"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Compilation errors detected:"
    echo ""
    grep -A 2 "Error:" /tmp/tenant_clean_build.log | head -30
    echo ""
    echo "Full build log: /tmp/tenant_clean_build.log"
    echo ""
    echo "Common issues:"
    echo "  • Check that all screen files import lib/config.dart"
    echo "  • Verify no conflicting variable declarations"
    echo "  • Ensure all nullable properties use safe access (?. or ??)"
    echo ""
    exit 1
fi

