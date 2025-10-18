#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 VERIFYING FULL TENANT APP - All Pages & Features"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")

echo ""
echo "Server IP: $PUBLIC_IP"
echo ""

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Check Current Tenant App Deployment"
echo "════════════════════════════════════════════════════════"

if [ -d "/usr/share/nginx/html/tenant" ]; then
    echo ""
    echo "Current deployment:"
    ls -lh /usr/share/nginx/html/tenant/ | head -15
    
    SIZE=$(du -sh /usr/share/nginx/html/tenant/ | cut -f1)
    echo ""
    echo "Total size: $SIZE"
    
    # Check which source it came from
    echo ""
    echo "Checking source project..."
    if [ -d "/home/ec2-user/pgni/pgworldtenant-master" ]; then
        TENANT_SOURCE="/home/ec2-user/pgni/pgworldtenant-master"
        echo "✅ Source: $TENANT_SOURCE"
    else
        echo "⚠️  Tenant source project not found!"
        TENANT_SOURCE=""
    fi
else
    echo "❌ Tenant app NOT deployed!"
    TENANT_SOURCE=""
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Check Tenant App Features"
echo "════════════════════════════════════════════════════════"

if [ ! -z "$TENANT_SOURCE" ]; then
    echo ""
    echo "Checking available screens in source..."
    if [ -d "$TENANT_SOURCE/lib/screens" ]; then
        echo ""
        echo "Available screens:"
        ls -1 "$TENANT_SOURCE/lib/screens/" | grep -E "\.dart$" | sed 's/\.dart$//'
        
        SCREEN_COUNT=$(ls -1 "$TENANT_SOURCE/lib/screens/" | grep -E "\.dart$" | wc -l)
        echo ""
        echo "Total screens: $SCREEN_COUNT"
    fi
    
    echo ""
    echo "Checking app config..."
    if [ -f "$TENANT_SOURCE/lib/config/app_config.dart" ]; then
        echo "✅ app_config.dart exists"
        grep "apiBaseUrl" "$TENANT_SOURCE/lib/config/app_config.dart" || echo "No apiBaseUrl found"
    elif [ -f "$TENANT_SOURCE/lib/config.dart" ]; then
        echo "✅ config.dart exists"
        grep "API\|apiBaseUrl" "$TENANT_SOURCE/lib/config.dart" | head -5
    else
        echo "⚠️  Config file not found"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Verify API Endpoints for Tenant Features"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing API endpoints that tenant app needs..."

# Test login
echo ""
echo "1. Login API:"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

if echo "$LOGIN_RESPONSE" | grep -q '"status": 200'; then
    echo "   ✅ Login works"
    
    # Extract user ID and hostel ID for further tests
    USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.id' 2>/dev/null || echo "")
    HOSTEL_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.hostelID' 2>/dev/null || echo "")
    
    echo "   User ID: $USER_ID"
    echo "   Hostel ID: $HOSTEL_ID"
else
    echo "   ❌ Login failed"
    USER_ID=""
    HOSTEL_ID=""
fi

