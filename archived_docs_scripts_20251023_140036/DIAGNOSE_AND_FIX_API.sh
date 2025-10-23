#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 DIAGNOSING API CONNECTION FAILURE"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")

echo ""
echo "Server Public IP: $PUBLIC_IP"
echo "Testing from: $(hostname)"
echo ""

echo "════════════════════════════════════════════════════════"
echo "TEST 1: Is API process running?"
echo "════════════════════════════════════════════════════════"

if systemctl is-active --quiet pgworld-api; then
    echo "✅ API service is running"
    systemctl status pgworld-api --no-pager | head -10
else
    echo "❌ API service is NOT running!"
    echo "Starting API service..."
    sudo systemctl start pgworld-api
    sleep 2
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 2: Is port 8080 listening?"
echo "════════════════════════════════════════════════════════"

if ss -tuln | grep -q ":8080"; then
    echo "✅ Port 8080 is listening:"
    ss -tuln | grep :8080
else
    echo "❌ Port 8080 is NOT listening!"
    echo "Check API logs:"
    sudo journalctl -u pgworld-api -n 20 --no-pager
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 3: Can we connect to API from localhost?"
echo "════════════════════════════════════════════════════════"

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API login works from localhost!"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ 404 - API endpoint not found"
    echo "   The endpoint might be /api/login instead of /login"
else
    echo "⚠️  Unexpected response code: $HTTP_CODE"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 4: Check Security Group / Firewall"
echo "════════════════════════════════════════════════════════"

echo "Checking if port 8080 is accessible from outside..."
echo ""
echo "⚠️  CRITICAL: Your AWS Security Group must allow:"
echo "   - Type: Custom TCP"
echo "   - Port: 8080"
echo "   - Source: 0.0.0.0/0 (or your IP)"
echo ""
echo "To check/fix:"
echo "   1. AWS Console → EC2 → Instances"
echo "   2. Select your instance"
echo "   3. Security → Security groups → Edit inbound rules"
echo "   4. Add rule: Custom TCP, Port 8080, Source 0.0.0.0/0"

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 5: Check CORS Configuration"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

if [ -f "main.go" ]; then
    echo "Checking main.go for CORS configuration..."
    if grep -q "CORS\|cors\|Access-Control" main.go; then
        echo "✅ CORS configuration found in main.go"
        grep -n "CORS\|cors\|Access-Control" main.go | head -5
    else
        echo "❌ No CORS configuration found!"
        echo ""
        echo "FIXING: Adding CORS headers to main.go..."
        
        # Backup
        cp main.go main.go.backup.$(date +%s)
        
        # Check if CORS middleware already exists
        if ! grep -q "func enableCORS" main.go; then
            # Add CORS middleware function before main()
            sed -i '/^func main/i\
func enableCORS(next http.Handler) http.Handler {\
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {\
        w.Header().Set("Access-Control-Allow-Origin", "*")\
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")\
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-API-Key, apikey, Authorization")\
        \
        if r.Method == "OPTIONS" {\
            w.WriteHeader(http.StatusOK)\
            return\
        }\
        \
        next.ServeHTTP(w, r)\
    })\
}\
\
' main.go
            
            echo "✅ Added CORS middleware function"
        fi
        
        # Apply CORS to router
        if ! grep -q "enableCORS" main.go | grep -v "^func enableCORS"; then
            sed -i 's/log.Fatal(http.ListenAndServe/log.Fatal(http.ListenAndServe(":8080", enableCORS(router)))\n\t\/\/ log.Fatal(http.ListenAndServe/' main.go
            echo "✅ Applied CORS middleware to router"
        fi
        
        echo ""
        echo "Rebuilding API with CORS..."
        go build -o /opt/pgworld/pgworld-api
        
        echo "Restarting API service..."
        sudo systemctl restart pgworld-api
        sleep 2
        
        echo "✅ API rebuilt and restarted with CORS enabled"
    fi
else
    echo "⚠️  main.go not found"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 6: Final Connection Test"
echo "════════════════════════════════════════════════════════"

echo "Testing API from localhost again..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API works!"
else
    echo "❌ API still not working (HTTP $HTTP_CODE)"
fi

echo ""
echo "Testing with public IP (requires Security Group fix)..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://$PUBLIC_IP:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1 || echo "Connection failed")

if echo "$RESPONSE" | grep -q "HTTP_CODE:200"; then
    echo "✅ API accessible from public IP!"
else
    echo "❌ API NOT accessible from public IP"
    echo "   This is likely a Security Group issue"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 DIAGNOSIS SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Your issue: 'ClientException: Failed to fetch'"
echo ""
echo "This means the Flutter app cannot reach the API."
echo ""
echo "Most likely causes:"
echo "  1. ❌ AWS Security Group blocking port 8080"
echo "  2. ❌ CORS not configured (now fixed if missing)"
echo "  3. ❌ API not listening on 0.0.0.0 (listening on 127.0.0.1 only)"
echo ""
echo "ACTION REQUIRED:"
echo ""
echo "1. Fix Security Group:"
echo "   → AWS Console → EC2 → Your instance → Security"
echo "   → Edit inbound rules"
echo "   → Add: Custom TCP, Port 8080, Source 0.0.0.0/0"
echo ""
echo "2. After fixing Security Group, test:"
echo "   curl http://$PUBLIC_IP:8080/login"
echo ""
echo "3. If still not working, check if API binds to 0.0.0.0:"
echo "   ss -tuln | grep 8080"
echo "   Should show: 0.0.0.0:8080 (not 127.0.0.1:8080)"
echo ""
echo "════════════════════════════════════════════════════════"

