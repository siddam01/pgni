#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 FIXING DATABASE CONFIGURATION"
echo "════════════════════════════════════════════════════════"

# RDS Database credentials (from AWS console)
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_NAME="database-PGNi"
DB_USER="admin"
DB_PASS="Omsairamdb951#"

echo ""
echo "Database Configuration:"
echo "  Host: $DB_HOST"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: ${DB_PASS:0:5}***"
echo ""

cd /home/ec2-user/pgni/pgworld-api-master

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Backup current config.go"
echo "════════════════════════════════════════════════════════"

if [ -f "config.go" ]; then
    cp config.go config.go.backup.$(date +%s)
    echo "✓ Backed up config.go"
else
    echo "⚠️  config.go not found, will create new one"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Update database configuration in config.go"
echo "════════════════════════════════════════════════════════"

# Create or update config.go with correct database settings
cat > config.go << 'EOFCONFIG'
package main

import (
    "github.com/spf13/viper"
)

func initConfig() {
    viper.SetConfigName("config")
    viper.AddConfigPath(".")
    viper.AutomaticEnv()
    viper.SetConfigType("yml")

    if err := viper.ReadInConfig(); err != nil {
        // If config file not found, use defaults
        setDefaults()
    }
}

func setDefaults() {
    // Database configuration
    viper.SetDefault("database.host", "DATABASE_HOST_PLACEHOLDER")
    viper.SetDefault("database.port", "3306")
    viper.SetDefault("database.user", "DATABASE_USER_PLACEHOLDER")
    viper.SetDefault("database.password", "DATABASE_PASS_PLACEHOLDER")
    viper.SetDefault("database.dbname", "DATABASE_NAME_PLACEHOLDER")
    
    // Server configuration
    viper.SetDefault("server.port", "8080")
}
EOFCONFIG

# Replace placeholders
sed -i "s/DATABASE_HOST_PLACEHOLDER/$DB_HOST/g" config.go
sed -i "s/DATABASE_USER_PLACEHOLDER/$DB_USER/g" config.go
sed -i "s/DATABASE_PASS_PLACEHOLDER/$DB_PASS/g" config.go
sed -i "s/DATABASE_NAME_PLACEHOLDER/$DB_NAME/g" config.go

echo "✓ Updated config.go"

echo ""
echo "Verifying config.go content:"
grep -A 5 "database\." config.go | head -10

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Update main.go to use new config"
echo "════════════════════════════════════════════════════════"

# Check if main.go has proper database initialization
if grep -q "viper.GetString" main.go; then
    echo "✓ main.go already uses viper config"
else
    echo "Updating main.go database connection..."
    
    # Backup main.go
    cp main.go main.go.backup.$(date +%s)
    
    # Update the database connection string in main.go
    # Look for the existing db connection and update it
    sed -i 's/db, err = sql.Open("mysql".*/db, err = sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)\/%s?parseTime=true", viper.GetString("database.user"), viper.GetString("database.password"), viper.GetString("database.host"), viper.GetString("database.port"), viper.GetString("database.dbname")))/' main.go
    
    echo "✓ Updated main.go"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Test database connection"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing connection to RDS database..."

if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Database connection successful!"
else
    echo "❌ Cannot connect to database!"
    echo ""
    echo "Possible issues:"
    echo "  1. RDS Security Group not allowing EC2 IP"
    echo "  2. Wrong credentials"
    echo "  3. Database endpoint incorrect"
    echo ""
    echo "Trying with explicit database name..."
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1;" 2>&1 | head -5
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Check/Create database and tables"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Checking if database '$DB_NAME' exists..."

DB_EXISTS=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES LIKE '$DB_NAME';" 2>/dev/null | wc -l)

if [ "$DB_EXISTS" -gt 1 ]; then
    echo "✅ Database exists"
else
    echo "Creating database..."
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
    echo "✅ Database created"
fi

echo ""
echo "Checking tables..."
TABLES=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2)

if [ -z "$TABLES" ]; then
    echo "⚠️  No tables found! Creating basic tables..."
    
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOFSQL'
-- Create hostels table
CREATE TABLE IF NOT EXISTS hostels (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    amenities TEXT,
    status VARCHAR(20) DEFAULT 'active',
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    hostelID VARCHAR(36),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'tenant',
    status VARCHAR(20) DEFAULT 'active',
    address TEXT,
    document TEXT,
    emerContact VARCHAR(255),
    emerPhone VARCHAR(20),
    food VARCHAR(50),
    paymentStatus VARCHAR(50),
    roomID VARCHAR(36),
    roomno VARCHAR(50),
    rent VARCHAR(50),
    joiningDateTime DATETIME,
    lastPaidDateTime DATETIME,
    expiryDateTime DATETIME,
    leaveDateTime DATETIME,
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hostelID) REFERENCES hostels(id) ON DELETE SET NULL
);

-- Create rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(36) PRIMARY KEY,
    hostelID VARCHAR(36),
    roomno VARCHAR(50) NOT NULL,
    rent VARCHAR(50),
    floor VARCHAR(50),
    filled VARCHAR(50) DEFAULT '0',
    capacity VARCHAR(50),
    amenities TEXT,
    status VARCHAR(20) DEFAULT 'active',
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hostelID) REFERENCES hostels(id) ON DELETE CASCADE
);

