#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 COMPREHENSIVE API SERVER DIAGNOSTICS"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "54.227.101.30")
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Server IPs:"
echo "  Public:  $PUBLIC_IP"
echo "  Private: $PRIVATE_IP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Check if API Service is Running"
echo "════════════════════════════════════════════════════════"

# Check systemd service
if systemctl list-units --type=service | grep -q pgworld; then
    echo ""
    echo "API Service Status:"
    sudo systemctl status pgworld-api --no-pager -l | head -20
else
    echo "⚠️  No pgworld-api systemd service found"
fi

# Check if port 8080 is listening
echo ""
echo "Checking port 8080..."
PORT_CHECK=$(sudo netstat -tlnp | grep :8080 || echo "")

if [ -n "$PORT_CHECK" ]; then
    echo "✅ Port 8080 is LISTENING:"
    echo "$PORT_CHECK"
else
    echo "❌ Port 8080 is NOT listening!"
    echo ""
    echo "Checking all listening ports:"
    sudo netstat -tlnp | grep LISTEN | head -10
fi

echo ""
echo "Checking process on port 8080:"
sudo lsof -i :8080 2>/dev/null || echo "No process found on port 8080"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Test API Endpoints"
echo "════════════════════════════════════════════════════════"

# Test various endpoints
echo ""
echo "Testing common API endpoints..."

echo ""
echo "1. Root API:"
curl -s -o /dev/null -w "   GET http://localhost:8080/  →  HTTP %{http_code}\n" http://localhost:8080/ || echo "   FAILED"

echo "2. API Root:"
curl -s -o /dev/null -w "   GET http://localhost:8080/api  →  HTTP %{http_code}\n" http://localhost:8080/api || echo "   FAILED"

echo "3. Health Check:"
curl -s -o /dev/null -w "   GET http://localhost:8080/api/health  →  HTTP %{http_code}\n" http://localhost:8080/api/health || echo "   FAILED"

echo "4. Login Endpoint:"
curl -s -o /dev/null -w "   POST http://localhost:8080/api/login  →  HTTP %{http_code}\n" -X POST http://localhost:8080/api/login -H "Content-Type: application/json" -d '{}' || echo "   FAILED"

echo "5. Users Endpoint:"
curl -s -o /dev/null -w "   GET http://localhost:8080/api/users  →  HTTP %{http_code}\n" http://localhost:8080/api/users || echo "   FAILED"

