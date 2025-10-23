#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🧪 TENANT APP - COMPLETE END-TO-END TEST"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "PHASE 1: API Backend Verification"
echo "───────────────────────────────────────────────────────"

# Test API health
echo "Testing API health endpoint..."
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
if [ "$API_HEALTH" = "200" ]; then
    echo "✓ API Health: OK ($API_HEALTH)"
else
    echo "⚠️  API Health: $API_HEALTH"
fi

# Test login endpoint
echo ""
echo "Testing login endpoint with tenant credentials..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"email":"priya@example.com","password":"Tenant@123"}')

echo "Login API Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q '"id"'; then
    echo "✓ Login API: Working"
else
    echo "⚠️  Login API: May have issues"
fi

echo ""
echo "PHASE 2: Frontend Deployment Verification"
echo "───────────────────────────────────────────────────────"

# Check deployed files
TENANT_DIR="/usr/share/nginx/html/tenant"
if [ -d "$TENANT_DIR" ]; then
    echo "✓ Tenant directory exists"
    FILE_COUNT=$(find "$TENANT_DIR" -type f | wc -l)
    echo "  Files deployed: $FILE_COUNT"
    
    # Check critical files
    if [ -f "$TENANT_DIR/index.html" ]; then
        echo "  ✓ index.html present"
    else
        echo "  ❌ index.html MISSING!"
    fi
    
    if [ -f "$TENANT_DIR/main.dart.js" ]; then
        SIZE=$(du -h "$TENANT_DIR/main.dart.js" | cut -f1)
        echo "  ✓ main.dart.js present ($SIZE)"
    else
        echo "  ❌ main.dart.js MISSING!"
    fi
    
    if [ -f "$TENANT_DIR/flutter_bootstrap.js" ]; then
        echo "  ✓ flutter_bootstrap.js present"
    else
        echo "  ❌ flutter_bootstrap.js MISSING!"
    fi
else
    echo "❌ Tenant directory does NOT exist!"
fi

echo ""
echo "PHASE 3: HTTP Access Verification"
echo "───────────────────────────────────────────────────────"

# Test main page
MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
echo "GET /tenant/         → HTTP $MAIN_STATUS"

# Test index.html
INDEX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/index.html)
echo "GET /tenant/index.html → HTTP $INDEX_STATUS"

# Test main.dart.js
JS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/main.dart.js)
echo "GET /tenant/main.dart.js → HTTP $JS_STATUS"

# Test flutter_bootstrap.js
BOOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/flutter_bootstrap.js)
echo "GET /tenant/flutter_bootstrap.js → HTTP $BOOT_STATUS"

echo ""
echo "PHASE 4: Content Verification"
echo "───────────────────────────────────────────────────────"

# Check if index.html has correct base href
if grep -q 'base href="/tenant/"' "$TENANT_DIR/index.html" 2>/dev/null; then
    echo "✓ base href is correct: /tenant/"
else
    echo "⚠️  base href may be incorrect"
fi

# Check if config has correct API URL
if [ -f "/home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart" ]; then
    if grep -q "54.227.101.30" /home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart; then
        echo "✓ API URL is correct: 54.227.101.30"
    else
        echo "⚠️  API URL may be incorrect"
    fi
fi

echo ""
echo "PHASE 5: Nginx Configuration Check"
echo "───────────────────────────────────────────────────────"

# Test Nginx config
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx configuration is valid"
else
    echo "⚠️  Nginx configuration has errors"
fi

# Check if Nginx is running
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx service is running"
else
    echo "❌ Nginx service is NOT running!"
fi

echo ""
echo "PHASE 6: Database User Verification"
echo "───────────────────────────────────────────────────────"

# Get DB credentials from config
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="Admin123"
DB_NAME="pgworld"

echo "Checking tenant user in database..."
TENANT_CHECK=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT id, name, email, hostelID FROM users WHERE email='priya@example.com';" 2>/dev/null || echo "")

if [ -n "$TENANT_CHECK" ]; then
    echo "✓ Tenant user exists in database:"
    echo "$TENANT_CHECK" | while IFS=$'\t' read -r id name email hostelID; do
        echo "  ID: $id"
        echo "  Name: $name"
        echo "  Email: $email"
        echo "  Hostel ID: $hostelID"
    done
else
    echo "⚠️  Tenant user NOT found in database!"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📊 TEST SUMMARY"
echo "═══════════════════════════════════════════════════════"
echo ""

# Summary counters
PASS=0
FAIL=0

# Check all critical items
[ "$API_HEALTH" = "200" ] && ((PASS++)) || ((FAIL++))
echo "$LOGIN_RESPONSE" | grep -q '"id"' && ((PASS++)) || ((FAIL++))
[ -f "$TENANT_DIR/index.html" ] && ((PASS++)) || ((FAIL++))
[ -f "$TENANT_DIR/main.dart.js" ] && ((PASS++)) || ((FAIL++))
[ "$MAIN_STATUS" = "200" ] && ((PASS++)) || ((FAIL++))
[ "$JS_STATUS" = "200" ] && ((PASS++)) || ((FAIL++))
systemctl is-active --quiet nginx && ((PASS++)) || ((FAIL++))

TOTAL=$((PASS + FAIL))
PERCENT=$((PASS * 100 / TOTAL))

echo "Tests Passed: $PASS / $TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 85 ]; then
    echo "✅ TENANT APP IS READY FOR TESTING!"
    echo ""
    echo "🎯 MANUAL TEST STEPS:"
    echo "───────────────────────────────────────────────────────"
    echo "1. Open browser (Chrome/Edge/Firefox)"
    echo "2. Press Ctrl+Shift+Delete → Clear cache"
    echo "3. Open: http://54.227.101.30/tenant/"
    echo "4. You should see: Blue gradient login page"
    echo "5. Enter Email: priya@example.com"
    echo "6. Enter Password: Tenant@123"
    echo "7. Click LOGIN button"
    echo "8. Should immediately navigate to Dashboard"
    echo "9. Dashboard should show:"
    echo "   - Welcome message with user name"
    echo "   - 6 colored navigation cards"
    echo "   - Logout button (top-right)"
    echo "10. Click any card → Should show 'coming soon' message"
    echo "11. Click Logout → Should return to login page"
    echo ""
    echo "📹 If all steps work, START SCREEN RECORDING!"
    echo ""
else
    echo "⚠️  SOME TESTS FAILED - MANUAL VERIFICATION NEEDED"
    echo ""
    echo "Common fixes:"
    echo "1. Restart Nginx: sudo systemctl restart nginx"
    echo "2. Check logs: sudo tail -50 /var/log/nginx/error.log"
    echo "3. Verify API: curl http://localhost:8080/health"
fi

echo "═══════════════════════════════════════════════════════"