-- Create bills table
CREATE TABLE IF NOT EXISTS bills (
    id VARCHAR(36) PRIMARY KEY,
    hostelID VARCHAR(36),
    user VARCHAR(36),
    room VARCHAR(36),
    bill TEXT,
    note TEXT,
    paid VARCHAR(20) DEFAULT 'no',
    description TEXT,
    expiryDateTime DATETIME,
    status VARCHAR(20) DEFAULT 'active',
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create issues table
CREATE TABLE IF NOT EXISTS issues (
    id VARCHAR(36) PRIMARY KEY,
    hostelID VARCHAR(36),
    log TEXT,
    \`by\` VARCHAR(36),
    type VARCHAR(100),
    status VARCHAR(20) DEFAULT 'open',
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create notices table
CREATE TABLE IF NOT EXISTS notices (
    id VARCHAR(36) PRIMARY KEY,
    hostelID VARCHAR(36),
    note TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    modifiedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
EOFSQL
    
    echo "✅ Tables created"
else
    echo "✅ Tables exist:"
    echo "$TABLES"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Create test data"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Creating test hostel and user..."

mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOFSQL'
-- Insert test hostel (if not exists)
INSERT INTO hostels (id, name, phone, email, address, amenities, status, createdBy, modifiedBy)
SELECT * FROM (
    SELECT 
        UUID() as id,
        'Sunrise PG Hostel' as name,
        '9876543210' as phone,
        'admin@sunrisepg.com' as email,
        '123 MG Road, Bangalore, Karnataka - 560001' as address,
        'WiFi,AC,Parking,Food,Laundry,Security' as amenities,
        'active' as status,
        'system' as createdBy,
        'system' as modifiedBy
) AS tmp
WHERE NOT EXISTS (
    SELECT email FROM hostels WHERE email = 'admin@sunrisepg.com'
) LIMIT 1;

-- Insert test user (if not exists)
INSERT INTO users (id, hostelID, name, email, phone, password, role, status, createdBy, modifiedBy)
SELECT * FROM (
    SELECT 
        UUID() as id,
        (SELECT id FROM hostels WHERE email='admin@sunrisepg.com' LIMIT 1) as hostelID,
        'Priya Sharma' as name,
        'priya@example.com' as email,
        '9876543210' as phone,
        'Tenant@123' as password,
        'tenant' as role,
        'active' as status,
        'system' as createdBy,
        'system' as modifiedBy
) AS tmp
WHERE NOT EXISTS (
    SELECT email FROM users WHERE email = 'priya@example.com'
) LIMIT 1;
EOFSQL

echo "✅ Test data created"

echo ""
echo "Verifying user exists..."
mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
    "SELECT id, name, email, role, status FROM users WHERE email='priya@example.com';"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 7: Rebuild API with new database config"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Building API..."
if go build -o /opt/pgworld/pgworld-api; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "Restarting API service..."
sudo systemctl restart pgworld-api
sleep 3

if sudo systemctl is-active --quiet pgworld-api; then
    echo "✅ API service running"
else
    echo "❌ API service failed!"
    sudo journalctl -u pgworld-api -n 20 --no-pager
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 8: Test login with real database"
echo "════════════════════════════════════════════════════════"

echo ""
echo "Testing login endpoint..."
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
echo "✅ CONFIGURATION COMPLETE!"
echo "════════════════════════════════════════════════════════"

if [ "$HTTP_CODE" = "200" ] && echo "$BODY" | grep -q '"status": 200'; then
    echo ""
    echo "🎉 SUCCESS! Database connected and login works!"
    echo ""
    echo "✅ Database: RDS connected"
    echo "✅ Tables: Created"
    echo "✅ Test data: Inserted"
    echo "✅ API: Rebuilt and running"
    echo "✅ Login: Working!"
    echo ""
    echo "🌐 Your app is READY:"
    echo "   http://54.227.101.30/tenant/"
    echo ""
    echo "📧 Login credentials:"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo ""
    echo "⚠️  IMPORTANT: Clear browser cache!"
    echo "   Ctrl+Shift+Delete → Clear all"
    echo "   Then go to: http://54.227.101.30/tenant/"
    echo ""
elif echo "$BODY" | grep -q "Database error"; then
    echo ""
    echo "⚠️  Still getting database error"
    echo ""
    echo "Check RDS Security Group:"
    echo "  1. AWS Console → RDS → Your database"
    echo "  2. Connectivity & security → Security group"
    echo "  3. Edit inbound rules"
    echo "  4. Add rule: MySQL/Aurora (3306), Source: EC2 Security Group"
    echo ""
    echo "Check API logs:"
    echo "  sudo journalctl -u pgworld-api -n 50"
else
    echo ""
    echo "⚠️  Unexpected response"
    echo ""
    echo "Debug:"
    echo "  sudo journalctl -u pgworld-api -f"
fi

echo ""
echo "════════════════════════════════════════════════════════"

