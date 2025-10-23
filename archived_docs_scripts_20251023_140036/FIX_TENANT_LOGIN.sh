#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIX TENANT LOGIN & CREATE TEST USER"
echo "════════════════════════════════════════════════════════"

# Get database credentials from API config
API_DIR="/home/ec2-user/pgni/pgworld-api-master"

if [ ! -f "$API_DIR/.env" ]; then
    echo "❌ API .env file not found!"
    echo "Looking for database config..."
    
    # Try to find DB config in Go files
    if [ -f "$API_DIR/config.go" ]; then
        echo "Found config.go"
        grep -E "(DB_|MYSQL)" "$API_DIR/config.go" | head -10 || true
    fi
    
    echo ""
    echo "Please provide database details:"
    read -p "DB Host (default: localhost): " DB_HOST
    DB_HOST=${DB_HOST:-localhost}
    read -p "DB Port (default: 3306): " DB_PORT
    DB_PORT=${DB_PORT:-3306}
    read -p "DB Name (default: pgworld): " DB_NAME
    DB_NAME=${DB_NAME:-pgworld}
    read -p "DB User (default: root): " DB_USER
    DB_USER=${DB_USER:-root}
    read -sp "DB Password: " DB_PASS
    echo ""
else
    echo "✓ Found .env file"
    source "$API_DIR/.env"
    DB_HOST=${DB_HOST:-localhost}
    DB_PORT=${DB_PORT:-3306}
    DB_NAME=${DB_NAME:-pgworld}
    DB_USER=${DB_USER:-root}
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Check Database Connection"
echo "════════════════════════════════════════════════════════"

# Test database connection
if command -v mysql &>/dev/null; then
    echo "Testing database connection..."
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT VERSION();" 2>/dev/null && echo "✓ Database connected" || {
        echo "❌ Cannot connect to database"
        exit 1
    }
else
    echo "❌ MySQL client not installed"
    echo "Install with: sudo yum install mysql -y"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Check Users Table"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Current users in database:"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'EOSQL'
SELECT id, name, email, phone, status, createdDateTime 
FROM users 
ORDER BY createdDateTime DESC 
LIMIT 10;
EOSQL

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Check for Tenant User (priya@example.com)"
echo "════════════════════════════════════════════════════════"

USER_EXISTS=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE email='priya@example.com';")

if [ "$USER_EXISTS" -eq "0" ]; then
    echo "❌ Tenant user 'priya@example.com' does NOT exist!"
    echo ""
    echo "Creating tenant user..."
    
    # Generate password hash (simple MD5 or bcrypt if available)
    # Note: Adjust based on your API's password hashing
    PASSWORD_HASH=$(echo -n "Tenant@123" | md5sum | awk '{print $1}')
    
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOSQL
INSERT INTO users (
    id, 
    hostelID, 
    name, 
    phone, 
    email, 
    password,
    address,
    roomID,
    roomno,
    rent,
    emerContact,
    emerPhone,
    food,
    document,
    paymentStatus,
    joiningDateTime,
    lastPaidDateTime,
    expiryDateTime,
    status,
    createdBy,
    createdDateTime
) VALUES (
    UUID(),
    (SELECT id FROM hostels LIMIT 1),
    'Priya Kumar',
    '9876543210',
    'priya@example.com',
    '$PASSWORD_HASH',
    '123 MG Road, Bangalore',
    (SELECT id FROM rooms LIMIT 1),
    '101',
    '8000',
    'Emergency Contact',
    '9876543211',
    'veg',
    '',
    'paid',
    NOW(),
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 DAY),
    'active',
    'admin',
    NOW()
);
EOSQL
    
    echo "✓ Created tenant user: priya@example.com"
else
    echo "✓ Tenant user exists"
    echo ""
    echo "User details:"
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'EOSQL'
SELECT id, hostelID, name, email, phone, status, roomno, rent
FROM users 
WHERE email='priya@example.com';
EOSQL
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Check Admin User"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Admin users:"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'EOSQL'
SELECT id, name, email, role, status 
FROM admins 
LIMIT 5;
EOSQL

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Test API Login Endpoints"
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

echo ""
echo "Testing ADMIN login endpoint..."
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -d '{
        "email": "admin@pgworld.com",
        "password": "Admin@123"
    }')

echo "$ADMIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ADMIN_RESPONSE"

echo ""
echo "Testing TENANT login endpoint..."
TENANT_RESPONSE=$(curl -s -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -d '{
        "email": "priya@example.com",
        "password": "Tenant@123"
    }')

echo "$TENANT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TENANT_RESPONSE"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Check API Code for User Type Distinction"
echo "════════════════════════════════════════════════════════"

if [ -f "$API_DIR/user.go" ]; then
    echo ""
    echo "Checking user.go for login logic..."
    grep -A 10 -B 2 "func.*Login" "$API_DIR/user.go" | head -30
fi

if [ -f "$API_DIR/admin.go" ]; then
    echo ""
    echo "Checking admin.go for admin login..."
    grep -A 10 -B 2 "func.*Login" "$API_DIR/admin.go" | head -30
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Browser Console Check"
echo "════════════════════════════════════════════════════════"

echo ""
echo "To debug tenant login in browser:"
echo ""
echo "1. Open http://$PUBLIC_IP/tenant/"
echo "2. Press F12 (Developer Console)"
echo "3. Go to 'Network' tab"
echo "4. Try to login with:"
echo "   Email: priya@example.com"
echo "   Password: Tenant@123"
echo "5. Look for the API call to /api/login"
echo "6. Check the Request payload"
echo "7. Check the Response"
echo ""
echo "Common issues:"
echo "   - 404: API endpoint not found"
echo "   - 401: Wrong credentials"
echo "   - 500: Server error"
echo "   - CORS error: API not allowing requests from frontend"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Fix Tenant App API URL"
echo "════════════════════════════════════════════════════════"

TENANT_CONFIG="/home/ec2-user/pgni/pgworldtenant-master/lib/config/app_config.dart"

if [ -f "$TENANT_CONFIG" ]; then
    echo ""
    echo "Current API URL in tenant app:"
    grep "apiBaseUrl" "$TENANT_CONFIG"
    
    echo ""
    echo "Updating to use correct IP..."
    sed -i "s|http://[0-9.]*:8080|http://$PUBLIC_IP:8080|g" "$TENANT_CONFIG"
    
    echo "Updated API URL:"
    grep "apiBaseUrl" "$TENANT_CONFIG"
    
    echo ""
    echo "Rebuilding tenant app..."
    cd /home/ec2-user/pgni/pgworldtenant-master
    flutter build web --release --base-href="/tenant/" --no-source-maps 2>&1 | tail -10
    
    echo ""
    echo "Deploying..."
    sudo rm -rf /usr/share/nginx/html/tenant/*
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo systemctl reload nginx
    
    echo "✓ Tenant app updated and deployed"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SUMMARY"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Tenant Login Credentials:"
echo "   Email:    priya@example.com"
echo "   Password: Tenant@123"
echo ""
echo "Admin Login Credentials:"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "URLs:"
echo "   Tenant: http://$PUBLIC_IP/tenant/"
echo "   Admin:  http://$PUBLIC_IP/admin/"
echo ""
echo "Next steps:"
echo "1. Clear browser cache (Ctrl+Shift+Delete)"
echo "2. Open tenant portal: http://$PUBLIC_IP/tenant/"
echo "3. Try login with priya@example.com"
echo "4. If still fails, open F12 console and check Network tab"
echo "5. Share any error messages"

echo ""
echo "════════════════════════════════════════════════════════"

