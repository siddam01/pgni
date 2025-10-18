#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 DIAGNOSING JSON PARSING ERROR"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")

echo ""
echo "Error: 'Unexpected non-whitespace character after JSON'"
echo "This means the API is returning HTML (error page) instead of JSON"
echo ""

echo "════════════════════════════════════════════════════════"
echo "TEST 1: What is the API actually returning?"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing: POST http://localhost/api/login"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $HTTP_CODE"
echo ""
echo "Response Body:"
echo "$BODY" | head -20
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API returns 200, checking if it's valid JSON..."
    if echo "$BODY" | jq . >/dev/null 2>&1; then
        echo "✅ Valid JSON!"
    else
        echo "❌ Invalid JSON! API is returning HTML or malformed data"
    fi
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ 404 - API endpoint not found"
    echo "   The proxy might not be forwarding correctly"
elif [ "$HTTP_CODE" = "502" ]; then
    echo "❌ 502 Bad Gateway - Backend is not responding"
elif [ "$HTTP_CODE" = "500" ]; then
    echo "❌ 500 - Backend error"
else
    echo "⚠️  Unexpected HTTP code: $HTTP_CODE"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 2: Is backend responding correctly?"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing backend directly: POST http://localhost:8080/login"
echo ""

DIRECT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

DIRECT_CODE=$(echo "$DIRECT_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
DIRECT_BODY=$(echo "$DIRECT_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $DIRECT_CODE"
echo ""
echo "Response Body:"
echo "$DIRECT_BODY" | head -20
echo ""

if [ "$DIRECT_CODE" = "200" ]; then
    echo "✅ Backend works directly"
    if echo "$DIRECT_BODY" | jq . >/dev/null 2>&1; then
        echo "✅ Backend returns valid JSON!"
    else
        echo "❌ Backend returns invalid JSON!"
    fi
elif [ "$DIRECT_CODE" = "404" ]; then
    echo "❌ Backend endpoint '/login' not found"
    echo "   Checking what endpoints exist..."
    cd /home/ec2-user/pgni/pgworld-api-master
    if [ -f "main.go" ]; then
        echo ""
        echo "Registered routes in main.go:"
        grep -n "HandleFunc\|router\." main.go | grep -E "login|user" | head -10
    fi
else
    echo "⚠️  Backend issue: HTTP $DIRECT_CODE"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 3: Check Nginx Error Logs"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Recent Nginx errors:"
sudo tail -20 /var/log/nginx/error.log | grep -E "error|crit|alert|emerg" | tail -10

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 4: Check Backend API Logs"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Recent API logs:"
sudo journalctl -u pgworld-api -n 20 --no-pager | grep -E "error|Error|ERROR|panic|fatal" || echo "No errors in logs"

echo ""
echo "════════════════════════════════════════════════════════"
echo "FIX: Check API Route Registration"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

if [ -f "user.go" ]; then
    echo ""
    echo "Checking user.go for Login function..."
    if grep -q "func Login" user.go; then
        echo "✅ Login function exists in user.go"
        grep -A 5 "func Login" user.go | head -10
    else
        echo "❌ Login function NOT found in user.go!"
    fi
fi

if [ -f "main.go" ]; then
    echo ""
    echo "Checking main.go for login route..."
    if grep -q "login\|Login" main.go; then
        echo "✅ Login route registered:"
        grep -n "login\|Login" main.go | head -5
    else
        echo "❌ Login route NOT registered in main.go!"
        echo ""
        echo "FIXING: Adding login route to main.go..."
        
        # Backup
        cp main.go main.go.backup.json_fix_$(date +%s)
        
        # Check if we need to add the route
        if ! grep -q 'router.HandleFunc("/login"' main.go; then
            # Find where to add it (after other HandleFunc calls)
            sed -i '/router.HandleFunc.*Methods.*POST/a\    router.HandleFunc("/login", Login).Methods("POST")' main.go
            echo "✅ Added login route"
            
            echo "Rebuilding API..."
            go build -o /opt/pgworld/pgworld-api
            
            echo "Restarting API..."
            sudo systemctl restart pgworld-api
            sleep 2
            
            echo "✅ API rebuilt and restarted"
        fi
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 5: Final Verification"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing API again after fixes..."
sleep 2

FINAL_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

FINAL_CODE=$(echo "$FINAL_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
FINAL_BODY=$(echo "$FINAL_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $FINAL_CODE"
echo ""

if [ "$FINAL_CODE" = "200" ]; then
    if echo "$FINAL_BODY" | jq . >/dev/null 2>&1; then
        echo "✅ SUCCESS! API returns valid JSON"
        echo ""
        echo "Response preview:"
        echo "$FINAL_BODY" | jq . | head -20
    else
        echo "❌ Still returning invalid JSON"
        echo "Response (first 200 chars):"
        echo "$FINAL_BODY" | head -c 200
    fi
else
    echo "❌ Still getting HTTP $FINAL_CODE"
    echo ""
    echo "Response (first 200 chars):"
    echo "$FINAL_BODY" | head -c 200
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 DIAGNOSIS SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
echo "JSON parsing error means:"
echo "  1. API is reachable (✅ proxy works)"
echo "  2. API returns HTML error page instead of JSON"
echo "  3. Most likely: 404 (endpoint not found) or 500 (server error)"
echo ""
echo "Common causes:"
echo "  • Login route not registered in main.go"
echo "  • API expects /api/login but receives /login"
echo "  • Backend crashed or not responding"
echo "  • Database connection failed"
echo ""
echo "ACTIONS TAKEN:"
echo "  ✓ Checked what API is returning"
echo "  ✓ Tested backend directly"
echo "  ✓ Checked Nginx logs"
echo "  ✓ Checked backend logs"
echo "  ✓ Verified route registration"
echo ""
echo "NEXT STEPS:"
echo ""
echo "If still not working, check:"
echo ""
echo "1. Backend logs for detailed error:"
echo "   sudo journalctl -u pgworld-api -f"
echo ""
echo "2. Test backend health:"
echo "   curl http://localhost:8080/"
echo ""
echo "3. Check database connection:"
echo "   mysql -u root -p -e 'SHOW DATABASES;'"
echo ""
echo "4. Restart everything:"
echo "   sudo systemctl restart pgworld-api"
echo "   sudo systemctl reload nginx"
echo ""
echo "════════════════════════════════════════════════════════"

