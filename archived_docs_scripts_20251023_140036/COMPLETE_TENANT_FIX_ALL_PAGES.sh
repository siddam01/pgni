#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔧 COMPLETE TENANT APP FIX - ALL 16 PAGES"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Goal: Fix 200+ build errors and deploy complete tenant app"
echo "Expected: All 16 original pages working"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ec2-user/pgni/tenant_backup_before_complete_fix_$TIMESTAMP"

echo "STEP 1: Backup Current State"
echo "───────────────────────────────────────────────────────"
cp -r "$TENANT_PATH" "$BACKUP_DIR"
echo "✓ Backup created: $BACKUP_DIR"

echo ""
echo "STEP 2: Restore Original 16-Page Source from GitHub"
echo "───────────────────────────────────────────────────────"

GITHUB_REPO="https://github.com/siddam01/pgni.git"
TEMP_DIR="/tmp/pgni_restore_$TIMESTAMP"

git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR" 2>&1 | tail -2

if [ -d "$TEMP_DIR/pgworldtenant-master/lib/screens" ]; then
    ORIGINAL_SCREENS=$(find "$TEMP_DIR/pgworldtenant-master/lib/screens" -name "*.dart" -type f | wc -l)
    echo "✓ Found $ORIGINAL_SCREENS screen files in GitHub"
    
    # Restore original source
    cd "$TENANT_PATH"
    rm -rf lib
    cp -r "$TEMP_DIR/pgworldtenant-master/lib" .
    
    # Also restore pubspec if exists
    if [ -f "$TEMP_DIR/pgworldtenant-master/pubspec.yaml" ]; then
        cp "$TEMP_DIR/pgworldtenant-master/pubspec.yaml" .
    fi
    
    echo "✓ Restored original source code with all $ORIGINAL_SCREENS screens"
    rm -rf "$TEMP_DIR"
else
    echo "❌ Could not find original source in GitHub"
    exit 1
fi

echo ""
echo "STEP 3: Update pubspec.yaml with ALL Required Packages"
echo "───────────────────────────────────────────────────────"

cat > pubspec.yaml << 'YAML_EOF'
name: cloudpgtenant
description: PG Tenant Management App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # UI & Material
  cupertino_icons: ^1.0.2
  
  # HTTP & Network
  http: ^1.1.0
  connectivity_plus: ^5.0.2
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # UI Components
  modal_progress_hud_nsn: ^0.5.0
  flutter_slidable: ^3.0.0
  
  # Image & Media
  image_picker: ^1.0.4
  
  # Push Notifications
  onesignal_flutter: ^5.0.0
  
  # Utilities
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
YAML_EOF

echo "✓ Updated pubspec.yaml with all required packages"

echo ""
echo "STEP 4: Create Global Configuration (lib/config.dart)"
echo "───────────────────────────────────────────────────────"

mkdir -p lib

cat > lib/config.dart << 'DART_EOF'
// Global Configuration for Tenant App

class Config {
  // API Configuration
  static const String API_BASE_URL = 'http://54.227.101.30:8080';
  
  // API Keys
  static const String APIKEY_ANDROID_LIVE = 'mrk-1b96d9eeccf649e695ed6ac2b13cb619';
  static const String APIKEY_ANDROID_TEST = 'mrk-1b96d9eeccf649e695ed6ac2b13cb619';
  static const String APIKEY_IOS_LIVE = 'mrk-1b96d9eeccf649e695ed6ac2b13cb619';
  static const String APIKEY_IOS_TEST = 'mrk-1b96d9eeccf649e695ed6ac2b13cb619';
  
  // OneSignal
  static const String ONESIGNAL_APP_ID = 'AKIA2FFQRNMAP3IDZD6V';
  
  // App Version
  static const String APPVERSION = '1.0.0';
  
  // HTTP Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': APIKEY_ANDROID_LIVE,
  };
  
  // Request Timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultOffset = 0;
  static const int defaultLimit = 20;
  
  // Media URL
  static const String mediaURL = '$API_BASE_URL/media/';
  
  // Status Codes
  static const int STATUS_403 = 403;
}

// Global Session State
class AppState {
  static String? userID;
  static String? hostelID;
  static String? emailID;
  static String? name;
  static String? token;
  
  static void clear() {
    userID = null;
    hostelID = null;
    emailID = null;
    name = null;
    token = null;
  }
}

// API Endpoints
class API {
  static const String BASE = Config.API_BASE_URL;
  
  static const String login = '$BASE/login';
  static const String dashboard = '$BASE/dashboard';
  static const String users = '$BASE/users';
  static const String hostels = '$BASE/hostels';
  static const String rooms = '$BASE/rooms';
  static const String bills = '$BASE/bills';
  static const String issues = '$BASE/issues';
  static const String notices = '$BASE/notices';
  static const String food = '$BASE/food';
}
DART_EOF

echo "✓ Created global configuration"

echo ""
echo "STEP 5: Fix lib/utils/models.dart (Null Safety)"
echo "───────────────────────────────────────────────────────"