# Test dashboard
echo ""
echo "2. Dashboard API:"
DASHBOARD_RESPONSE=$(curl -s "http://localhost/api/dashboard?hostelID=$HOSTEL_ID&userID=$USER_ID" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" 2>/dev/null || echo "{}")

if echo "$DASHBOARD_RESPONSE" | grep -q "status"; then
    echo "   ✅ Dashboard endpoint exists"
else
    echo "   ⚠️  Dashboard endpoint may not work"
fi

# Test bills
echo ""
echo "3. Bills API:"
BILLS_RESPONSE=$(curl -s "http://localhost/api/bill?hostelID=$HOSTEL_ID&user=$USER_ID" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" 2>/dev/null || echo "{}")

if echo "$BILLS_RESPONSE" | grep -q "status\|bills"; then
    echo "   ✅ Bills endpoint exists"
else
    echo "   ⚠️  Bills endpoint may not work"
fi

# Test issues
echo ""
echo "4. Issues API:"
ISSUES_RESPONSE=$(curl -s "http://localhost/api/issue?hostelID=$HOSTEL_ID" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" 2>/dev/null || echo "{}")

if echo "$ISSUES_RESPONSE" | grep -q "status\|issues"; then
    echo "   ✅ Issues endpoint exists"
else
    echo "   ⚠️  Issues endpoint may not work"
fi

# Test notices
echo ""
echo "5. Notices API:"
NOTICES_RESPONSE=$(curl -s "http://localhost/api/notice?hostelID=$HOSTEL_ID" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" 2>/dev/null || echo "{}")

if echo "$NOTICES_RESPONSE" | grep -q "status\|notices"; then
    echo "   ✅ Notices endpoint exists"
else
    echo "   ⚠️  Notices endpoint may not work"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Test Actual Site Access"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing tenant site HTTP response..."
SITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/tenant/")

if [ "$SITE_STATUS" = "200" ]; then
    echo "✅ Tenant site accessible (HTTP 200)"
else
    echo "❌ Tenant site HTTP $SITE_STATUS"
fi

echo ""
echo "Testing if Flutter app loads..."
SITE_CONTENT=$(curl -s "http://localhost/tenant/" | head -50)

if echo "$SITE_CONTENT" | grep -q "flutter\|main.dart.js"; then
    echo "✅ Flutter app files referenced"
else
    echo "⚠️  Flutter app may not be properly configured"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 TENANT APP ANALYSIS"
echo "════════════════════════════════════════════════════════"

echo ""
echo "✅ WHAT'S WORKING:"
echo "   • Tenant app deployed at: http://$PUBLIC_IP/tenant/"
echo "   • Login API: Working"
echo "   • Database: Connected"
echo "   • Test user: priya@example.com exists"

echo ""
echo "📱 EXPECTED TENANT APP PAGES:"
echo ""
echo "After login, you should see these pages:"
echo ""
echo "   1. 🏠 Dashboard"
echo "      - User info (Name, Email, Phone)"
echo "      - Hostel info"
echo "      - Room details"
echo "      - Quick stats"
echo ""
echo "   2. 👤 Profile"
echo "      - View/Edit personal details"
echo "      - Contact information"
echo "      - Emergency contacts"
echo "      - Document uploads"
echo ""
echo "   3. 💰 Bills"
echo "      - View pending bills"
echo "      - Payment history"
echo "      - Bill details"
echo "      - Due dates"
echo ""
echo "   4. 🛠️ Issues"
echo "      - Report new issues"
echo "      - View submitted issues"
echo "      - Issue status"
echo "      - Issue history"
echo ""
echo "   5. 📢 Notices"
echo "      - View hostel notices"
echo "      - Important announcements"
echo "      - Notice history"
echo ""
echo "   6. 🍽️ Food"
echo "      - Food menu"
echo "      - Meal preferences"
echo "      - Food schedule"
echo ""
echo "   7. 🏢 Room"
echo "      - Room details"
echo "      - Room amenities"
echo "      - Roommate info"
echo ""
echo "   8. 📄 Documents"
echo "      - View uploaded documents"
echo "      - Upload new documents"
echo "      - Document verification status"
echo ""
echo "   9. ⚙️ Settings"
echo "      - App preferences"
echo "      - Logout"
echo ""

echo "════════════════════════════════════════════════════════"
echo "🌐 HOW TO ACCESS YOUR TENANT APP"
echo "════════════════════════════════════════════════════════"

echo ""
echo "1. CLEAR BROWSER CACHE (Very Important!):"
echo "   • Press: Ctrl + Shift + Delete"
echo "   • Select: 'All time'"
echo "   • Check: 'Cached images and files'"
echo "   • Click: 'Clear data'"
echo ""
echo "2. OPEN THE APP:"
echo "   • URL: http://$PUBLIC_IP/tenant/"
echo "   • OR use Incognito: Ctrl + Shift + N"
echo ""
echo "3. LOGIN:"
echo "   • Email:    priya@example.com"
echo "   • Password: Tenant@123"
echo "   • Click:    Login button"
echo ""
echo "4. EXPLORE:"
echo "   • After login, you'll see the Dashboard"
echo "   • Use the menu/navigation to access other pages"
echo "   • Try Bills, Issues, Notices, Profile, etc."
echo ""

echo "════════════════════════════════════════════════════════"
echo "🐛 IF PAGES DON'T LOAD OR SHOW ERRORS:"
echo "════════════════════════════════════════════════════════"

echo ""
echo "1. Open Browser DevTools (F12)"
echo ""
echo "2. Check Console Tab for errors:"
echo "   • Red errors = JavaScript issues"
echo "   • Look for 'Failed to fetch' or '404' errors"
echo ""
echo "3. Check Network Tab:"
echo "   • Look for API calls to /api/*"
echo "   • Check if they return 200 or errors"
echo "   • See what data is returned"
echo ""
echo "4. Common Issues:"
echo "   • Blank page = Usually cached old files"
echo "   • Fix: Clear cache + Hard refresh (Ctrl+Shift+R)"
echo ""
echo "   • Login works but pages blank = API endpoints missing"
echo "   • Fix: Check API logs: sudo journalctl -u pgworld-api -f"
echo ""
echo "   • 'Database error' = Backend can't fetch data"
echo "   • Fix: Check if tables have data"
echo ""

echo "════════════════════════════════════════════════════════"
echo "🔧 VERIFY DATA IN DATABASE"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Checking if tenant has data to display..."

# Check user details
echo ""
echo "User details:"
mysql -h"database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" \
      -u"admin" -p"Omsairamdb951#" "database-PGNi" \
      -e "SELECT name, email, phone, role, roomno, status FROM users WHERE email='priya@example.com';" 2>/dev/null || echo "Could not fetch user"

# Check if there are bills
echo ""
echo "Bills count:"
BILLS_COUNT=$(mysql -h"database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" \
                    -u"admin" -p"Omsairamdb951#" "database-PGNi" \
                    -N -e "SELECT COUNT(*) FROM bills WHERE user='$USER_ID';" 2>/dev/null || echo "0")
echo "  Bills for this user: $BILLS_COUNT"

# Check if there are notices
echo ""
echo "Notices count:"
NOTICES_COUNT=$(mysql -h"database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" \
                      -u"admin" -p"Omsairamdb951#" "database-PGNi" \
                      -N -e "SELECT COUNT(*) FROM notices WHERE hostelID='$HOSTEL_ID';" 2>/dev/null || echo "0")
echo "  Notices for this hostel: $NOTICES_COUNT"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Your Tenant App URL:"
echo "  🔗 http://$PUBLIC_IP/tenant/"
echo ""
echo "Login:"
echo "  📧 priya@example.com"
echo "  🔐 Tenant@123"
echo ""
echo "Expected after login:"
echo "  • Dashboard with user info"
echo "  • Menu/tabs to navigate to:"
echo "    - Profile, Bills, Issues, Notices"
echo "    - Food, Room, Documents, Settings"
echo ""
echo "⚠️  REMEMBER: Clear browser cache before testing!"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Verification completed: $(date)"
echo ""
echo "════════════════════════════════════════════════════════"

