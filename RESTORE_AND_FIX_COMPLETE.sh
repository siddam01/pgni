#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 COMPLETE API FIX - Restoring Original + DB Config"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Find and restore original config.go"
echo "════════════════════════════════════════════════════════"

# Find the most recent backup before our changes
LATEST_BACKUP=$(ls -t config.go.backup.* 2>/dev/null | head -1)

if [ ! -z "$LATEST_BACKUP" ]; then
    echo "Found backup: $LATEST_BACKUP"
    cp "$LATEST_BACKUP" config.go.original
    echo "✓ Restored original config"
else
    echo "⚠️  No backup found, config.go might be corrupted"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Update ONLY database settings in config.go"
echo "════════════════════════════════════════════════════════"

# Read original config and update only database section
if [ -f "config.go.original" ]; then
    # Use the original but update database settings
    sed -i 's/"host": *"[^"]*"/"host": "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"/g' config.go.original
    sed -i 's/"user": *"[^"]*"/"user": "admin"/g' config.go.original
    sed -i 's/"password": *"[^"]*"/"password": "Omsairamdb951#"/g' config.go.original
    sed -i 's/"dbname": *"[^"]*"/"dbname": "database-PGNi"/g' config.go.original
    
    cp config.go.original config.go
    echo "✓ Updated database settings only"
else
    echo "Creating minimal config.go with all required constants..."
    cat > config.go << 'EOFCONFIG'
package main

// Database connection string will be set in main.go directly
var (
    // Table names
    adminTable     = "admins"
    userTable      = "users"
    hostelTable    = "hostels"
    roomTable      = "rooms"
    billTable      = "bills"
    issueTable     = "issues"
    noticeTable    = "notices"
    
    // Status codes
    statusCodeOK          = 200
    statusCodeBadRequest  = 400
    statusCodeUnauthorized = 401
    statusCodeNotFound    = 404
    statusCodeServerError = 500
    
    // Dialog types
    dialogType         = "error"
    dialogTypeSuccess  = "success"
    dialogTypeWarning  = "warning"
    
    // Pagination
    defaultLimit  = "10"
    defaultOffset = "0"
    
    // Required fields
    adminRequiredFields  = []string{"email", "password"}
    userRequiredFields   = []string{"email", "password", "name"}
    hostelRequiredFields = []string{"name"}
    roomRequiredFields   = []string{"roomno", "hostelID"}
)
EOFCONFIG
    echo "✓ Created config.go with required constants"
fi

echo ""
echo "Verifying config.go..."
head -20 config.go

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Update main.go database connection"
echo "════════════════════════════════════════════════════════"

# Update main.go to use direct connection string
cat > db_init_snippet.go << 'EOFDB'
package main

import (
    "database/sql"
    "fmt"
    "log"
    _ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

func initDB() error {
    var err error
    
    // RDS Database connection
    dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
        "admin",
        "Omsairamdb951#",
        "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com",
        "3306",
        "database-PGNi")
    
    db, err = sql.Open("mysql", dsn)
    if err != nil {
        return fmt.Errorf("error opening database: %v", err)
    }
    
    // Test connection
    err = db.Ping()
    if err != nil {
        return fmt.Errorf("error connecting to database: %v", err)
    }
    
    log.Println("✅ Connected to RDS database successfully")
    return nil
}
EOFDB

echo "✓ Created DB initialization snippet"

# Check if main.go has initDB function
if ! grep -q "func initDB" main.go; then
    echo "Adding initDB to main.go..."
    cat db_init_snippet.go >> main.go
    
    # Add initDB call to main function
    sed -i '/func main/a\    if err := initDB(); err != nil {\n        log.Fatal("Database initialization failed:", err)\n    }' main.go
    
    echo "✓ Added initDB to main.go"
else
    echo "✓ initDB already exists"
fi

rm -f db_init_snippet.go

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Ensure all dependencies"
echo "════════════════════════════════════════════════════════"

echo "Installing mysql driver..."
go get github.com/go-sql-driver/mysql

echo ""
echo "Resolving all dependencies..."
go mod tidy

echo "✓ Dependencies ready"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Build API"
echo "════════════════════════════════════════════════════════"

echo "Building..."
if go build -o /opt/pgworld/pgworld-api 2>&1 | tee /tmp/build.log; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    echo ""
    echo "Build errors:"
    cat /tmp/build.log | head -20
    echo ""
    echo "This might be due to missing original code."
    echo "Let's try a simpler approach..."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Restart and Test"
echo "════════════════════════════════════════════════════════"

sudo systemctl restart pgworld-api
sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ API running"
else
    echo "❌ API failed to start"
    sudo journalctl -u pgworld-api -n 20 --no-pager
    exit 1
fi

echo ""
echo "Testing login..."
sleep 2

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost/api/login \
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
echo "════════════════════════════════════════════════════════"

if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q '"status": 200'; then
    echo "🎉 SUCCESS! Login works!"
    echo ""
    echo "🌐 http://54.227.101.30/tenant/"
    echo "📧 priya@example.com / Tenant@123"
else
    echo "⚠️  Still issues. Check logs:"
    echo "sudo journalctl -u pgworld-api -f"
fi

echo "════════════════════════════════════════════════════════"

