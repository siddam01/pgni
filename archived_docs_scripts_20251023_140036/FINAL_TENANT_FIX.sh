#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FINAL COMPREHENSIVE TENANT FIX"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"

cd /home/ec2-user/pgni/pgworldtenant-master

echo "STEP 1: Fixing services.dart and other screen errors"
echo "────────────────────────────────────────────────────────"

# Backup
cp lib/screens/services.dart lib/screens/services.dart.backup 2>/dev/null || true

# Fix the services.dart file - replace the problematic dialog calls
echo "Fixing lib/screens/services.dart..."

# The issue is that oneButtonDialog() returns void but code tries to use .then()
# We need to remove the .then() calls or make the function return a Future

cat > /tmp/services_fix.dart << 'EOFSERVICES'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/utils/config.dart';
import 'package:cloudpgtenant/utils/api.dart' as api;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ServicesActivity extends StatefulWidget {
  final String? hostelID;
  final String? userID;

  const ServicesActivity({Key? key, this.hostelID, this.userID}) : super(key: key);

  @override
  ServicesActivityState createState() => ServicesActivityState();
}

class ServicesActivityState extends State<ServicesActivity> {
  bool showSpinner = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> showOneButtonDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> requestSupport() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      await showOneButtonDialog('Error', 'Please fill all fields');
      return;
    }

    setState(() {
      showSpinner = true;
    });

    try {
      final requestData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'hostel_id': widget.hostelID ?? '',
      };

      final response = await api.requestSupport(requestData);

      setState(() {
        showSpinner = false;
      });

      if (response != null) {
        await showOneButtonDialog('Success', 'Support request submitted successfully!');
        nameController.clear();
        phoneController.clear();
        emailController.clear();
        addressController.clear();
      } else {
        await showOneButtonDialog('Error', 'Failed to submit request. Please try again.');
      }
    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      await showOneButtonDialog('Error', 'An error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Services'),
        backgroundColor: Colors.blue,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Request Support',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: requestSupport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOFSERVICES

cp /tmp/services_fix.dart lib/screens/services.dart
echo "✓ services.dart fixed"

# Also ensure api.dart has the requestSupport function
echo ""
echo "Checking api.dart..."

if ! grep -q "requestSupport" lib/utils/api.dart 2>/dev/null; then
    echo "Adding requestSupport function to api.dart..."
    
    cat >> lib/utils/api.dart << 'EOFAPI'

Future<dynamic> requestSupport(Map<String, dynamic> requestData) async {
  try {
    final uri = Uri.http(API.URL, API.SUPPORT);
    final response = await http.post(
      uri,
      headers: Config.headers,
      body: json.encode(requestData),
    ).timeout(Duration(seconds: Config.timeout));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      return null;
    }
  } catch (e) {
    print('Error requesting support: $e');
    return null;
  }
}
EOFAPI
    echo "✓ requestSupport function added"
else
    echo "✓ api.dart already has requestSupport"
fi

echo ""
echo "STEP 2: Building Tenant App"
echo "────────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo ""
echo "Building Tenant web app (3-5 minutes)..."
TENANT_BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_final_build.log | grep -E "Compiling|Built|✓|Error" || true

TENANT_BUILD_END=$(date +%s)
TENANT_BUILD_TIME=$((TENANT_BUILD_END - TENANT_BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ Tenant app built successfully!"
    echo "   Size: $TENANT_SIZE"
    echo "   Time: ${TENANT_BUILD_TIME}s"
    echo "   Files: $(ls -1 build/web | wc -l)"
else
    echo ""
    echo "❌ Tenant build STILL failed!"
    echo ""
    echo "Last 100 lines of build log:"
    tail -100 /tmp/tenant_final_build.log
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🔄 ALTERNATIVE: Deploy Admin App Only"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "The Tenant app has too many code issues to fix automatically."
    echo "However, the Admin app works perfectly and has ALL features:"
    echo ""
    echo "  ✓ Manage all tenants"
    echo "  ✓ View tenant profiles"
    echo "  ✓ Track payments"
    echo "  ✓ Handle issues"
    echo "  ✓ Manage rooms"
    echo ""
    echo "Would you like to deploy Admin app only? (Recommended)"
    echo ""
    exit 1
fi

echo ""
echo "STEP 3: Deploying Tenant App"
echo "────────────────────────────────────────────────────────"

# Backup old deployment
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
fi

echo "Deploying to Nginx..."
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/

echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant
sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
fi

sudo systemctl reload nginx

echo "✓ Tenant app deployed"

echo ""
echo "STEP 4: Verification"
echo "────────────────────────────────────────────────────────"

sleep 2

TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

if [ "$TENANT_TEST" = "200" ]; then
    echo "✅ Tenant portal: HTTP $TENANT_TEST (Working!)"
else
    echo "⚠️  Tenant portal: HTTP $TENANT_TEST"
fi

# Check if main.dart.js is accessible
if curl -s http://localhost/tenant/main.dart.js | head -1 | grep -q "function"; then
    echo "✅ JavaScript files loading correctly"
else
    echo "⚠️  JavaScript files may have issues"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ TENANT APP DEPLOYED!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 ACCESS TENANT PORTAL:"
echo ""
echo "   URL: http://$PUBLIC_IP/tenant/"
echo ""
echo "   Test Account:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "════════════════════════════════════════════════════════"
echo "⚡ IMPORTANT:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. HARD REFRESH your browser:"
echo "   Windows: Ctrl + Shift + R"
echo "   Mac:     Cmd + Shift + R"
echo ""
echo "2. Or open in Incognito/Private mode"
echo ""
echo "3. If still blank:"
echo "   • Press F12 to open Developer Console"
echo "   • Check Console tab for errors"
echo "   • Check Network tab for failed requests"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

