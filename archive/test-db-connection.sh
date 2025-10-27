#!/bin/bash

#############################################################
# Database Connection Test Script
# Tests MySQL connection with special character passwords
#############################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "Testing MySQL Database Connection"
echo "================================================"
echo ""

# Load config
if [ -f ~/.pgni-config ]; then
    source ~/.pgni-config
    echo -e "${GREEN}Config loaded from ~/.pgni-config${NC}"
    echo "RDS Endpoint: $RDS_ENDPOINT"
    echo "DB User: $DB_USER"
    echo "DB Name: $DB_NAME"
    echo ""
else
    echo -e "${RED}Config file not found!${NC}"
    exit 1
fi

# Get password securely
echo -e "${YELLOW}Enter your database password:${NC}"
read -s DB_PASSWORD
echo ""

# Test 1: Basic connection
echo "Test 1: Basic MySQL connection..."
mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1 AS test;" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Connection successful!${NC}"
    echo ""
    
    # Test 2: Database access
    echo "Test 2: Accessing database '$DB_NAME'..."
    mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME; SELECT DATABASE();" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database access successful!${NC}"
        echo ""
        
        # Test 3: Check existing tables
        echo "Test 3: Checking existing tables..."
        mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" 2>&1
        
        echo ""
        echo -e "${GREEN}================================================"
        echo "✅ All tests passed! Database is ready."
        echo "================================================${NC}"
        echo ""
        echo "You can now run the deployment script."
        
    else
        echo -e "${RED}❌ Cannot access database '$DB_NAME'${NC}"
        echo ""
        echo "Creating database..."
        mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Database created successfully!${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Connection failed!${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Verify password is correct"
    echo "2. Check RDS endpoint: $RDS_ENDPOINT"
    echo "3. Verify user has permissions"
    echo "4. Check RDS security group allows connections from this EC2"
    echo ""
    
    # Show detailed error
    echo "Detailed connection test:"
    mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" 2>&1 | grep -i error
fi

echo ""

