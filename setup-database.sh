#!/bin/bash

# PGNI Database Setup Script
# Usage: ./setup-database.sh <rds-endpoint> <db-user> <db-password>

set -e

echo "💾 PGNI Database Setup Script"
echo "=============================="

# Check arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: ./setup-database.sh <RDS_ENDPOINT> <DB_USER> <DB_PASSWORD>"
    echo "Example: ./setup-database.sh mydb.123456.us-east-1.rds.amazonaws.com admin mypassword"
    exit 1
fi

RDS_ENDPOINT=$1
DB_USER=$2
DB_PASSWORD=$3
DB_NAME="pgworld"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "${YELLOW}Creating RBAC tables...${NC}"

# Create SQL file
cat > /tmp/rbac_setup.sql << 'EOF'
-- Create admin_permissions table if not exists
CREATE TABLE IF NOT EXISTS admin_permissions (
  id VARCHAR(12) PRIMARY KEY,
  admin_id VARCHAR(12) NOT NULL,
  hostel_id VARCHAR(12) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'manager',
  can_view_dashboard BOOLEAN DEFAULT FALSE,
  can_manage_rooms BOOLEAN DEFAULT FALSE,
  can_manage_tenants BOOLEAN DEFAULT FALSE,
  can_manage_bills BOOLEAN DEFAULT FALSE,
  can_view_financials BOOLEAN DEFAULT FALSE,
  can_manage_employees BOOLEAN DEFAULT FALSE,
  can_view_reports BOOLEAN DEFAULT FALSE,
  can_manage_notices BOOLEAN DEFAULT FALSE,
  can_manage_issues BOOLEAN DEFAULT FALSE,
  can_manage_payments BOOLEAN DEFAULT FALSE,
  assigned_by VARCHAR(12) NOT NULL,
  status ENUM('0', '1') DEFAULT '1',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_admin_id (admin_id),
  INDEX idx_hostel_id (hostel_id),
  INDEX idx_status (status),
  FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
  FOREIGN KEY (hostel_id) REFERENCES hostels(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add role column to admins table if not exists
ALTER TABLE admins 
  ADD COLUMN IF NOT EXISTS role ENUM('owner', 'manager') DEFAULT 'owner',
  ADD COLUMN IF NOT EXISTS parent_admin_id VARCHAR(12) NULL,
  ADD COLUMN IF NOT EXISTS assigned_hostel_ids TEXT NULL,
  ADD INDEX IF NOT EXISTS idx_role (role),
  ADD INDEX IF NOT EXISTS idx_parent_admin_id (parent_admin_id);

-- Update existing admins to be owners
UPDATE admins SET role = 'owner' WHERE role IS NULL;

-- Show tables
SHOW TABLES LIKE '%admin%';

-- Verify structure
DESCRIBE admin_permissions;
DESCRIBE admins;

-- Count records
SELECT COUNT(*) as admin_permissions_count FROM admin_permissions;
SELECT COUNT(*) as admins_count FROM admins;

EOF

echo "Connecting to database and running migrations..."
mysql -h "$RDS_ENDPOINT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /tmp/rbac_setup.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "${GREEN}✅ Database setup complete!${NC}"
    echo ""
    echo "Tables created:"
    echo "  - admin_permissions (RBAC permissions)"
    echo "  - admins (updated with role column)"
    echo ""
    echo "To verify:"
    echo "  mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_NAME -e 'SHOW TABLES;'"
else
    echo "${RED}❌ Database setup failed${NC}"
    exit 1
fi

# Cleanup
rm /tmp/rbac_setup.sql

echo ""
echo "Next steps:"
echo "1. Update .env file on EC2 with database credentials"
echo "2. Restart backend: sudo systemctl restart pgworld-api"
echo "3. Test API connection to database"

