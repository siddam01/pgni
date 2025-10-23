#!/bin/bash
# ========================================
# PGNi - Load Test Data into Database
# ========================================
# This script loads test accounts and demo data
# into the RDS database
# ========================================

echo "=========================================="
echo "🚀 PGNi - Loading Test Data"
echo "=========================================="
echo ""

# Configuration
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_PORT="3306"
DB_USER="admin"
DB_PASSWORD="Omsairamdb951#"
DB_NAME="pgworld"

echo "Target Database: $DB_HOST"
echo "Database Name: $DB_NAME"
echo ""

# Check if MySQL client is installed
echo "Step 1: Checking MySQL client..."
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL client not found. Installing..."
    if command -v yum &> /dev/null; then
        sudo yum install -y mysql
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y mysql-client
    else
        echo "❌ Cannot install MySQL client automatically"
        echo "Please install it manually and run this script again"
        exit 1
    fi
else
    echo "✅ MySQL client installed"
fi
echo ""

# Test database connection
echo "Step 2: Testing database connection..."
if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" &> /dev/null; then
    echo "✅ Database connection successful"
else
    echo "❌ Cannot connect to database"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if this instance can access RDS"
    echo "2. Verify security group allows MySQL (port 3306)"
    echo "3. Confirm database credentials are correct"
    exit 1
fi
echo ""

# Download test data SQL file
echo "Step 3: Getting test data SQL file..."
if [ -f "CREATE_TEST_ACCOUNTS.sql" ]; then
    echo "✅ SQL file found locally"
else
    echo "Downloading from GitHub..."
    curl -sS -O https://raw.githubusercontent.com/siddam01/pgni/main/CREATE_TEST_ACCOUNTS.sql
    if [ $? -eq 0 ]; then
        echo "✅ SQL file downloaded"
    else
        echo "❌ Failed to download SQL file"
        exit 1
    fi
fi
echo ""

# Load test data
echo "Step 4: Loading test data into database..."
echo "This may take a moment..."
echo ""

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < CREATE_TEST_ACCOUNTS.sql 2>&1 | grep -v "mysql: \[Warning\]"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Test data loaded successfully!"
else
    echo ""
    echo "⚠️ Some warnings occurred, but data may have loaded"
fi
echo ""

# Verify data was loaded
echo "Step 5: Verifying data..."
echo ""

QUERY="
SELECT 'TEST ACCOUNTS SUMMARY' AS '';
SELECT 
    (SELECT COUNT(*) FROM users) AS 'Total Users',
    (SELECT COUNT(*) FROM pg_properties) AS 'Total Properties',
    (SELECT COUNT(*) FROM rooms) AS 'Total Rooms',
    (SELECT COUNT(*) FROM tenants) AS 'Total Tenants',
    (SELECT COUNT(*) FROM payments) AS 'Total Payments';
"

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$QUERY" 2>&1 | grep -v "mysql: \[Warning\]"

echo ""
echo "=========================================="
echo "✅ TEST DATA LOADED SUCCESSFULLY!"
echo "=========================================="
echo ""
echo "📋 Test Account Credentials:"
echo ""
echo "ADMIN ACCOUNT:"
echo "  Email: admin@pgni.com"
echo "  Password: password123"
echo "  Access: Full system access"
echo ""
echo "PG OWNER ACCOUNT:"
echo "  Email: owner@pgni.com"
echo "  Password: password123"
echo "  Access: Manages properties and tenants"
echo ""
echo "TENANT ACCOUNT:"
echo "  Email: tenant@pgni.com"
echo "  Password: password123"
echo "  Access: Resident access only"
echo ""
echo "=========================================="
echo "🎯 Next Steps:"
echo "=========================================="
echo ""
echo "1. Open Admin App:"
echo "   Double-click: RUN_ADMIN_APP.bat"
echo ""
echo "2. Login with test credentials:"
echo "   Email: admin@pgni.com"
echo "   Password: password123"
echo ""
echo "3. Test all pages:"
echo "   Double-click: TEST_ALL_PAGES.bat"
echo ""
echo "4. View page inventory:"
echo "   Open: UI_PAGES_INVENTORY.md"
echo ""
echo "=========================================="
echo "✨ Your system now has demo data!"
echo "=========================================="
echo ""

