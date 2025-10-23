#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING API LOGIN - Complete Fix with Imports"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

# Backup
BACKUP_DIR="/home/ec2-user/pgni/backups/api_complete_$(date +%s)"
mkdir -p "$BACKUP_DIR"
cp main.go "$BACKUP_DIR/"
cp user.go "$BACKUP_DIR/"

echo "✓ Backed up to $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Check and fix imports in user.go"
echo "════════════════════════════════════════════════════════"

# Check if database/sql is imported
if ! grep -q '"database/sql"' user.go; then
    echo "Adding database/sql import..."
    sed -i '/^import (/a\    "database/sql"' user.go
    echo "✓ Added database/sql"
fi

# Check if encoding/json is imported
if ! grep -q '"encoding/json"' user.go; then
    echo "Adding encoding/json import..."
    sed -i '/^import (/a\    "encoding/json"' user.go
    echo "✓ Added encoding/json"
fi

echo "✓ Imports verified"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Add Login function to user.go"
echo "════════════════════════════════════════════════════════"

# Remove any existing Login function
sed -i '/^func Login/,/^}/d' user.go

# Add Login function at the end
cat >> user.go << 'EOFLOGIN'

// Login - Handle user login
func Login(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    
    // Parse request body
    var loginReq struct {
        Email    string `json:"email"`
        Password string `json:"password"`
    }
    
    err := json.NewDecoder(r.Body).Decode(&loginReq)
    if err != nil {
        json.NewEncoder(w).Encode(map[string]interface{}{
            "meta": map[string]interface{}{
                "status": 400,
                "message": "Invalid request body",
                "messageType": "error",
            },
        })
        return
    }
    
    // Query database for user
    query := `SELECT id, hostelID, name, email, phone, role 
              FROM users 
              WHERE email = ? AND password = ? AND status = 'active'`
    
    var user struct {
        ID       string
        HostelID string
        Name     string
        Email    string
        Phone    string
        Role     string
    }
    
    err = db.QueryRow(query, loginReq.Email, loginReq.Password).Scan(
        &user.ID,
        &user.HostelID,
        &user.Name,
        &user.Email,
        &user.Phone,
        &user.Role,
    )
    
    if err != nil {
        if err == sql.ErrNoRows {
            json.NewEncoder(w).Encode(map[string]interface{}{
                "meta": map[string]interface{}{
                    "status": 401,
                    "message": "Invalid email or password",
                    "messageType": "error",
                },
            })
        } else {
            json.NewEncoder(w).Encode(map[string]interface{}{
                "meta": map[string]interface{}{
                    "status": 500,
                    "message": "Database error",
                    "messageType": "error",
                },
            })
        }
        return
    }
    
    // Success response
    json.NewEncoder(w).Encode(map[string]interface{}{
        "meta": map[string]interface{}{
            "status": 200,
            "message": "Login successful",
            "messageType": "success",
        },
        "data": map[string]interface{}{
            "user": map[string]interface{}{
                "id":       user.ID,
                "hostelID": user.HostelID,
                "name":     user.Name,
                "email":    user.Email,
                "phone":    user.Phone,
                "role":     user.Role,
            },
        },
    })
}
EOFLOGIN

echo "✓ Added Login function"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Register /login route in main.go"
echo "════════════════════════════════════════════════════════"

# Remove any existing login routes
sed -i '/HandleFunc("\/login"/d' main.go

# Find where to add it (look for the first router.HandleFunc)
LINE_NUM=$(grep -n "router.HandleFunc" main.go | head -1 | cut -d: -f1)

if [ ! -z "$LINE_NUM" ]; then
    # Add login route before first HandleFunc
    sed -i "${LINE_NUM}i\\    // Login endpoint" main.go
    sed -i "$((LINE_NUM+1))i\\    router.HandleFunc(\"/login\", Login).Methods(\"POST\")" main.go
    sed -i "$((LINE_NUM+2))i\\" main.go
    echo "✓ Added /login route"
else
    echo "❌ Could not find insertion point"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Verify imports in user.go"
echo "════════════════════════════════════════════════════════"

echo "Current imports in user.go:"
sed -n '/^import (/,/^)/p' user.go

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Build API"
echo "════════════════════════════════════════════════════════"

echo "Running go build..."
if go build -o /opt/pgworld/pgworld-api; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    echo ""
    echo "Build errors:"
    go build 2>&1 | head -20
    echo ""
    echo "Restoring backup..."
    cp "$BACKUP_DIR/main.go" main.go
    cp "$BACKUP_DIR/user.go" user.go
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Restart API"
echo "════════════════════════════════════════════════════════"

