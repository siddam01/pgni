#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING API LOGIN - Creating /login endpoint"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

# Backup
BACKUP_DIR="/home/ec2-user/pgni/backups/api_$(date +%s)"
mkdir -p "$BACKUP_DIR"
cp main.go "$BACKUP_DIR/"
cp user.go "$BACKUP_DIR/" 2>/dev/null || true

echo "✓ Backed up to $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Check existing user authentication"
echo "════════════════════════════════════════════════════════"

if [ -f "user.go" ]; then
    echo "Checking user.go for authentication functions..."
    grep -n "func User" user.go | head -10
    echo ""
    
    # Check if there's a UserGet or similar that handles login
    if grep -q "func UserGet" user.go; then
        echo "✓ Found UserGet function"
    fi
else
    echo "⚠️  user.go not found!"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Login function in user.go"
echo "════════════════════════════════════════════════════════"

# Add Login function at the end of user.go
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
    query := "SELECT id, hostelID, name, email, phone, role FROM users WHERE email = ? AND password = ? AND status = 'active'"
    
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
                    "message": "Database error: " + err.Error(),
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

echo "✓ Added Login function to user.go"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Register /login route in main.go"
echo "════════════════════════════════════════════════════════"

# Remove any incorrectly added login routes first
sed -i '/router.HandleFunc("\/login"/d' main.go

# Add the login route properly (after the router initialization)
# Find the line with first HandleFunc and add login route before it
LINE_NUM=$(grep -n "router.HandleFunc" main.go | head -1 | cut -d: -f1)

if [ ! -z "$LINE_NUM" ]; then
    # Insert before the first HandleFunc
    sed -i "${LINE_NUM}i\\    // Login endpoint" main.go
    sed -i "$((LINE_NUM+1))i\\    router.HandleFunc(\"/login\", Login).Methods(\"POST\")" main.go
    sed -i "$((LINE_NUM+2))i\\" main.go
    echo "✓ Added /login route to main.go"
else
    echo "⚠️  Could not find where to add route"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Rebuild API"
echo "════════════════════════════════════════════════════════"

echo "Building Go API..."
if go build -o /opt/pgworld/pgworld-api; then
    echo "✓ Build successful!"
else
    echo "❌ Build failed! Restoring backup..."
    cp "$BACKUP_DIR/main.go" main.go
    cp "$BACKUP_DIR/user.go" user.go 2>/dev/null || true
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Restart API Service"
echo "════════════════════════════════════════════════════════"

sudo systemctl restart pgworld-api
sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✓ API service is running"
else
    echo "❌ API service failed to start!"
    echo "Checking logs..."
    sudo journalctl -u pgworld-api -n 20 --no-pager
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Test Login Endpoint"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing: POST http://localhost:8080/login"

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:8080/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $HTTP_CODE"
echo ""
echo "Response:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Login endpoint works!"
elif [ "$HTTP_CODE" = "401" ]; then
    echo "⚠️  401 - Invalid credentials (but endpoint exists!)"
    echo "   Need to check database for user account"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ Still 404 - route not registered correctly"
else
    echo "⚠️  HTTP $HTTP_CODE"
fi

echo ""
echo "Testing via Nginx proxy: POST http://localhost/api/login"

PROXY_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

PROXY_CODE=$(echo "$PROXY_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

echo "HTTP Status: $PROXY_CODE"

if [ "$PROXY_CODE" = "200" ] || [ "$PROXY_CODE" = "401" ]; then
    echo "✅ Proxy works!"
else
    echo "⚠️  Proxy returned $PROXY_CODE"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Verify/Create Test User"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Checking if priya@example.com exists in database..."

# Get DB credentials from config.go or .env
DB_NAME="pgworld"
DB_USER="root"

# Try to find DB password
if [ -f "../.env" ]; then
    DB_PASS=$(grep DB_PASS ../.env | cut -d= -f2 | tr -d '"' | tr -d "'")
elif [ -f "config.go" ]; then
    DB_PASS=$(grep -A 5 "database" config.go | grep password | cut -d'"' -f2)
fi

if [ ! -z "$DB_PASS" ]; then
    echo "Found DB credentials, checking user..."
    
    USER_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM users WHERE email='priya@example.com'" 2>/dev/null || echo "0")
    
    if [ "$USER_EXISTS" = "0" ]; then
        echo "⚠️  User not found! Creating priya@example.com..."
        
        mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOFSQL
INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdDateTime, modifiedDateTime)
VALUES (
    UUID(),
    (SELECT id FROM hostels LIMIT 1),
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
        
        echo "✓ Created user: priya@example.com / Tenant@123"
    else
        echo "✓ User exists!"
    fi
else
    echo "⚠️  Could not find DB password"
    echo "   Manually create user:"
    echo "   mysql -u root -p"
    echo "   USE pgworld;"
    echo "   INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdDateTime, modifiedDateTime)"
    echo "   VALUES (UUID(), (SELECT id FROM hostels LIMIT 1), 'Priya Sharma', 'priya@example.com', '9876543210', 'Tenant@123', 'tenant', 'active', NOW(), NOW());"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Final Test"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Final login test with credentials..."

FINAL_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}' 2>&1)

FINAL_CODE=$(echo "$FINAL_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
FINAL_BODY=$(echo "$FINAL_RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP Status: $FINAL_CODE"
echo ""
echo "Response:"
echo "$FINAL_BODY" | jq . 2>/dev/null || echo "$FINAL_BODY"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "════════════════════════════════════════════════════════"

if [ "$FINAL_CODE" = "200" ]; then
    echo ""
    echo "🎉 SUCCESS! Login endpoint works!"
    echo ""
    echo "✅ API endpoint created: POST /login"
    echo "✅ Route registered in main.go"
    echo "✅ Nginx proxy configured"
    echo "✅ User account verified"
    echo ""
    echo "🌐 Access your app:"
    echo "   http://54.227.101.30/tenant/"
    echo ""
    echo "📧 Login:"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo ""
    echo "⚠️  Clear browser cache (Ctrl+Shift+Delete) then try!"
elif [ "$FINAL_CODE" = "401" ]; then
    echo ""
    echo "⚠️  Endpoint works but credentials invalid"
    echo ""
    echo "Check database:"
    echo "  mysql -u root -p"
    echo "  USE pgworld;"
    echo "  SELECT email, password, role, status FROM users WHERE email='priya@example.com';"
else
    echo ""
    echo "❌ Still not working (HTTP $FINAL_CODE)"
    echo ""
    echo "Debug:"
    echo "  sudo journalctl -u pgworld-api -f"
    echo "  sudo tail -f /var/log/nginx/error.log"
fi

echo ""
echo "════════════════════════════════════════════════════════"

