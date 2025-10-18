#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 SIMPLE FIX - Update DB Connection Only"
echo "════════════════════════════════════════════════════════"

cd /home/ec2-user/pgni/pgworld-api-master

# RDS credentials
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_NAME="database-PGNi"
DB_USER="admin"
DB_PASS="Omsairamdb951#"

echo ""
echo "Target Database:"
echo "  $DB_HOST/$DB_NAME"
echo ""

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Restore original config.go from backup"
echo "════════════════════════════════════════════════════════"

# Find original backup (before viper changes)
ORIGINAL_BACKUP=$(ls -t config.go.backup.* 2>/dev/null | tail -1)

if [ ! -z "$ORIGINAL_BACKUP" ]; then
    echo "Restoring from: $ORIGINAL_BACKUP"
    cp "$ORIGINAL_BACKUP" config.go
    echo "✓ Restored original config.go"
else
    echo "⚠️  No backup found"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Find and update database connection in main.go"
echo "════════════════════════════════════════════════════════"

# Backup main.go
cp main.go main.go.backup.dbfix.$(date +%s)

# Find the database connection string and update it
# Look for patterns like: db, err = sql.Open("mysql", "...")

if grep -q 'sql.Open.*mysql' main.go; then
    echo "Found database connection in main.go"
    
    # Create the new connection string
    NEW_DSN="${DB_USER}:${DB_PASS}@tcp(${DB_HOST}:3306)/${DB_NAME}?parseTime=true"
    
    # Update the connection string
    # This handles various formats
    sed -i "s|sql.Open(\"mysql\",.*)|sql.Open(\"mysql\", \"${NEW_DSN}\")|" main.go
    
    echo "✓ Updated database connection"
    echo ""
    echo "New connection:"
    grep "sql.Open" main.go | head -1
else
    echo "⚠️  Could not find sql.Open in main.go"
    echo ""
    echo "Searching for database initialization..."
    grep -n "database\|db\|sql" main.go | head -10
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Build API"
echo "════════════════════════════════════════════════════════"

echo "Building..."
if go build -o /opt/pgworld/pgworld-api; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed with updated connection"
    echo ""
    echo "Let's check what's in the original code..."
    echo ""
    echo "Checking config.go structure..."
    head -50 config.go
    echo ""
    echo "Checking main.go DB init..."
    grep -A 10 -B 5 "sql.Open\|database" main.go | head -30
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Restart and Test"
echo "════════════════════════════════════════════════════════"

sudo systemctl restart pgworld-api
sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ API running"
else
    echo "❌ API failed"
    sudo journalctl -u pgworld-api -n 30 --no-pager
    exit 1
fi

echo ""
echo "Testing login..."
RESPONSE=$(curl -s -X POST http://localhost/api/login \
    -H "Content-Type: application/json" \
    -H "X-API-Key: mrk-1b96d9eeccf649e695ed6ac2b13cb619" \
    -d '{"email":"priya@example.com","password":"Tenant@123"}')

echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"status": 200'; then
    echo ""
    echo "🎉🎉🎉 SUCCESS! 🎉🎉🎉"
    echo ""
    echo "✅ Database connected"
    echo "✅ Login working"
    echo ""
    echo "🌐 http://54.227.101.30/tenant/"
    echo "📧 priya@example.com / Tenant@123"
    echo ""
    echo "Clear browser cache and login!"
elif echo "$RESPONSE" | grep -q "Database error"; then
    echo ""
    echo "⚠️  Still database error"
    echo "Check API logs: sudo journalctl -u pgworld-api -n 50"
else
    echo ""
    echo "Response: $RESPONSE"
fi

echo ""
echo "════════════════════════════════════════════════════════"