sudo systemctl restart pgworld-api
sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ API service running"
else
    echo "❌ API failed to start"
    sudo journalctl -u pgworld-api -n 20 --no-pager
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Create/Verify Test User"
echo "════════════════════════════════════════════════════════"

# Get DB credentials
if [ -f "config.go" ]; then
    DB_HOST=$(grep -A 10 "database" config.go | grep host | cut -d'"' -f2 || echo "localhost")
    DB_NAME=$(grep -A 10 "database" config.go | grep dbname | cut -d'"' -f2 || echo "pgworld")
    DB_USER=$(grep -A 10 "database" config.go | grep user | cut -d'"' -f2 || echo "root")
    DB_PASS=$(grep -A 10 "database" config.go | grep password | cut -d'"' -f2)
fi

if [ -z "$DB_NAME" ]; then DB_NAME="pgworld"; fi
if [ -z "$DB_USER" ]; then DB_USER="root"; fi

echo "Database: $DB_NAME"

if [ ! -z "$DB_PASS" ]; then
    echo "Checking for test user..."
    
    USER_COUNT=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM users WHERE email='priya@example.com'" 2>/dev/null || echo "0")
    
    if [ "$USER_COUNT" = "0" ]; then
        echo "Creating test user..."
        
        # Get a hostel ID
        HOSTEL_ID=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
            "SELECT id FROM hostels LIMIT 1" 2>/dev/null)
        
        if [ ! -z "$HOSTEL_ID" ]; then
            mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOFSQL
INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdDateTime, modifiedDateTime)
VALUES (
    UUID(),
    '$HOSTEL_ID',
    'Priya Sharma',
    'priya@example.com',
    '9876543210',
    'Tenant@123',
    'tenant',
    'active',
    NOW(),
    NOW()
);
EOFSQL
            echo "✅ Created user: priya@example.com / Tenant@123"
        else
            echo "⚠️  No hostels found, creating one first..."
            mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOFSQL
INSERT INTO hostels (id, name, phone, email, address, status, createdDateTime, modifiedDateTime)
VALUES (UUID(), 'Test Hostel', '1234567890', 'admin@test.com', 'Test Address', 'active', NOW(), NOW());

INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdDateTime, modifiedDateTime)
VALUES (
    UUID(),
    (SELECT id FROM hostels WHERE name='Test Hostel'),
    'Priya Sharma',
    'priya@example.com',
    '9876543210',
    'Tenant@123',
    'tenant',
    'active',
    NOW(),
    NOW()
);
EOFSQL
            echo "✅ Created hostel and user"
        fi
    else
        echo "✅ User already exists"
    fi
else
    echo "⚠️  DB password not found, skipping user creation"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Test Login Endpoint"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing: POST http://localhost:8080/login"

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $HTTP_CODE"
echo ""
echo "Response:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

echo ""
echo "Testing via Nginx proxy: POST http://localhost/api/login"

PROXY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

PROXY_CODE=$(echo "$PROXY_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
PROXY_BODY=$(echo "$PROXY_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $PROXY_CODE"
echo ""
echo "Response:"
echo "$PROXY_BODY" | jq . 2>/dev/null || echo "$PROXY_BODY"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "════════════════════════════════════════════════════════"

if [ "$PROXY_CODE" = "200" ]; then
    echo ""
    echo "🎉 SUCCESS! Login endpoint works!"
    echo ""
    echo "✅ /login endpoint created"
    echo "✅ API rebuilt and running"
    echo "✅ Nginx proxy configured"
    echo "✅ User account ready"
    echo ""
    echo "🌐 Access your app:"
    echo "   http://54.227.101.30/tenant/"
    echo ""
    echo "📧 Login credentials:"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo ""
    echo "⚠️  IMPORTANT: Clear browser cache!"
    echo "   Ctrl+Shift+Delete → Clear all → Try login"
    echo ""
elif [ "$PROXY_CODE" = "401" ]; then
    echo ""
    echo "⚠️  Endpoint works but credentials invalid"
    echo ""
    echo "Check database:"
    echo "  mysql -u root -p"
    echo "  USE pgworld;"
    echo "  SELECT email, password, role, status FROM users WHERE email='priya@example.com';"
elif [ "$PROXY_CODE" = "404" ]; then
    echo ""
    echo "❌ Still 404 - checking configuration..."
    echo ""
    echo "Registered routes:"
    grep -n "HandleFunc.*login" main.go
else
    echo ""
    echo "❌ Unexpected result: HTTP $PROXY_CODE"
    echo ""
    echo "Debug commands:"
    echo "  sudo journalctl -u pgworld-api -f"
    echo "  sudo tail -f /var/log/nginx/error.log"
fi

echo ""
echo "════════════════════════════════════════════════════════"

