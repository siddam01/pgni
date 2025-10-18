#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔍 COMPLETE END-TO-END TESTING & FIX"
echo "   Tenant App Comprehensive Diagnostics"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "54.227.101.30")

echo ""
echo "Server IP: $PUBLIC_IP"
echo "Testing Date: $(date)"
echo ""

# Initialize counters
TESTS_PASSED=0
TESTS_FAILED=0
ISSUES_FOUND=()
FIXES_APPLIED=()

echo "════════════════════════════════════════════════════════"
echo "TEST 1: Database Connection & Configuration"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

# Extract DB config
if [ -f "config.go" ]; then
    echo "Reading database configuration from config.go..."
    DB_HOST=$(grep -A 20 '"database"' config.go | grep host | cut -d'"' -f2 || echo "localhost")
    DB_NAME=$(grep -A 20 '"database"' config.go | grep dbname | cut -d'"' -f2 || echo "pgworld")
    DB_USER=$(grep -A 20 '"database"' config.go | grep user | cut -d'"' -f2 || echo "root")
    DB_PASS=$(grep -A 20 '"database"' config.go | grep password | cut -d'"' -f2)
    
    echo "  Host: $DB_HOST"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Password: ${DB_PASS:0:3}***"
else
    echo "❌ config.go not found!"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("config.go missing")
fi

# Test DB connection
if [ ! -z "$DB_PASS" ]; then
    echo ""
    echo "Testing database connection..."
    if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ Database connection works"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo "❌ Cannot connect to database!"
        TESTS_FAILED=$((TESTS_FAILED+1))
        ISSUES_FOUND+=("Database connection failed")
    fi
    
    # Check if database exists
    echo ""
    echo "Checking if database '$DB_NAME' exists..."
    DB_EXISTS=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES LIKE '$DB_NAME';" | wc -l)
    
    if [ "$DB_EXISTS" -gt 1 ]; then
        echo "✅ Database '$DB_NAME' exists"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo "❌ Database '$DB_NAME' does NOT exist!"
        echo "Creating database..."
        mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
        echo "✅ Database created"
        FIXES_APPLIED+=("Created database $DB_NAME")
    fi
    
    # Check tables
    echo ""
    echo "Checking tables..."
    TABLES=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2)
    
    if echo "$TABLES" | grep -q "users"; then
        echo "✅ 'users' table exists"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo "❌ 'users' table missing!"
        TESTS_FAILED=$((TESTS_FAILED+1))
        ISSUES_FOUND+=("users table missing")
    fi
    
    if echo "$TABLES" | grep -q "hostels"; then
        echo "✅ 'hostels' table exists"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo "❌ 'hostels' table missing!"
        TESTS_FAILED=$((TESTS_FAILED+1))
        ISSUES_FOUND+=("hostels table missing")
    fi
    
    # Show table structure
    echo ""
    echo "Users table structure:"
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE users;" 2>/dev/null || echo "Cannot read table structure"
    
else
    echo "❌ Database password not found!"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("DB password not in config.go")
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 2: Check/Create Test Data"
echo "════════════════════════════════════════════════════════"

if [ ! -z "$DB_PASS" ]; then
    # Check hostels
    echo "Checking hostels..."
    HOSTEL_COUNT=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM hostels WHERE status='active';" 2>/dev/null || echo "0")
    
    echo "Active hostels: $HOSTEL_COUNT"
    
    if [ "$HOSTEL_COUNT" = "0" ]; then
        echo "Creating test hostel..."
        mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOFSQL'
INSERT INTO hostels (id, name, phone, email, address, amenities, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime)
VALUES (
    UUID(),
    'Sunrise PG Hostel',
    '9876543210',
    'admin@sunrisepg.com',
    '123 MG Road, Bangalore, Karnataka - 560001',
    'WiFi,AC,Parking,Food',
    'active',
    'system',
    'system',
    NOW(),
    NOW()
);
EOFSQL
        echo "✅ Created test hostel"
        FIXES_APPLIED+=("Created test hostel")
    else
        echo "✅ Hostels exist"
        TESTS_PASSED=$((TESTS_PASSED+1))
    fi
    
    # Check users
    echo ""
    echo "Checking users..."
    USER_COUNT=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM users WHERE email='priya@example.com';" 2>/dev/null || echo "0")
    
    if [ "$USER_COUNT" = "0" ]; then
        echo "Creating test user priya@example.com..."
        HOSTEL_ID=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
            "SELECT id FROM hostels WHERE status='active' LIMIT 1;")
        
        mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOFSQL
INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime)
VALUES (
    UUID(),
    '$HOSTEL_ID',
    'Priya Sharma',
    'priya@example.com',
    '9876543210',
    'Tenant@123',
    'tenant',
    'active',
    'system',
    'system',
    NOW(),
    NOW()
);
EOFSQL
        echo "✅ Created user priya@example.com"
        FIXES_APPLIED+=("Created test user")
    else
        echo "✅ User exists"
        TESTS_PASSED=$((TESTS_PASSED+1))
        
        # Show user details
        echo ""
        echo "User details:"
        mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
            "SELECT id, name, email, phone, role, status FROM users WHERE email='priya@example.com';" 2>/dev/null
    fi
    
    # Verify user can login
    echo ""
    echo "Verifying login credentials in database..."
    LOGIN_CHECK=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM users WHERE email='priya@example.com' AND password='Tenant@123' AND status='active';" 2>/dev/null || echo "0")
    
    if [ "$LOGIN_CHECK" = "1" ]; then
        echo "✅ User credentials valid in database"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo "❌ User credentials NOT valid!"
        echo "Fixing password..."
        mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
            "UPDATE users SET password='Tenant@123', status='active' WHERE email='priya@example.com';"
        echo "✅ Password updated"
        FIXES_APPLIED+=("Fixed user password")
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 3: API Service Status"
echo "════════════════════════════════════════════════════════"

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ API service is running"
    TESTS_PASSED=$((TESTS_PASSED+1))
    
    # Show service status
    sudo systemctl status pgworld-api --no-pager | head -10
else
    echo "❌ API service NOT running"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("API service stopped")
    
    echo "Starting API service..."
    sudo systemctl start pgworld-api
    sleep 2
    FIXES_APPLIED+=("Started API service")
fi

echo ""
echo "Checking API logs for errors..."
API_ERRORS=$(sudo journalctl -u pgworld-api -n 50 --no-pager | grep -i "error\|panic\|fatal" | tail -10)

if [ -z "$API_ERRORS" ]; then
    echo "✅ No errors in API logs"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo "⚠️  Found errors in API logs:"
    echo "$API_ERRORS"
    ISSUES_FOUND+=("API errors in logs")
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 4: Login API Endpoint"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing: POST http://localhost:8080/login (direct backend)"

BACKEND_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

