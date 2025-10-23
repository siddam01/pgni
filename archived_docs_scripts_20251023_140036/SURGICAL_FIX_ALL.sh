#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 SURGICAL FIX - Every Single Error"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

BACKUP="surgical_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
cp -r lib "$BACKUP/" 2>/dev/null || true
echo "✓ Backup: $BACKUP"

echo ""
echo "STEP 1: Fix lib/main.dart and lib/screens/login.dart"
echo "──────────────────────────────────────────────────────"

# Fix main.dart
cat > lib/main.dart << 'EOFMAIN'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/config.dart';
import 'package:cloudpgtenant/utils/utils.dart';
import 'package:cloudpgtenant/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSharedPreference();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PG Tenant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      home: Login(),
    );
  }
}
EOFMAIN

# Fix login.dart
cat > lib/screens/login.dart << 'EOFLOGIN'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloudpgtenant/config.dart';
import 'package:cloudpgtenant/utils/utils.dart';
import 'package:cloudpgtenant/utils/models.dart';
import 'package:cloudpgtenant/screens/dashboard.dart';

class Login extends StatefulWidget {
  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    String? savedUserID = safeGetString('userID');
    String? savedHostelID = safeGetString('hostelID');
    if (savedUserID.isNotEmpty && savedHostelID.isNotEmpty) {
      userID = savedUserID;
      hostelID = savedHostelID;
      name = safeGetString('name');
      emailID = safeGetString('emailID');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasInternet = await checkInternet();
    if (!hasInternet) {
      await oneButtonDialog(context, 'Error', 'No internet connection');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.http(API.URL, API.LOGIN),
        headers: headers,
        body: jsonEncode({'email': _emailController.text, 'password': _passwordController.text}),
      ).timeout(Duration(seconds: timeout));

      final data = jsonDecode(response.body);
      final meta = Meta.fromJson(data['meta'] ?? {});

      if (meta.status == 200 && data['user'] != null) {
        final user = User.fromJson(data['user']);
        userID = user.id;
        hostelID = user.hostelID;
        name = user.name;
        emailID = user.email;
        await safeSetString('userID', user.id);
        await safeSetString('hostelID', user.hostelID);
        await safeSetString('name', user.name);
        await safeSetString('emailID', user.email);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
      } else {
        await oneButtonDialog(context, 'Login Failed', meta.message);
      }
    } catch (e) {
      await oneButtonDialog(context, 'Error', 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PG Tenant Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: Padding(padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15), child: Text('Login', style: TextStyle(fontSize: 18))),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOFLOGIN

echo "✓ Fixed main.dart and login.dart"

echo ""
echo "STEP 2: Fix settings.dart"
echo "──────────────────────────────────────────────────────"

cat > lib/screens/settings.dart << 'EOFSETTINGS'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/config.dart';
import 'package:cloudpgtenant/utils/utils.dart';
import 'package:cloudpgtenant/screens/login.dart';

class Settings extends StatefulWidget {
  @override
  SettingsActivityState createState() => SettingsActivityState();
}

class SettingsActivityState extends State<Settings> {
  String userName = name ?? 'User';
  String userEmail = emailID ?? 'email@example.com';

  Future<void> _logout() async {
    clearSession();
    if (prefs != null) await prefs!.clear();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: Text('Name'), subtitle: Text(userName)),
          ListTile(title: Text('Email'), subtitle: Text(userEmail)),
          ListTile(title: Text('Version'), subtitle: Text(APPVERSION.WEB)),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
EOFSETTINGS

echo "✓ Fixed settings.dart"

echo ""
echo "STEP 3: Fix lib/utils/utils.dart imports"
echo "──────────────────────────────────────────────────────"

cat > lib/utils/utils.dart << 'EOFUTILS'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

SharedPreferences? prefs;

Future<bool> initSharedPreference() async {
  prefs = await SharedPreferences.getInstance();
  return true;
}

String safeGetString(String key, [String defaultValue = '']) {
  return prefs?.getString(key) ?? defaultValue;
}

Future<bool> safeSetString(String key, String value) async {
  if (prefs == null) await initSharedPreference();
  return await prefs!.setString(key, value);
}

Color HexColor(String hexColor) {
  hexColor = hexColor.replaceAll("#", "");
  if (hexColor.length == 6) hexColor = "FF" + hexColor;
  return Color(int.parse(hexColor, radix: 16));
}

Future<void> oneButtonDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [TextButton(child: Text('OK'), onPressed: () => Navigator.pop(context))],
    ),
  );
}

Future<bool> checkInternet() async {
  try {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  } catch (e) {
    return false;
  }
}

void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
EOFUTILS

echo "✓ Fixed utils.dart"

echo ""
echo "STEP 4: Fix all remaining imports"
echo "──────────────────────────────────────────────────────"

find lib -name "*.dart" -type f -exec grep -l "utils/config.dart" {} \; | while read file; do
    sed -i "s|import 'package:cloudpgtenant/utils/config.dart';|import 'package:cloudpgtenant/config.dart';|g" "$file"
    sed -i "s|import 'package:cloudpgtenant/utils/config.dart' as config;||g" "$file"
done

echo "✓ Fixed all imports"

echo ""
echo "STEP 5: Fix api.dart"
echo "──────────────────────────────────────────────────────"

# Ensure api.dart uses correct imports and doesn't return null
if [ -f lib/utils/api.dart ]; then
    # Remove old config import
    sed -i "/import.*utils\/config\.dart/d" lib/utils/api.dart
    # Add new config import at top if not present
    if ! grep -q "import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart; then
        sed -i "1i import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart
    fi
fi

echo "✓ Fixed api.dart"

echo ""
echo "STEP 6: Build and deploy"
echo "──────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
flutter pub get 2>&1 | tail -3

BUILD_START=$(date +%s)
flutter build web --release --no-source-maps --base-href="/tenant/" 2>&1 | tee /tmp/surgical_fix.log

if grep -q "Error:" /tmp/surgical_fix.log; then
    echo ""
    echo "❌ BUILD FAILED - Top 40 unique errors:"
    grep "Error:" /tmp/surgical_fix.log | sort -u | head -40
    echo ""
    echo "Full log: /tmp/surgical_fix.log"
    exit 1
fi

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    
    [ -d "/usr/share/nginx/html/tenant" ] && sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ] && sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    sudo systemctl reload nginx
    
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 URL:      http://13.221.117.236/tenant/"
    echo "👤 Email:    priya@example.com"
    echo "🔐 Password: Tenant@123"
    echo "📊 Status:   HTTP $STATUS"
    echo "⏱️  Build:    ${BUILD_TIME}s"
    echo "📦 Size:     $SIZE"
    echo ""
else
    echo "❌ Build output not found"
    exit 1
fi