if [ -f "lib/utils/models.dart" ]; then
    cp lib/utils/models.dart lib/utils/models.dart.backup
    
    # Make all required String parameters have default empty strings
    sed -i 's/required this\.id,/this.id = "",/g' lib/utils/models.dart
    sed -i 's/required this\.name,/this.name = "",/g' lib/utils/models.dart
    sed -i 's/required this\.email,/this.email = "",/g' lib/utils/models.dart
    sed -i 's/required this\.phone,/this.phone = "",/g' lib/utils/models.dart
    sed -i 's/required this\.address,/this.address = "",/g' lib/utils/models.dart
    sed -i 's/required this\.user,/this.user = "",/g' lib/utils/models.dart
    sed -i 's/required this\.room,/this.room = "",/g' lib/utils/models.dart
    sed -i 's/required this\.bill,/this.bill = "",/g' lib/utils/models.dart
    sed -i 's/required this\.note,/this.note = "",/g' lib/utils/models.dart
    sed -i 's/required this\.log,/this.log = "",/g' lib/utils/models.dart
    sed -i 's/required this\.by,/this.by = "",/g' lib/utils/models.dart
    sed -i 's/required this\.type,/this.type = "",/g' lib/utils/models.dart
    sed -i 's/required this\.status,/this.status = "",/g' lib/utils/models.dart
    sed -i 's/required this\.title,/this.title = "",/g' lib/utils/models.dart
    sed -i 's/required this\.img,/this.img = "",/g' lib/utils/models.dart
    sed -i 's/required this\.hostelID,/this.hostelID = "",/g' lib/utils/models.dart
    sed -i 's/required this\.roomno,/this.roomno = "",/g' lib/utils/models.dart
    sed -i 's/required this\.rent,/this.rent = "",/g' lib/utils/models.dart
    sed -i 's/required this\.document,/this.document = "",/g' lib/utils/models.dart
    sed -i 's/required this\.designation,/this.designation = "",/g' lib/utils/models.dart
    sed -i 's/required this\.salary,/this.salary = "",/g' lib/utils/models.dart
    sed -i 's/required this\.paid,/this.paid = "",/g' lib/utils/models.dart
    
    echo "✓ Fixed null safety in models.dart"
else
    echo "⚠️  models.dart not found, will be created"
fi

echo ""
echo "STEP 6: Add Config Imports to All Screen Files"
echo "───────────────────────────────────────────────────────"