BACKEND_CODE=$(echo "$BACKEND_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BACKEND_BODY=$(echo "$BACKEND_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $BACKEND_CODE"
echo ""
echo "Response:"
echo "$BACKEND_BODY" | jq . 2>/dev/null || echo "$BACKEND_BODY"

if [ "$BACKEND_CODE" = "200" ]; then
    echo ""
    echo "✅ Backend login works!"
    TESTS_PASSED=$((TESTS_PASSED+1))
elif [ "$BACKEND_CODE" = "401" ]; then
    echo ""
    echo "❌ Invalid credentials"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Backend returns 401")
elif [ "$BACKEND_CODE" = "500" ]; then
    echo ""
    echo "❌ Backend error (500)"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Backend returns 500 - database error")
else
    echo ""
    echo "❌ Unexpected response: $BACKEND_CODE"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Backend returns $BACKEND_CODE")
fi

echo ""
echo "Testing: POST http://localhost/api/login (via Nginx proxy)"

PROXY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

PROXY_CODE=$(echo "$PROXY_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
PROXY_BODY=$(echo "$PROXY_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $PROXY_CODE"
echo ""
echo "Response:"
echo "$PROXY_BODY" | jq . 2>/dev/null || echo "$PROXY_BODY"

if [ "$PROXY_CODE" = "200" ]; then
    echo ""
    echo "✅ Proxy login works!"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo ""
    echo "❌ Proxy issue: HTTP $PROXY_CODE"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Proxy returns $PROXY_CODE")
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 5: Nginx Configuration"
echo "════════════════════════════════════════════════════════"

if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration valid"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo "❌ Nginx configuration error!"
    sudo nginx -t
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Nginx config invalid")
fi

# Test tenant app
echo ""
echo "Testing tenant app: http://localhost/tenant/"
TENANT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

if [ "$TENANT_STATUS" = "200" ]; then
    echo "✅ Tenant app accessible (HTTP 200)"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo "❌ Tenant app issue (HTTP $TENANT_STATUS)"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Tenant app HTTP $TENANT_STATUS")
fi

# Check if Flutter files exist
echo ""
echo "Checking Flutter deployment..."
if [ -f "/usr/share/nginx/html/tenant/index.html" ]; then
    echo "✅ index.html exists"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo "❌ index.html missing!"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("index.html missing")
fi

if [ -f "/usr/share/nginx/html/tenant/main.dart.js" ]; then
    SIZE=$(du -h /usr/share/nginx/html/tenant/main.dart.js | cut -f1)
    echo "✅ main.dart.js exists ($SIZE)"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo "❌ main.dart.js missing!"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("main.dart.js missing")
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "TEST 6: Frontend API Configuration"
echo "════════════════════════════════════════════════════════"

echo "Checking API URL in deployed app..."
if grep -q "/api" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "✅ Relative API URL configured"
    TESTS_PASSED=$((TESTS_PASSED+1))
elif grep -q "54.227.101.30:8080" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "⚠️  Still using direct IP (should use /api)"
    ISSUES_FOUND+=("Frontend uses direct IP instead of /api")
elif grep -q "13.221.117.236" /usr/share/nginx/html/tenant/main.dart.js 2>/dev/null; then
    echo "❌ Using OLD IP!"
    TESTS_FAILED=$((TESTS_FAILED+1))
    ISSUES_FOUND+=("Frontend uses old IP")
else
    echo "⚠️  Cannot determine API URL in frontend"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 TEST RESULTS SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"

if [ ${#ISSUES_FOUND[@]} -gt 0 ]; then
    echo ""
    echo "❌ Issues Found:"
    for issue in "${ISSUES_FOUND[@]}"; do
        echo "  • $issue"
    done
fi

if [ ${#FIXES_APPLIED[@]} -gt 0 ]; then
    echo ""
    echo "✅ Fixes Applied:"
    for fix in "${FIXES_APPLIED[@]}"; do
        echo "  • $fix"
    done
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🎯 FINAL VERDICT"
echo "════════════════════════════════════════════════════════"

if [ "$TESTS_FAILED" -eq 0 ] && [ "$PROXY_CODE" = "200" ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "✅ Database: Connected and populated"
    echo "✅ API: Running and responding"
    echo "✅ Login: Working (HTTP 200)"
    echo "✅ Proxy: Configured correctly"
    echo "✅ Frontend: Deployed"
    echo ""
    echo "🌐 Your app is READY:"
    echo "   http://$PUBLIC_IP/tenant/"
    echo ""
    echo "📧 Login credentials:"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo ""
    echo "⚠️  Clear browser cache before testing!"
elif [ "$BACKEND_CODE" = "500" ] || echo "$BACKEND_BODY" | grep -q -i "database"; then
    echo ""
    echo "❌ DATABASE ERROR DETECTED"
    echo ""
    echo "The issue is with database connectivity or query."
    echo ""
    echo "Common causes:"
    echo "  1. Database not running"
    echo "  2. Wrong credentials in config.go"
    echo "  3. Tables missing or wrong structure"
    echo "  4. User/hostel data missing"
    echo ""
    echo "Recommendations:"
    echo "  1. Check MySQL is running: sudo systemctl status mysqld"
    echo "  2. Verify credentials: mysql -u root -p"
    echo "  3. Check database: SHOW DATABASES; USE pgworld; SHOW TABLES;"
    echo "  4. Run this script again (it created missing data)"
else
    echo ""
    echo "⚠️  PARTIAL SUCCESS"
    echo ""
    echo "Some tests failed. See issues above."
    echo ""
    echo "Next steps:"
    echo "  1. Review failed tests"
    echo "  2. Fix reported issues"
    echo "  3. Run this script again"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📋 DETAILED LOGS"
echo "════════════════════════════════════════════════════════"

echo ""
echo "View logs:"
echo "  API logs:   sudo journalctl -u pgworld-api -f"
echo "  Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "  MySQL logs: sudo tail -f /var/log/mysqld.log"

echo ""
echo "Manual database check:"
echo "  mysql -u root -p"
echo "  USE pgworld;"
echo "  SELECT * FROM users WHERE email='priya@example.com';"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Test completed: $(date)"
echo "════════════════════════════════════════════════════════"

