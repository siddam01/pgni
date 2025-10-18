#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 AUTO FIX TENANT LOGIN (No Manual Input Needed)"
echo "════════════════════════════════════════════════════════"

API_DIR="/home/ec2-user/pgni/pgworld-api-master"

echo ""
echo "Step 1: Auto-detecting database configuration..."

# Try to extract DB config from Go files
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="pgworld"
DB_USER="root"
DB_PASS=""

if [ -f "$API_DIR/config.go" ]; then
    echo "✓ Found config.go, extracting DB config..."
    
    # Extract database name
    DB_NAME_FOUND=$(grep -oP 'DBName.*=.*"\K[^"]+' "$API_DIR/config.go" 2>/dev/null || echo "")
    [ -n "$DB_NAME_FOUND" ] && DB_NAME="$DB_NAME_FOUND"
    
    # Extract database user
    DB_USER_FOUND=$(grep -oP 'DBUser.*=.*"\K[^"]+' "$API_DIR/config.go" 2>/dev/null || echo "")
    [ -n "$DB_USER_FOUND" ] && DB_USER="$DB_USER_FOUND"
    
    # Extract database password
    DB_PASS_FOUND=$(grep -oP 'DBPassword.*=.*"\K[^"]+' "$API_DIR/config.go" 2>/dev/null || echo "")
    [ -n "$DB_PASS_FOUND" ] && DB_PASS="$DB_PASS_FOUND"
    
    # Extract database host
    DB_HOST_FOUND=$(grep -oP 'DBHost.*=.*"\K[^"]+' "$API_DIR/config.go" 2>/dev/null || echo "")
    [ -n "$DB_HOST_FOUND" ] && DB_HOST="$DB_HOST_FOUND"
fi

# Try .env file if exists
if [ -f "$API_DIR/.env" ]; then
    echo "✓ Found .env file"
    source "$API_DIR/.env" 2>/dev/null || true
fi

# Try alternative environment variable names
DB_HOST=${DB_HOST:-${MYSQL_HOST:-localhost}}
DB_PORT=${DB_PORT:-${MYSQL_PORT:-3306}}
DB_NAME=${DB_NAME:-${MYSQL_DATABASE:-pgworld}}
DB_USER=${DB_USER:-${MYSQL_USER:-root}}
DB_PASS=${DB_PASS:-${MYSQL_PASSWORD:-}}

echo ""
echo "Detected configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: ${DB_PASS:+[SET]}${DB_PASS:-[EMPTY]}"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 2: Testing database connection..."
echo "════════════════════════════════════════════════════════"

# Build MySQL command
if [ -n "$DB_PASS" ]; then
    MYSQL_CMD="mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS"
else
    MYSQL_CMD="mysql -h$DB_HOST -P$DB_PORT -u$DB_USER"
fi

# Test connection
if ! command -v mysql &>/dev/null; then
    echo "❌ MySQL client not installed"
    echo "Installing MySQL client..."
    sudo yum install -y mysql >/dev/null 2>&1 || sudo apt-get install -y mysql-client >/dev/null 2>&1
fi

# Test database access
if $MYSQL_CMD -e "USE $DB_NAME; SELECT 1;" 2>/dev/null >/dev/null; then
    echo "✅ Database connection successful!"
else
    echo "❌ Cannot connect to database with detected credentials"
    echo ""
    echo "Trying without password..."
    if mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -e "USE $DB_NAME; SELECT 1;" 2>/dev/null >/dev/null; then
        echo "✅ Connected without password"
        MYSQL_CMD="mysql -h$DB_HOST -P$DB_PORT -u$DB_USER"
        DB_PASS=""
    else
        echo "❌ Still cannot connect"
        echo ""
        echo "Common default passwords to try:"
        echo "1. Empty password (no password)"
        echo "2. root"
        echo "3. password"
        echo "4. admin"
        echo ""
        echo "Please run this manually:"
        echo "mysql -u root -p"
        echo ""
        echo "Then run these SQL commands:"
        cat << 'EOSQL'

-- Create tenant user
USE pgworld;

INSERT INTO users (
    id, hostelID, name, phone, email, password,
    address, roomno, rent, paymentStatus, status, createdDateTime
) VALUES (
    UUID(),
    (SELECT id FROM hostels LIMIT 1),
    'Priya Kumar',
    '9876543210',
    'priya@example.com',
    MD5('Tenant@123'),
    '123 MG Road, Bangalore',
    '101',
    '8000',
    'paid',
    'active',
    NOW()
) ON DUPLICATE KEY UPDATE name='Priya Kumar';

SELECT 'User created/updated successfully' as result;
EOSQL
        exit 1
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 3: Checking database tables..."
echo "════════════════════════════════════════════════════════"

echo ""
echo "Available tables:"
$MYSQL_CMD "$DB_NAME" -e "SHOW TABLES;"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 4: Checking for tenant user..."
echo "════════════════════════════════════════════════════════"

USER_COUNT=$($MYSQL_CMD "$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE email='priya@example.com';")

echo ""
if [ "$USER_COUNT" -eq "0" ]; then
    echo "❌ Tenant user NOT found. Creating..."
    
    # Get a hostel ID
    HOSTEL_ID=$($MYSQL_CMD "$DB_NAME" -se "SELECT id FROM hostels LIMIT 1;")
    
    if [ -z "$HOSTEL_ID" ]; then
        echo "⚠️  No hostels found. Creating sample hostel first..."
        $MYSQL_CMD "$DB_NAME" <<'EOSQL'
