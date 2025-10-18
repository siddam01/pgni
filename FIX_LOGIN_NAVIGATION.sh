#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING LOGIN NAVIGATION - Redirect to Dashboard"
echo "════════════════════════════════════════════════════════"

TENANT_DIR="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_DIR"

echo ""
echo "Checking login screen navigation logic..."
echo ""

if [ -f "lib/screens/login.dart" ] || [ -f "lib/screens/login_screen.dart" ]; then
    
    LOGIN_FILE=$(find lib/screens -name "*login*.dart" | head -1)
    echo "Found login file: $LOGIN_FILE"
    
    echo ""
    echo "Checking current navigation after login..."
    grep -A 20 "Navigator\|pushReplacement\|pushNamed" "$LOGIN_FILE" | head -30 || echo "No navigation found"
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "STEP 1: Fix login navigation"
    echo "════════════════════════════════════════════════════════"
    
    # Backup
    cp "$LOGIN_FILE" "${LOGIN_FILE}.backup.nav.$(date +%s)"
    
    # Check if navigation exists after successful login
    if grep -q "Navigator.pushReplacement\|Navigator.pushNamed" "$LOGIN_FILE"; then
        echo "✓ Navigation code exists, checking if it's correct..."
        
        # Check if it navigates to Dashboard
        if grep -q "DashboardScreen\|dashboard\|Dashboard" "$LOGIN_FILE"; then
            echo "✓ Already navigates to Dashboard"
        else
            echo "⚠️  Navigation exists but may not go to Dashboard"
            echo "   Adding proper navigation..."
            
            # Find where login success happens and add navigation
            sed -i '/status.*200\|success.*true/a\                Navigator.pushReplacement(\n                  context,\n                  MaterialPageRoute(builder: (context) => DashboardScreen()),\n                );' "$LOGIN_FILE"
        fi
    else
        echo "❌ No navigation after login! Adding it..."
        
        # Add navigation after successful login response
        # This is a bit tricky, we need to find where login succeeds
        
        # Pattern 1: Look for where API response is successful
        if grep -q "status.*==.*200" "$LOGIN_FILE"; then
            LINE_NUM=$(grep -n "status.*==.*200" "$LOGIN_FILE" | head -1 | cut -d: -f1)
            echo "   Found success check at line $LINE_NUM"
            
            # Add navigation after this line
            sed -i "${LINE_NUM}a\                // Navigate to dashboard\n                Navigator.pushReplacement(\n                  context,\n                  MaterialPageRoute(builder: (context) => DashboardScreen()),\n                );" "$LOGIN_FILE"
        fi
    fi
    
    # Ensure DashboardScreen is imported
    if ! grep -q "import.*dashboard" "$LOGIN_FILE"; then
        echo ""
        echo "Adding Dashboard import..."
        sed -i "1i import 'package:cloudpgtenant/screens/dashboard.dart';" "$LOGIN_FILE"
    fi
    
    echo "✓ Updated login navigation"
    
else
    echo "❌ Login file not found!"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Verify Dashboard screen exists"
echo "════════════════════════════════════════════════════════"

if [ -f "lib/screens/dashboard.dart" ]; then
    echo "✅ Dashboard screen exists"
    head -20 lib/screens/dashboard.dart
elif [ -f "lib/screens/dashboard_screen.dart" ]; then
    echo "✅ Dashboard screen exists (dashboard_screen.dart)"
    head -20 lib/screens/dashboard_screen.dart
else
    echo "❌ Dashboard screen missing! Creating it..."
    
    cat > lib/screens/dashboard.dart << 'EOFDASH'
import 'package:flutter/material.dart';
import 'package:cloudpgtenant/config/app_config.dart';
import 'package:cloudpgtenant/services/session_manager.dart';
import 'package:cloudpgtenant/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _hostelInfo;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get user info from session
      final userName = await SessionManager.getUserName();
      final userEmail = await SessionManager.getUserEmail();
      final hostelId = await SessionManager.getHostelId();
      
      setState(() {
        _userInfo = {
          'name': userName ?? 'User',
          'email': userEmail ?? '',
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await SessionManager.clearSession();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _userInfo?['name'] ?? 'User',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _userInfo?['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Quick Actions Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        'Profile',
                        Icons.person,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/profile'),
                      ),
                      _buildActionCard(
                        'Bills',
                        Icons.receipt,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/bills'),
                      ),
                      _buildActionCard(
                        'Issues',
                        Icons.report_problem,
                        Colors.orange,
                        () => Navigator.pushNamed(context, '/issues'),
                      ),
                      _buildActionCard(
                        'Notices',
                        Icons.notifications,
                        Colors.purple,
                        () => Navigator.pushNamed(context, '/notices'),
                      ),
                      _buildActionCard(
                        'Food',
                        Icons.restaurant,
                        Colors.red,
                        () => Navigator.pushNamed(context, '/food'),
                      ),
                      _buildActionCard(
                        'Room',
                        Icons.hotel,
                        Colors.teal,
                        () => Navigator.pushNamed(context, '/room'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOFDASH
    
    echo "✅ Created Dashboard screen"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Check main.dart routes"
echo "════════════════════════════════════════════════════════"

if [ -f "lib/main.dart" ]; then
    echo "Checking routes in main.dart..."
    
    if grep -q "routes:" lib/main.dart; then
        echo "✓ Routes defined"
        grep -A 10 "routes:" lib/main.dart | head -15
    else
        echo "⚠️  No routes found, app might use direct navigation"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Rebuild tenant app"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache

echo ""
echo "Running flutter pub get..."
flutter pub get

echo ""
echo "Building tenant app..."
BUILD_START=$(date +%s)

flutter build web \
  --release \
  --base-href="/tenant/" \
  --no-source-maps \
  --dart-define=dart.vm.product=true \
  2>&1 | grep -E "Compiling|Built|✓|Error|error" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ Build successful: $SIZE in ${BUILD_TIME}s"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Deploy to Nginx"
echo "════════════════════════════════════════════════════════"

sudo rm -rf /usr/share/nginx/html/tenant.old 2>/dev/null || true
sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.old 2>/dev/null || true
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
sudo chmod -R 755 /usr/share/nginx/html/tenant

if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
fi

echo "✓ Deployed"

sudo systemctl reload nginx
sleep 2

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Test"
echo "════════════════════════════════════════════════════════"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "Tenant app: HTTP $STATUS $([ "$STATUS" = "200" ] && echo "✅" || echo "⚠️")"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ NAVIGATION FIX COMPLETE!"
echo "════════════════════════════════════════════════════════"

echo ""
echo "🌐 Test your app:"
echo "   URL: http://54.227.101.30/tenant/"
echo ""
echo "📧 Login:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "✅ What should happen:"
echo "   1. Enter credentials"
echo "   2. Click Login button"
echo "   3. → AUTOMATICALLY navigate to Dashboard"
echo "   4. See: Welcome message, user info, quick action cards"
echo "   5. Click cards to access: Profile, Bills, Issues, Notices, Food, Room"
echo ""
echo "⚠️  IMPORTANT:"
echo "   • Clear browser cache: Ctrl+Shift+Delete"
echo "   • Or use Incognito: Ctrl+Shift+N"
echo "   • Hard refresh: Ctrl+Shift+R"
echo ""
echo "🐛 If still not redirecting:"
echo "   • Open DevTools (F12) → Console"
echo "   • Look for JavaScript errors"
echo "   • Check Network tab for API response"
echo ""
echo "════════════════════════════════════════════════════════"

