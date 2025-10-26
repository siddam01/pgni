-- ============================================
-- PG/Hostel Management - Safe Database Setup
-- Compatible with All MySQL Versions
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

-- ============================================
-- Create admin_permissions table (RBAC)
-- ============================================
CREATE TABLE IF NOT EXISTS admin_permissions (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL COMMENT 'Admin/Manager ID',
    hostel_id VARCHAR(50) NOT NULL COMMENT 'Property ID',
    role VARCHAR(20) NOT NULL DEFAULT 'manager' COMMENT 'owner or manager',
    
    -- 10 Granular Permissions
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
    
    -- Metadata
    assigned_by VARCHAR(50) COMMENT 'Owner who assigned permissions',
    status VARCHAR(1) DEFAULT '1' COMMENT '1=active, 0=inactive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_role (role),
    INDEX idx_status (status),
    UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Role-based access control for admins';

-- ============================================
-- Verification
-- ============================================
SELECT '✅ Database migration completed successfully!' AS Status;

-- Show what was created/updated
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    COLUMN_DEFAULT, 
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'admins' 
  AND COLUMN_NAME IN ('role', 'parent_admin_id', 'assigned_hostel_ids')
ORDER BY ORDINAL_POSITION;

SELECT 
    COUNT(*) AS admin_permissions_table_exists
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'admin_permissions';

-- ============================================
-- End of Migration
-- ============================================

