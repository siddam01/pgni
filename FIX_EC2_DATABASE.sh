#!/bin/bash
###############################################################################
# CloudPG - Fix EC2 Database Migration
# This script fixes the MySQL syntax error during deployment
###############################################################################

echo "=========================================="
echo "CloudPG - Database Migration Fix"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database credentials (will prompt if not provided)
DB_HOST="${DB_HOST:-database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com}"
DB_USER="${DB_USER:-admin}"
DB_NAME="${DB_NAME:-pgworld}"

# Prompt for password if not set
if [ -z "$DB_PASSWORD" ]; then
    echo -n "Enter Database Password: "
    read -s DB_PASSWORD
    echo ""
fi

echo -e "${BLUE}Testing database connection...${NC}"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Database connection failed!${NC}"
    echo "Please check your credentials and try again."
    exit 1
fi

echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

echo -e "${BLUE}Applying safe database migrations...${NC}"
echo ""

# Create temporary SQL file with safe migrations
cat > /tmp/fix_database.sql << 'EOF'
-- ============================================
-- CloudPG - Safe Database Migration
-- Compatible with MySQL 5.7 and 8.0
-- ============================================

USE pgworld;

-- ============================================
-- Add 'role' column if missing
-- ============================================
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'role'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN role VARCHAR(20) DEFAULT "owner" COMMENT "owner or manager";',
  'SELECT "✓ Column role already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ Role column processed' AS Status;

-- ============================================
-- Add 'parent_admin_id' column if missing
-- ============================================
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'parent_admin_id'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN parent_admin_id VARCHAR(50) NULL COMMENT "For managers: owner admin ID";',
  'SELECT "✓ Column parent_admin_id already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ Parent admin ID column processed' AS Status;

-- ============================================
-- Add 'assigned_hostel_ids' column if missing
-- ============================================
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'assigned_hostel_ids'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN assigned_hostel_ids TEXT NULL COMMENT "For managers: comma-separated hostel IDs";',
  'SELECT "✓ Column assigned_hostel_ids already exists" AS Info;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ Assigned hostel IDs column processed' AS Status;

-- ============================================
-- Create admin_permissions table if not exists
-- ============================================
CREATE TABLE IF NOT EXISTS admin_permissions (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    hostel_id VARCHAR(50) NOT NULL,
    can_view_dashboard BOOLEAN DEFAULT TRUE,
    can_manage_rooms BOOLEAN DEFAULT FALSE,
    can_manage_tenants BOOLEAN DEFAULT FALSE,
    can_manage_bills BOOLEAN DEFAULT FALSE,
    can_view_financials BOOLEAN DEFAULT FALSE,
    can_manage_employees BOOLEAN DEFAULT FALSE,
    can_view_reports BOOLEAN DEFAULT FALSE,
    can_manage_notices BOOLEAN DEFAULT FALSE,
    can_manage_issues BOOLEAN DEFAULT FALSE,
    can_manage_payments BOOLEAN DEFAULT FALSE,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status),
    UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT '✓ Admin permissions table processed' AS Status;

-- ============================================
-- Verify the changes
-- ============================================
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_DEFAULT,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'admins'
  AND COLUMN_NAME IN ('role', 'parent_admin_id', 'assigned_hostel_ids')
ORDER BY ORDINAL_POSITION;

SELECT '========================================' AS '';
SELECT '✅ DATABASE MIGRATION COMPLETED!' AS Status;
SELECT '========================================' AS '';

EOF

# Execute the migration
echo -e "${BLUE}Executing migration...${NC}"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /tmp/fix_database.sql

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✅ DATABASE MIGRATION SUCCESSFUL!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Re-run your deployment script"
    echo "  2. The database is now properly configured"
    echo "  3. All RBAC columns have been added"
    echo ""
    
    # Cleanup
    rm -f /tmp/fix_database.sql
    
    exit 0
else
    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ MIGRATION FAILED${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check the error messages above"
    echo "  2. Verify database credentials"
    echo "  3. Check MySQL version: mysql --version"
    echo "  4. Try running: mysql -h $DB_HOST -u $DB_USER -p"
    echo ""
    
    # Keep SQL file for debugging
    echo -e "${YELLOW}SQL file saved at: /tmp/fix_database.sql${NC}"
    echo "You can manually run it: mysql -h $DB_HOST -u $DB_USER -p $DB_NAME < /tmp/fix_database.sql"
    echo ""
    
    exit 1
fi