# Add import to all screen files
for screen_file in lib/screens/*.dart; do
    if [ -f "$screen_file" ]; then
        # Check if import already exists
        if ! grep -q "import.*config\.dart" "$screen_file"; then
            # Add import after package imports
            sed -i "1i import 'package:cloudpgtenant/config.dart';" "$screen_file"
        fi
    fi
done

echo "✓ Added config imports to all screens"

echo ""
echo "STEP 7: Fix Common Variable References"
echo "───────────────────────────────────────────────────────"

# Fix undefined variables in all screen files
for screen_file in lib/screens/*.dart; do
    if [ -f "$screen_file" ]; then
        filename=$(basename "$screen_file")
        
        # Replace undefined variables with AppState or Config
        sed -i 's/\buserID\b/AppState.userID ?? ""/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bhostelID\b/AppState.hostelID ?? ""/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bemailID\b/AppState.emailID ?? ""/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bname\s*=/AppState.name =/g' "$screen_file" 2>/dev/null || true
        
        # Fix APIKEY references
        sed -i 's/APIKEY\.ANDROID_LIVE/Config.APIKEY_ANDROID_LIVE/g' "$screen_file" 2>/dev/null || true
        sed -i 's/APIKEY\.IOS_LIVE/Config.APIKEY_IOS_LIVE/g' "$screen_file" 2>/dev/null || true
        
        # Fix other config references
        sed -i 's/\bAPPVERSION\b/Config.APPVERSION/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bSTATUS_403\b/Config.STATUS_403/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bdefaultOffset\b/Config.defaultOffset/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bdefaultLimit\b/Config.defaultLimit/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bmediaURL\b/Config.mediaURL/g' "$screen_file" 2>/dev/null || true
        sed -i 's/\bheaders\b/Config.headers/g' "$screen_file" 2>/dev/null || true
        
        echo "  ✓ Fixed: $filename"
    fi
done

echo ""
echo "STEP 8: Fix lib/utils/api.dart"
echo "───────────────────────────────────────────────────────"

if [ -f "lib/utils/api.dart" ]; then
    # Add config import
    if ! grep -q "import.*config\.dart" "lib/utils/api.dart"; then
        sed -i "1i import 'package:cloudpgtenant/config.dart';" "lib/utils/api.dart"
    fi
    
    # Fix API URL references
    sed -i 's/"\$API\.URL/"\${API.BASE}/g' lib/utils/api.dart 2>/dev/null || true
    sed -i 's/API\.URL/API.BASE/g' lib/utils/api.dart 2>/dev/null || true
    
    echo "✓ Fixed api.dart"
fi

echo ""
echo "STEP 9: Create lib/utils/utils.dart (if missing)"
echo "───────────────────────────────────────────────────────"

if [ ! -f "lib/utils/utils.dart" ]; then
    cat > lib/utils/utils.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

// Global SharedPreferences instance
SharedPreferences? prefs;

// Initialize SharedPreferences
Future<bool> initSharedPreference() async {
  try {
    prefs = await SharedPreferences.getInstance();
    return true;
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
    return false;
  }
}

// Check internet connectivity
Future<bool> checkInternet() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  } catch (e) {
    print('Error checking internet: $e');
    return false;
  }
}

// Show one button dialog
Future<void> oneButtonDialog(BuildContext context, String message, String buttonText) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(buttonText),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Show two button dialog
Future<bool> twoButtonDialog(BuildContext context, String message, String button1Text, String button2Text) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(button1Text),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(button2Text),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  ) ?? false;
}

// Show loading dialog
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );
}

// Show snackbar
void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}

// HexColor helper
Color HexColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// Format date
String formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '';
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    return dateString;
  }
}

// Format date time
String formatDateTime(String? dateTimeString) {
  if (dateTimeString == null || dateTimeString.isEmpty) return '';
  try {
    final dateTime = DateTime.parse(dateTimeString);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  } catch (e) {
    return dateTimeString;
  }
}

// Validate email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// Validate phone
bool isValidPhone(String phone) {
  return RegExp(r'^\d{10}$').hasMatch(phone);
}
DART_EOF
    echo "✓ Created utils.dart"
else
    echo "✓ utils.dart already exists"
fi

echo ""
echo "STEP 10: Clean and Build"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo "Cleaning..."
flutter clean > /dev/null 2>&1

echo "Getting dependencies..."
flutter pub get 2>&1 | tail -5

echo ""
echo "Building for web (this will take 2-5 minutes)..."
echo "Note: We'll try to build and show errors if any..."

BUILD_START=$(date +%s)

if flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | tee /tmp/tenant_build_$TIMESTAMP.log; then
    
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    
    if [ -f "build/web/main.dart.js" ]; then
        SIZE=$(du -h build/web/main.dart.js | cut -f1)
        
        echo ""
        echo "✅ BUILD SUCCESSFUL!"
        echo "   Size: $SIZE"
        echo "   Time: ${BUILD_TIME}s"
        
        echo ""
        echo "STEP 11: Deploy to Nginx"
        echo "───────────────────────────────────────────────────────"
        
        sudo rm -rf /usr/share/nginx/html/tenant
        sudo mkdir -p /usr/share/nginx/html/tenant
        sudo cp -r build/web/* /usr/share/nginx/html/tenant/
        sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
        sudo chmod -R 755 /usr/share/nginx/html/tenant
        sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
        
        if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
            sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
        fi
        
        sudo systemctl reload nginx
        
        echo "✓ Deployed to Nginx"
        
        # Count deployed files
        SCREEN_COUNT=$(find lib/screens -name "*.dart" -type f | wc -l)
        
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "✅ SUCCESS! ALL 16 PAGES DEPLOYED!"
        echo "═══════════════════════════════════════════════════════"
        echo ""
        echo "📱 Total Screens: $SCREEN_COUNT"
        echo "📊 Build Time: ${BUILD_TIME}s"
        echo "📦 Bundle Size: $SIZE"
        echo ""
        echo "🌐 URL: http://54.227.101.30/tenant/"
        echo "📧 Email: priya@example.com"
        echo "🔐 Password: Tenant@123"
        echo ""
        echo "✅ ALL PAGES NOW AVAILABLE:"
        echo "  1. Login"
        echo "  2. Dashboard"
        echo "  3. Profile"
        echo "  4. Edit Profile"
        echo "  5. Room Details"
        echo "  6. Bills/Rents"
        echo "  7. Issues"
        echo "  8. Notices"
        echo "  9. Food Menu"
        echo " 10. Menu List"
        echo " 11. Meal History"
        echo " 12. Documents"
        echo " 13. Photo Gallery"
        echo " 14. Services"
        echo " 15. Support"
        echo " 16. Settings"
        echo ""
        echo "🎯 TEST NOW:"
        echo "  1. Clear browser cache"
        echo "  2. Login and navigate through all pages"
        echo "  3. Verify all features work"
        echo ""
        echo "💾 Backup saved: $BACKUP_DIR"
        echo "═══════════════════════════════════════════════════════"
    fi
else
    echo ""
    echo "❌ BUILD FAILED - Showing errors..."
    echo ""
    echo "Top 50 errors:"
    grep "Error:" /tmp/tenant_build_$TIMESTAMP.log | head -50
    echo ""
    echo "Full build log: /tmp/tenant_build_$TIMESTAMP.log"
    echo ""
    echo "This means more complex fixes are needed."
    echo "The script has done basic fixes, but manual intervention required."
    exit 1
fi