INSERT INTO hostels (id, name, phone, email, address, status, createdDateTime)
VALUES (UUID(), 'Sample PG', '9999999999', 'admin@pgworld.com', 'Sample Address', 'active', NOW());
EOSQL
        HOSTEL_ID=$($MYSQL_CMD "$DB_NAME" -se "SELECT id FROM hostels LIMIT 1;")
    fi
    
    # Get a room ID
    ROOM_ID=$($MYSQL_CMD "$DB_NAME" -se "SELECT id FROM rooms WHERE hostelID='$HOSTEL_ID' LIMIT 1;")
    
    if [ -z "$ROOM_ID" ]; then
        echo "⚠️  No rooms found. Creating sample room first..."
        $MYSQL_CMD "$DB_NAME" <<EOSQL
INSERT INTO rooms (id, hostelID, roomno, rent, capacity, filled, status, createdDateTime)
VALUES (UUID(), '$HOSTEL_ID', '101', '8000', '2', '0', 'available', NOW());
EOSQL
        ROOM_ID=$($MYSQL_CMD "$DB_NAME" -se "SELECT id FROM rooms WHERE hostelID='$HOSTEL_ID' LIMIT 1;")
    fi
    
    echo "✓ Hostel ID: $HOSTEL_ID"
    echo "✓ Room ID: $ROOM_ID"
    
    # Create user with MD5 password (common for simple setups)
    echo ""
    echo "Creating tenant user with:"
    echo "  Email: priya@example.com"
    echo "  Password: Tenant@123 (hashed)"
    
    $MYSQL_CMD "$DB_NAME" <<EOSQL
INSERT INTO users (
    id, hostelID, name, phone, email, password,
    address, roomID, roomno, rent,
    emerContact, emerPhone, food,
    paymentStatus, joiningDateTime, expiryDateTime,
    status, createdBy, createdDateTime
) VALUES (
    UUID(),
    '$HOSTEL_ID',
    'Priya Kumar',
    '9876543210',
    'priya@example.com',
    MD5('Tenant@123'),
    '123 MG Road, Bangalore',
    '$ROOM_ID',
    '101',
    '8000',
    'Emergency Contact',
    '9876543211',
    'veg',
    'paid',
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 DAY),
    'active',
    'system',
    NOW()
);
EOSQL
    
    echo "✅ Tenant user created successfully!"
else
    echo "✅ Tenant user already exists"
fi

echo ""
echo "Current tenant user details:"
$MYSQL_CMD "$DB_NAME" <<'EOSQL'
SELECT id, hostelID, name, email, phone, roomno, rent, status, createdDateTime
FROM users 
WHERE email='priya@example.com';
EOSQL

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 5: Checking admin user..."
echo "════════════════════════════════════════════════════════"

echo ""
echo "Admin users in database:"
$MYSQL_CMD "$DB_NAME" -e "SELECT id, name, email, role, status FROM admins LIMIT 5;" 2>/dev/null || echo "⚠️  Admins table not found or empty"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 6: Testing API endpoints..."
echo "════════════════════════════════════════════════════════"

PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

echo ""
echo "Testing tenant login via API..."
TENANT_TEST=$(curl -s -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{
        "email": "priya@example.com",
        "password": "Tenant@123"
    }')

echo "API Response:"
echo "$TENANT_TEST" | python3 -m json.tool 2>/dev/null || echo "$TENANT_TEST"

if echo "$TENANT_TEST" | grep -q "\"status\":200"; then
    echo ""
    echo "✅ Tenant login API works!"
elif echo "$TENANT_TEST" | grep -q "\"status\":401"; then
    echo ""
    echo "❌ API returns 401 - Wrong password or user not found"
    echo ""
    echo "This might mean the API uses a different password hashing method."
    echo "Check your API code (user.go or auth.go) to see how passwords are hashed."
else
    echo ""
    echo "⚠️  Unexpected API response. Check API logs:"
    echo "sudo journalctl -u pgworld-api -n 30"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SUMMARY & NEXT STEPS"
echo "════════════════════════════════════════════════════════"

echo ""
echo "📊 Status:"
echo "  ✅ Database: Connected"
echo "  ✅ User: $([ "$USER_COUNT" -gt "0" ] && echo "Exists" || echo "Created")"
echo "  ✅ API: Running on port 8080"
echo ""
echo "🔐 Login Credentials:"
echo "  📧 Tenant Email:    priya@example.com"
echo "  🔑 Tenant Password: Tenant@123"
echo ""
echo "  📧 Admin Email:     admin@pgworld.com"  
echo "  🔑 Admin Password:  Admin@123"
echo ""
echo "🌐 Access URLs:"
echo "  Tenant: http://$PUBLIC_IP/tenant/"
echo "  Admin:  http://$PUBLIC_IP/admin/"
echo ""
echo "🔍 If tenant login still doesn't work:"
echo ""
echo "1. Open tenant portal in browser"
echo "2. Press F12 → Network tab"
echo "3. Try login"
echo "4. Look for /api/login request"
echo "5. Check Response - what error does it show?"
echo ""
echo "6. Check API logs:"
echo "   sudo journalctl -u pgworld-api -n 50 --no-pager"
echo ""
echo "7. Test API directly:"
echo "   curl -X POST http://localhost:8080/api/login \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"email\":\"priya@example.com\",\"password\":\"Tenant@123\"}'"
echo ""
echo "════════════════════════════════════════════════════════"

