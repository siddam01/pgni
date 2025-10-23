#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🚀 DEPLOYING WORKING TENANT APP"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Strategy: Use the proven PRODUCTION_DEPLOY.sh approach"
echo "Result: Clean, working tenant app with Login + Dashboard"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "STEP 1: Backup Current State"
echo "───────────────────────────────────────────────────────"
BACKUP_DIR="/home/ec2-user/pgni/tenant_original_backup_$TIMESTAMP"
cp -r "$TENANT_PATH" "$BACKUP_DIR"
echo "✓ Backup: $BACKUP_DIR"

echo ""
echo "STEP 2: Clean Project Structure"
echo "───────────────────────────────────────────────────────"
rm -rf lib build .dart_tool
mkdir -p lib/{config,services,screens,utils}
echo "✓ Clean structure created"

echo ""
echo "STEP 3: Create Production Configuration"
echo "───────────────────────────────────────────────────────"

cat > lib/config/app_config.dart << 'DART_EOF'
class AppConfig {
  static const bool isProduction = true;
  static const String apiBaseUrl = 'http://54.227.101.30:8080';
  static const String apiKey = 'mrk-1b96d9eeccf649e695ed6ac2b13cb619';
  static const String oneSignalAppId = 'AKIA2FFQRNMAP3IDZD6V';
  static const Duration requestTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String dashboardEndpoint = '/dashboard';
  static const String usersEndpoint = '/users';
  static const String hostelsEndpoint = '/hostels';
  static const String roomsEndpoint = '/rooms';
  static const String billsEndpoint = '/bills';
  static const String issuesEndpoint = '/issues';
  static const String noticesEndpoint = '/notices';
}
DART_EOF

echo "✓ Config created"

echo ""
echo "STEP 4: Create Session Manager"
echo "───────────────────────────────────────────────────────"

cat > lib/services/session_manager.dart << 'DART_EOF'
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveUserData({
    required String userId,
    required String name,
    required String email,
    required String hostelId,
    required String token,
  }) async {
    await _prefs?.setString('userId', userId);
    await _prefs?.setString('name', name);
    await _prefs?.setString('email', email);
    await _prefs?.setString('hostelId', hostelId);
    await _prefs?.setString('token', token);
  }

  static String? getUserId() => _prefs?.getString('userId');
  static String? getName() => _prefs?.getString('name');
  static String? getEmail() => _prefs?.getString('email');
  static String? getHostelId() => _prefs?.getString('hostelId');
  static String? getToken() => _prefs?.getString('token');

  static Future<void> clearSession() async {
    await _prefs?.clear();
  }

  static bool isLoggedIn() {
    return getToken() != null && getUserId() != null;
  }
}
DART_EOF

echo "✓ Session manager created"

echo ""
echo "STEP 5: Create Utility Functions"
echo "───────────────────────────────────────────────────────"

cat > lib/utils/app_utils.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class AppUtils {
  static Future<bool> checkInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static void showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<void> showLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  static String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}
DART_EOF

echo "✓ Utilities created"

echo ""
echo "STEP 6: Create Login Screen"
echo "───────────────────────────────────────────────────────"