echo "6. Dashboard Endpoint:"
curl -s -o /dev/null -w "   GET http://localhost:8080/api/dashboard  →  HTTP %{http_code}\n" http://localhost:8080/api/dashboard || echo "   FAILED"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Test Login API with Real Credentials"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing tenant login API..."
TENANT_RESPONSE=$(curl -s -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

echo "Response:"
echo "$TENANT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TENANT_RESPONSE"

if echo "$TENANT_RESPONSE" | grep -q "200\|success\|token\|user"; then
    echo ""
    echo "✅ Login API is working!"
else
    echo ""
    echo "⚠️  Login API returned unexpected response"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Check API Logs"
echo "════════════════════════════════════════════════════════"

if [ -f "/tmp/api.log" ]; then
    echo ""
    echo "Last 20 lines of /tmp/api.log:"
    tail -20 /tmp/api.log
fi

if systemctl list-units --type=service | grep -q pgworld; then
    echo ""
    echo "Last 30 lines of systemd journal:"
    sudo journalctl -u pgworld-api -n 30 --no-pager
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Check API Source Code & Routes"
echo "════════════════════════════════════════════════════════"

API_DIR="/home/ec2-user/pgni/pgworld-api-master"

if [ -f "$API_DIR/main.go" ]; then
    echo ""
    echo "Checking main.go for route definitions..."
    grep -E "HandleFunc|router\.|POST|GET|r\." "$API_DIR/main.go" | head -30 || echo "Could not find routes"
fi

if [ -f "$API_DIR/user.go" ]; then
    echo ""
    echo "Checking user.go for login function..."
    grep -B 5 -A 10 "func.*Login" "$API_DIR/user.go" | head -20 || echo "Could not find login function"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Check Tenant App API Configuration"
echo "════════════════════════════════════════════════════════"

TENANT_CONFIG="/home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart"

if [ -f "$TENANT_CONFIG" ]; then
    echo ""
    echo "Tenant app API configuration:"
    grep -E "apiBaseUrl|API\." "$TENANT_CONFIG" | head -10
    
    # Check if deployed JS has correct API URL
    echo ""
    echo "Checking deployed tenant app for API URL..."
    if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
        API_IN_JS=$(strings /usr/share/nginx/html/tenant/main.dart.js | grep -o "http://[^\"']*:8080" | head -1)
        if [ -n "$API_IN_JS" ]; then
            echo "Found API URL in deployed app: $API_IN_JS"
            
            if [[ "$API_IN_JS" == *"$PUBLIC_IP"* ]]; then
                echo "✅ Correct IP in deployed app"
            else
                echo "⚠️  Wrong IP in deployed app!"
                echo "   Expected: http://$PUBLIC_IP:8080"
                echo "   Found:    $API_IN_JS"
            fi
        else
            echo "⚠️  Could not find API URL in deployed JavaScript"
        fi
    fi
else
    echo "⚠️  Tenant config file not found at $TENANT_CONFIG"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Test API from Public IP"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing API access via public IP..."
curl -s -o /dev/null -w "http://$PUBLIC_IP:8080/api/login  →  HTTP %{http_code}\n" \
    -X POST "http://$PUBLIC_IP:8080/api/login" \
    -H "Content-Type: application/json" \
    -d '{}' \
    --connect-timeout 10 || echo "FAILED - Cannot reach API via public IP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Check Firewall & Security Group"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Checking iptables..."
sudo iptables -L -n | grep 8080 || echo "No iptables rules for port 8080"

echo ""
echo "Checking firewalld..."
if command -v firewall-cmd &>/dev/null; then
    sudo firewall-cmd --list-all 2>/dev/null || echo "Firewalld not active"
else
    echo "Firewalld not installed"
fi

echo ""
echo "⚠️  SECURITY GROUP CHECK:"
echo "You must ensure AWS Security Group allows:"
echo "   - Inbound: Port 8080 from 0.0.0.0/0 (or your IP)"
echo "   - Inbound: Port 80 from 0.0.0.0/0"

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 DIAGNOSIS SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
if [ -n "$PORT_CHECK" ]; then
    echo "✅ API Server: Running on port 8080"
else
    echo "❌ API Server: NOT running on port 8080"
fi

echo ""
echo "Common 404 Error Causes:"
echo ""
echo "1. API endpoint path is wrong"
echo "   - Tenant app calls: /api/login"
echo "   - API expects: /api/user/login or different path"
echo ""
echo "2. API server not accessible from outside"
echo "   - Works on localhost but not on public IP"
echo "   - Security Group blocking port 8080"
echo ""
echo "3. CORS issues"
echo "   - API not allowing requests from frontend domain"
echo "   - Check API CORS configuration"
echo ""
echo "4. API server crashed or not started"
echo "   - Check: sudo systemctl status pgworld-api"
echo "   - Restart: sudo systemctl restart pgworld-api"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🔧 QUICK FIXES"
echo "════════════════════════════════════════════════════════"

echo ""
echo "If API is not running:"
echo "  cd /home/ec2-user/pgni/pgworld-api-master"
echo "  sudo systemctl start pgworld-api"
echo "  sudo systemctl status pgworld-api"
echo ""
echo "If API is running but getting 404:"
echo "  1. Check API routes in main.go"
echo "  2. Make sure endpoint is /api/login (not /login)"
echo "  3. Test with: curl -X POST http://localhost:8080/api/login -d '{}'"
echo ""
echo "If port 8080 blocked:"
echo "  1. AWS Console → EC2 → Security Groups"
echo "  2. Add Inbound Rule: Custom TCP, Port 8080, Source: 0.0.0.0/0"
echo ""
echo "View logs:"
echo "  sudo journalctl -u pgworld-api -f"
echo ""
echo "════════════════════════════════════════════════════════"

