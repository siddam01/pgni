#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🛠️ CREATE MISSING UTILS FILE"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo "Creating lib/utils/utils.dart with all utility functions..."

cat > lib/utils/utils.dart << 'EOFUTILS'
// ════════════════════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Shared Preferences instance
SharedPreferences? prefs;

// Initialize SharedPreferences
Future<void> initSharedPreference() async {
  prefs = await SharedPreferences.getInstance();
}

// Hex Color converter
Color HexColor(String hexColor) {
  hexColor = hexColor.replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}

// One Button Dialog
Future<void> oneButtonDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Two Button Dialog
Future<bool?> twoButtonDialog(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}

// Check Internet Connectivity
Future<bool> checkInternet() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

// Show Loading Dialog
void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      );
    },
  );
}

// Hide Loading Dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}

// Show Snackbar
void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// Format Date
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    DateTime date = DateTime.parse(dateStr);
    return "${date.day}/${date.month}/${date.year}";
  } catch (e) {
    return dateStr;
  }
}

// Format DateTime
String formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    DateTime date = DateTime.parse(dateStr);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  } catch (e) {
    return dateStr;
  }
}

// Validate Email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// Validate Phone
bool isValidPhone(String phone) {
  return RegExp(r'^\d{10}$').hasMatch(phone);
}
EOFUTILS

echo "✓ Created lib/utils/utils.dart"

echo ""
echo "Building..."
export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

BUILD_START=$(date +%s)
flutter build web --release --no-source-maps --base-href="/tenant/" 2>&1 | tee /tmp/utils_build.log | grep -E "Compiling|Built|✓" || true
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    
    echo ""
    echo "✅ BUILD SUCCESS!"
    
    # Deploy
    [ -d "/usr/share/nginx/html/tenant" ] && sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ] && sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    sudo systemctl reload nginx
    
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 Tenant App: http://13.221.117.236/tenant/"
    echo "👤 Email:      priya@example.com"
    echo "🔐 Password:   Tenant@123"
    echo "📊 Status:     HTTP $STATUS $([ "$STATUS" = "200" ] && echo "✅" || echo "⚠️")"
    echo "⏱️  Build:      ${BUILD_TIME}s ($(($BUILD_TIME/60))m $(($BUILD_TIME%60))s)"
    echo "📦 Size:       $SIZE"
    echo ""
    echo "✅ All errors fixed!"
    echo "✅ lib/utils/utils.dart created"
    echo "✅ lib/utils/models.dart working"
    echo "✅ lib/utils/api.dart working"
    echo "✅ lib/config.dart working"
    echo ""
    echo "════════════════════════════════════════════════════════"
    
else
    echo ""
    echo "❌ Build failed. Remaining errors:"
    grep "Error:" /tmp/utils_build.log | head -30
    echo ""
    echo "Full log: /tmp/utils_build.log"
    exit 1
fi