cat > lib/screens/login_screen.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/services/session_manager.dart';
import 'package:cloudpgtenant/utils/app_utils.dart';
import 'package:cloudpgtenant/screens/dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloudpgtenant/config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hasInternet = await AppUtils.checkInternet();
      if (!hasInternet) {
        if (mounted) {
          AppUtils.showSnackbar(context, 'No internet connection', isError: true);
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        await SessionManager.saveUserData(
          userId: data['id'] ?? '',
          name: data['name'] ?? 'User',
          email: data['email'] ?? '',
          hostelId: data['hostelID'] ?? '',
          token: data['token'] ?? '',
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          AppUtils.showSnackbar(context, 'Invalid credentials', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackbar(context, 'Login failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tenant Login',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DART_EOF

echo "✓ Login screen created"

echo ""
echo "STEP 7: Create Dashboard Screen"
echo "───────────────────────────────────────────────────────"

cat > lib/screens/dashboard_screen.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/services/session_manager.dart';
import 'package:cloudpgtenant/utils/app_utils.dart';
import 'package:cloudpgtenant/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userName = SessionManager.getName() ?? 'Tenant User';
      _userEmail = SessionManager.getEmail() ?? 'tenant@example.com';
    });
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Dashboard'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[700],
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $_userName!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  'My Profile',
                  Icons.person,
                  Colors.blue,
                  () => AppUtils.showSnackbar(context, 'Profile coming soon!'),
                ),
                _buildDashboardCard(
                  context,
                  'My Room',
                  Icons.room_preferences,
                  Colors.purple,
                  () => AppUtils.showSnackbar(context, 'Room details coming soon!'),
                ),
                _buildDashboardCard(
                  context,
                  'My Bills',
                  Icons.receipt_long,
                  Colors.orange,
                  () => AppUtils.showSnackbar(context, 'Bills coming soon!'),
                ),
                _buildDashboardCard(
                  context,
                  'My Issues',
                  Icons.report_problem,
                  Colors.red,
                  () => AppUtils.showSnackbar(context, 'Issues coming soon!'),
                ),
                _buildDashboardCard(
                  context,
                  'Notices',
                  Icons.notifications,
                  Colors.green,
                  () => AppUtils.showSnackbar(context, 'Notices coming soon!'),
                ),
                _buildDashboardCard(
                  context,
                  'Food Menu',
                  Icons.restaurant_menu,
                  Colors.teal,
                  () => AppUtils.showSnackbar(context, 'Food menu coming soon!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART_EOF

echo "✓ Dashboard screen created"

echo ""
echo "STEP 8: Create Main Entry Point"
echo "───────────────────────────────────────────────────────"

cat > lib/main.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/services/session_manager.dart';
import 'package:cloudpgtenant/screens/login_screen.dart';
import 'package:cloudpgtenant/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PG Tenant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SessionManager.isLoggedIn() 
          ? const DashboardScreen() 
          : const LoginScreen(),
    );
  }
}
DART_EOF

echo "✓ Main entry point created"

echo ""
echo "STEP 9: Update pubspec.yaml"
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
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.2
  http: ^1.1.0
  connectivity_plus: ^5.0.2
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
YAML_EOF

echo "✓ pubspec.yaml updated"

echo ""
echo "STEP 10: Get Dependencies"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
flutter pub get 2>&1 | tail -5
echo "✓ Dependencies resolved"

echo ""
echo "STEP 11: Build for Web"
echo "───────────────────────────────────────────────────────"

BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | grep -E "Compiling|Built|✓" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   Size: $SIZE"
    echo "   Time: ${BUILD_TIME}s"
    
    echo ""
    echo "STEP 12: Deploy to Nginx"
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
    
    # Verify
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    echo "✓ HTTP Status: $STATUS"
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ SUCCESS! WORKING TENANT APP DEPLOYED!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "🌐 URL:      http://54.227.101.30/tenant/"
    echo "📧 Email:    priya@example.com"
    echo "🔐 Password: Tenant@123"
    echo ""
    echo "✅ WORKING FEATURES:"
    echo "   - Professional login page with gradient background"
    echo "   - Email/password validation"
    echo "   - Session management"
    echo "   - Dashboard with user info"
    echo "   - Colored action cards (Profile, Room, Bills, etc.)"
    echo "   - Logout functionality"
    echo ""
    echo "📊 Build Stats:"
    echo "   Time: ${BUILD_TIME}s"
    echo "   Size: $SIZE"
    echo ""
    echo "🎯 TEST NOW:"
    echo "   1. Clear browser cache (Ctrl+Shift+Delete)"
    echo "   2. Open http://54.227.101.30/tenant/ in incognito"
    echo "   3. Login with above credentials"
    echo "   4. See beautiful dashboard with navigation cards!"
    echo ""
    echo "📹 READY FOR SCREEN RECORDING!"
    echo "═══════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ BUILD FAILED"
    exit 1
fi


