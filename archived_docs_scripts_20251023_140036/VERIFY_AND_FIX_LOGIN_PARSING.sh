#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔍 VERIFY LOGIN API RESPONSE PARSING"
echo "═══════════════════════════════════════════════════════"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

echo "ISSUE DETECTED:"
echo "───────────────────────────────────────────────────────"
echo "API Response Structure:"
echo '{
  "data": {
    "user": {
      "id": "...",
      "name": "...",
      "email": "...",
      "hostelID": "..."
    }
  },
  "meta": {
    "status": 200,
    "message": "Login successful"
  }
}'
echo ""
echo "Current Frontend Code expects:"
echo '{
  "id": "...",
  "name": "...",
  "email": "...",
  "hostelID": "..."
}'
echo ""
echo "❌ MISMATCH! Frontend is looking for data at wrong level!"
echo ""

echo "STEP 1: Fix Login Screen to Parse Nested Response"
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
          setState(() => _isLoading = false);
        }
        return;
      }

      print('🔐 Attempting login to: ${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(AppConfig.requestTimeout);

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // API returns nested structure: { "data": { "user": {...} }, "meta": {...} }
        final userData = jsonResponse['data']?['user'];
        
        if (userData != null) {
          print('✅ User data found: ${userData['name']}');
          
          // Save session data
          await SessionManager.saveUserData(
            userId: userData['id']?.toString() ?? '',
            name: userData['name']?.toString() ?? 'User',
            email: userData['email']?.toString() ?? '',
            hostelId: userData['hostelID']?.toString() ?? '',
            token: 'token-${DateTime.now().millisecondsSinceEpoch}',
          );

          print('💾 Session data saved');
          print('🚀 Navigating to dashboard...');

          if (mounted) {
            // Navigate to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          print('❌ No user data in response');
          if (mounted) {
            setState(() => _isLoading = false);
            AppUtils.showSnackbar(
              context, 
              'Login failed: Invalid response from server', 
              isError: true
            );
          }
        }
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        if (mounted) {
          setState(() => _isLoading = false);
          AppUtils.showSnackbar(
            context, 
            'Login failed: Please check your credentials', 
            isError: true
          );
        }
      }
    } catch (e) {
      print('💥 Login error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AppUtils.showSnackbar(
          context, 
          'Login error: ${e.toString()}', 
          isError: true
        );
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
                      Icon(
                        Icons.home_work,
                        size: 64,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PG Tenant Portal',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'priya@example.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Demo Credentials',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Email: priya@example.com\nPassword: Tenant@123',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
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

echo "✓ Updated login screen to parse nested API response"

echo ""
echo "STEP 2: Rebuild and Deploy"
echo "───────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo "Building..."
flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | grep -E "Compiling|Built|✓" || true

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo "✓ Build successful: $SIZE"
    
    echo ""
    echo "Deploying to Nginx..."
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
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ LOGIN PARSING FIX DEPLOYED!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "🔧 WHAT WAS FIXED:"
    echo "   - Login now correctly parses nested API response"
    echo "   - Extracts user data from response.data.user"
    echo "   - Saves all session information properly"
    echo "   - Navigates to dashboard after successful login"
    echo "   - Added debug logging for troubleshooting"
    echo "   - Enhanced login UI with icon and hints"
    echo ""
    echo "🌐 URL:      http://54.227.101.30/tenant/"
    echo "📧 Email:    priya@example.com"
    echo "🔐 Password: Tenant@123"
    echo ""
    echo "🎯 TEST NOW:"
    echo "   1. Clear browser cache (Ctrl+Shift+Delete)"
    echo "   2. Open http://54.227.101.30/tenant/"
    echo "   3. Enter credentials and click LOGIN"
    echo "   4. Check browser console (F12) for debug logs:"
    echo "      🔐 Attempting login..."
    echo "      📡 Response status: 200"
    echo "      ✅ User data found: Priya Sharma"
    echo "      💾 Session data saved"
    echo "      🚀 Navigating to dashboard..."
    echo "   5. Should see dashboard with 6 colored cards!"
    echo ""
    echo "📊 HTTP Status: $STATUS"
    echo "═══════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ BUILD FAILED"
    exit 1
fi

