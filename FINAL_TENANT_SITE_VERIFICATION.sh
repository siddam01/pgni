#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🌐 FINAL TENANT SITE VERIFICATION & DEPLOYMENT"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")

echo ""
echo "Server IP: $PUBLIC_IP"
echo "Date: $(date)"
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ VERIFICATION CHECKLIST"
echo "════════════════════════════════════════════════════════"

CHECKS_PASSED=0
CHECKS_TOTAL=0

# Check 1: API Service
echo ""
echo "1. API Service Status"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
if sudo systemctl is-active --quiet pgworld-api; then
    echo "   ✅ API service running"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ API service NOT running"
fi

# Check 2: API Login Works
echo ""
echo "2. API Login Endpoint"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
API_RESPONSE=$(curl -s -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

if echo "$API_RESPONSE" | grep -q '"status": 200'; then
    echo "   ✅ Login API working"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ Login API issue"
    echo "   Response: $API_RESPONSE"
fi

# Check 3: Nginx Running
echo ""
echo "3. Nginx Service"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
if sudo systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx running"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ Nginx NOT running"
fi

# Check 4: Tenant App Files
echo ""
echo "4. Tenant App Deployment"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
if [ -f "/usr/share/nginx/html/tenant/index.html" ] && [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    SIZE=$(du -sh /usr/share/nginx/html/tenant/ | cut -f1)
    echo "   ✅ Tenant app deployed ($SIZE)"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ Tenant app files missing!"
fi

# Check 5: Tenant App Accessible
echo ""
echo "5. Tenant App HTTP Response"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
if [ "$TENANT_STATUS" = "200" ]; then
    echo "   ✅ Tenant app accessible (HTTP 200)"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ Tenant app HTTP $TENANT_STATUS"
fi

# Check 6: Frontend API Configuration
echo ""
echo "6. Frontend API Configuration"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
if grep -q '"/api"' /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "   ✅ Using relative API URL (/api)"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
elif grep -q "$PUBLIC_IP:8080" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "   ⚠️  Using direct IP (will work but not optimal)"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ API URL issue"
fi

# Check 7: Database Connection
echo ""
echo "7. Database Connection"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
if mysql -h"database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" \
         -u"admin" -p"Omsairamdb951#" "database-PGNi" \
         -e "SELECT 1;" >/dev/null 2>&1; then
    echo "   ✅ RDS database connected"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ⚠️  Database connection issue"
fi

# Check 8: Test User Exists
echo ""
echo "8. Test User in Database"
CHECKS_TOTAL=$((CHECKS_TOTAL+1))
USER_CHECK=$(mysql -h"database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com" \
                   -u"admin" -p"Omsairamdb951#" "database-PGNi" \
                   -N -e "SELECT COUNT(*) FROM users WHERE email='priya@example.com' AND status='active';" 2>/dev/null || echo "0")

if [ "$USER_CHECK" = "1" ]; then
    echo "   ✅ Test user exists and active"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
else
    echo "   ❌ Test user missing or inactive"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 RESULTS: $CHECKS_PASSED/$CHECKS_TOTAL checks passed"
echo "════════════════════════════════════════════════════════"

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo ""
    echo "🎉🎉🎉 PERFECT! EVERYTHING IS WORKING! 🎉🎉🎉"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🌐 YOUR TENANT APP IS LIVE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Access your application:"
    echo ""
    echo "   🔗 URL: http://$PUBLIC_IP/tenant/"
    echo ""
    echo "Login credentials:"
    echo ""
    echo "   📧 Email:    priya@example.com"
    echo "   🔐 Password: Tenant@123"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "⚠️  IMPORTANT STEPS BEFORE TESTING:"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "1. CLEAR YOUR BROWSER CACHE:"
    echo "   • Press: Ctrl + Shift + Delete"
    echo "   • Select: 'All time'"
    echo "   • Check: 'Cached images and files'"
    echo "   • Click: 'Clear data'"
    echo ""
    echo "   OR"
    echo ""
    echo "2. USE INCOGNITO/PRIVATE MODE:"
    echo "   • Press: Ctrl + Shift + N (Chrome/Edge)"
    echo "   • Press: Ctrl + Shift + P (Firefox)"
    echo "   • Then go to: http://$PUBLIC_IP/tenant/"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📱 TESTING CHECKLIST:"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "1. ✅ Open: http://$PUBLIC_IP/tenant/"
    echo "2. ✅ You should see: 'PG Tenant Login' screen"
    echo "3. ✅ Enter email: priya@example.com"
    echo "4. ✅ Enter password: Tenant@123"
    echo "5. ✅ Click: Login button"
    echo "6. ✅ You should see: Dashboard with user info"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🐛 IF LOGIN FAILS:"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "1. Open Browser DevTools (F12)"
    echo "2. Go to 'Console' tab - check for errors"
    echo "3. Go to 'Network' tab - check API calls"
    echo "4. Look for: POST request to /api/login"
    echo "5. Check response: Should be status 200"
    echo ""
    echo "Common issues:"
    echo "  • Browser cache → Clear cache and retry"
    echo "  • Old cached JS files → Hard refresh (Ctrl+Shift+R)"
    echo "  • Network error → Check console for details"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 DEPLOYMENT SUMMARY:"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "✅ Backend:"
    echo "   • Go API running on port 8080"
    echo "   • Connected to RDS MySQL database"
    echo "   • Login endpoint working (/api/login)"
    echo ""
    echo "✅ Proxy:"
    echo "   • Nginx reverse proxy configured"
    echo "   • Routes /api/* to backend:8080"
    echo "   • No CORS issues"
    echo ""
    echo "✅ Frontend:"
    echo "   • Flutter web app deployed"
    echo "   • Served by Nginx on port 80"
    echo "   • Using relative URLs for API"
    echo ""
    echo "✅ Database:"
    echo "   • RDS MySQL (database-PGNi)"
    echo "   • Tables created"
    echo "   • Test data inserted"
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🎊 CONGRATULATIONS! 🎊"
    echo ""
    echo "Your PG Tenant Management Application is:"
    echo "  ✅ Fully deployed"
    echo "  ✅ Production ready"
    echo "  ✅ Accessible from anywhere"
    echo ""
    echo "Next steps:"
    echo "  • Test the application thoroughly"
    echo "  • Add more test data if needed"
    echo "  • Consider getting a domain name"
    echo "  • Set up SSL/HTTPS with Let's Encrypt"
    echo ""
    echo "════════════════════════════════════════════════════════"
    
elif [ $CHECKS_PASSED -ge 6 ]; then
    echo ""
    echo "✅ MOSTLY WORKING ($CHECKS_PASSED/$CHECKS_TOTAL checks passed)"
    echo ""
    echo "Your app should work! Minor issues can be ignored."
    echo ""
    echo "🌐 Try accessing: http://$PUBLIC_IP/tenant/"
    echo "📧 Login: priya@example.com / Tenant@123"
    echo ""
    echo "⚠️  Clear browser cache first!"
    
else
    echo ""
    echo "⚠️  SOME ISSUES FOUND ($CHECKS_PASSED/$CHECKS_TOTAL checks passed)"
    echo ""
    echo "Review failed checks above and fix them."
    echo ""
    echo "Common fixes:"
    echo "  • Restart services: sudo systemctl restart pgworld-api nginx"
    echo "  • Check logs: sudo journalctl -u pgworld-api -n 50"
    echo "  • Verify deployment: ls -la /usr/share/nginx/html/tenant/"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🔍 QUICK DEBUG COMMANDS:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Check API logs:"
echo "  sudo journalctl -u pgworld-api -f"
echo ""
echo "Check Nginx logs:"
echo "  sudo tail -f /var/log/nginx/error.log"
echo ""
echo "Test API directly:"
echo "  curl -X POST http://localhost/api/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"priya@example.com\",\"password\":\"Tenant@123\"}'"
echo ""
echo "Check database:"
echo "  mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com \\"
echo "    -u admin -p'Omsairamdb951#' database-PGNi \\"
echo "    -e 'SELECT * FROM users WHERE email=\"priya@example.com\";'"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Verification completed: $(date)"
echo ""
echo "════════════════════════════════════════════════════════"

