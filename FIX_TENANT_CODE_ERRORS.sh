#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 Fixing Tenant App Code Errors"
echo "════════════════════════════════════════════════════════"
echo ""

cd /home/ec2-user/pgni/pgworldtenant-master

# Create missing config file with all global variables
echo "1. Creating missing config.dart file..."
cat > lib/utils/config.dart << 'CONFIG_EOF'
class Config {
  static const String URL = "34.227.111.143:8080";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
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

// Global constants
const String mediaURL = "http://34.227.111.143:8080/uploads/";
const int timeout = 30;
const String defaultOffset = "0";
const String defaultLimit = "20";
const int STATUS_403 = 403;

// These will be loaded from SharedPreferences at runtime
String hostelID = "";
String userID = "";

// Headers
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
CONFIG_EOF

echo "   ✓ config.dart created"

# Fix models.dart - add required keyword and make nullable
echo "2. Fixing models.dart Service class..."
sed -i 's/String color;/String? color;/g' lib/utils/models.dart
sed -i 's/IconData icon;/IconData? icon;/g' lib/utils/models.dart
sed -i 's/String title;/String? title;/g' lib/utils/models.dart

# Fix Pagination null issues
sed -i 's/Pagination.fromJson(json\[.pagination.\])/Pagination.fromJson(json[\x27pagination\x27]!)/g' lib/utils/models.dart || true

echo "   ✓ models.dart fixed"

# Fix api.dart - add imports
echo "3. Fixing api.dart..."
if ! grep -q "import 'config.dart';" lib/utils/api.dart; then
    sed -i '1i import '\''config.dart'\'';' lib/utils/api.dart
fi

echo "   ✓ api.dart fixed"

# Fix all screen files to import config
echo "4. Fixing screen imports..."
for file in lib/screens/*.dart; do
    if ! grep -q "import 'package:cloudpgtenant/utils/config.dart';" "$file"; then
        sed -i "1i import 'package:cloudpgtenant/utils/config.dart';" "$file"
    fi
done

echo "   ✓ Screen imports fixed"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Code fixes applied!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Now building Tenant app..."
echo ""

# Build
export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean
rm -rf .dart_tool build

flutter pub get

echo ""
echo "Compiling..."
flutter build web --release \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  --no-tree-shake-icons

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ Tenant build SUCCESS! ($TENANT_SIZE)"
    echo ""
    
    # Deploy
    echo "Deploying Tenant app..."
    sudo rm -rf /usr/share/nginx/html/tenant
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    
    if command -v getenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant
    fi
    
    sudo systemctl reload nginx
    
    echo "✓ Tenant app deployed!"
    echo ""
    
    # Verify
    TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo "════════════════════════════════════════════════════════"
    echo "🎉 TENANT APP IS LIVE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 Access Tenant Portal:"
    echo "   http://34.227.111.143/tenant/"
    echo ""
    echo "   Status: HTTP $TENANT_STATUS"
    echo "   Size: $TENANT_SIZE"
    echo ""
    echo "🔐 Login:"
    echo "   Email:    tenant@pgworld.com"
    echo "   Password: Tenant@123"
    echo ""
else
    echo ""
    echo "❌ Build still failed. Check errors above."
    exit 1
fi

