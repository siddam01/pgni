-- ============================================
-- PG/Hostel Management System - Complete Database Setup
-- Simple version without foreign key constraints
-- Compatible with All MySQL Versions
-- ============================================

-- Use the specified database
USE pgworld;

-- ============================================
-- PART 1: Base Schema - Create All Tables
-- ============================================

-- Admins table (base structure)
CREATE TABLE IF NOT EXISTS admins (
    id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    hostel_ids TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hostels table
CREATE TABLE IF NOT EXISTS hostels (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    amenities TEXT,
    document TEXT,
    expiry_date_time DATETIME,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admin_id (admin_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    roomno VARCHAR(50) NOT NULL,
    type VARCHAR(50),
    size VARCHAR(50),
    capacity INT,
    rent DECIMAL(10,2),
    amenities TEXT,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_roomno (roomno),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Users (Tenants) table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    room_id VARCHAR(50),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100),
    address TEXT,
    roomno VARCHAR(50),
    rent DECIMAL(10,2),
    food VARCHAR(500),
    document TEXT,
    emer_contact VARCHAR(100),
    emer_phone VARCHAR(20),
    joining_date_time DATETIME,
    last_paid_date_time DATETIME,
    expiry_date_time DATETIME,
    vacate_date_time DATETIME,
    payment_status VARCHAR(1) DEFAULT '0',
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_room_id (room_id),
    INDEX idx_phone (phone),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bills table
CREATE TABLE IF NOT EXISTS bills (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    bill_date DATETIME,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_type (type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Issues table
CREATE TABLE IF NOT EXISTS issues (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50),
    room_id VARCHAR(50),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    description TEXT,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notices table
CREATE TABLE IF NOT EXISTS notices (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Employees table
CREATE TABLE IF NOT EXISTS employees (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    role VARCHAR(50),
    salary DECIMAL(10,2),
    joining_date DATETIME,
    document TEXT,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- OTP table for tenant authentication
CREATE TABLE IF NOT EXISTS otps (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE,
    INDEX idx_phone (phone),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    hostel_id VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_type VARCHAR(50),
    payment_id VARCHAR(100),
    order_id VARCHAR(100),
    payment_date DATETIME,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Food menu table
CREATE TABLE IF NOT EXISTS food (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2),
    description TEXT,
    type VARCHAR(50),
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT '✅ Base tables created successfully!' AS Status;

-- Show what tables were created
SHOW TABLES;

-- ============================================
-- PART 2: RBAC - Add Role Columns to Admins
-- ============================================

-- Add 'role' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'role'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN role VARCHAR(20) DEFAULT "owner" COMMENT "owner or manager";',
  'SELECT "✓ Column role already exists" AS Info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add 'parent_admin_id' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'parent_admin_id'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN parent_admin_id VARCHAR(50) NULL COMMENT "For managers: owner admin ID";',
  'SELECT "✓ Column parent_admin_id already exists" AS Info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add 'assigned_hostel_ids' column if missing
SET @col_exists := (
  SELECT COUNT(*) 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admins' 
    AND COLUMN_NAME = 'assigned_hostel_ids'
);

SET @sql := IF(@col_exists = 0, 
  'ALTER TABLE admins ADD COLUMN assigned_hostel_ids TEXT NULL COMMENT "For managers: comma-separated hostel IDs";',
  'SELECT "✓ Column assigned_hostel_ids already exists" AS Info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✅ RBAC columns added to admins table!' AS Status;

-- ============================================
-- PART 3: RBAC - Create Permissions Table
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

SELECT '✅ Admin permissions table created!' AS Status;

-- ============================================
-- PART 4: Insert Demo Data (Safe Insert)
-- ============================================

-- Insert demo admin user
INSERT INTO admins (id, username, password, name, email, phone, hostel_ids, role, status) 
VALUES (
    'admin001', 
    'admin', 
    'admin123', 
    'Admin User', 
    'admin@pgworld.com', 
    '9876543210',
    'hostel001',
    'owner',
    '1'
) ON DUPLICATE KEY UPDATE username=username;

SELECT '✅ Demo admin created!' AS Status;

-- Insert demo hostel
INSERT INTO hostels (id, admin_id, name, address, phone, email, amenities, expiry_date_time, status)
VALUES (
    'hostel001',
    'admin001',
    'Demo PG Hostel',
    '123 Main Street, Hyderabad, Telangana, India',
    '9876543210',
    'contact@demopg.com',
    'Wifi,AC,TV,Bathroom,Power Backup,Washing Machine,Geyser,Laundry',
    DATE_ADD(NOW(), INTERVAL 1 YEAR),
    '1'
) ON DUPLICATE KEY UPDATE name=name;

SELECT '✅ Demo hostel created!' AS Status;

-- Insert demo rooms
INSERT INTO rooms (id, hostel_id, roomno, type, size, capacity, rent, amenities, status)
VALUES 
    ('room001', 'hostel001', '101', 'Single', '120 sq ft', 1, 5000.00, 'Wifi,AC,TV,Bathroom', '1'),
    ('room002', 'hostel001', '102', 'Double', '150 sq ft', 2, 4000.00, 'Wifi,Bathroom,Power Backup', '1'),
    ('room003', 'hostel001', '103', 'Triple', '180 sq ft', 3, 3500.00, 'Wifi,Bathroom,TV', '1'),
    ('room004', 'hostel001', '104', 'Single', '120 sq ft', 1, 5500.00, 'Wifi,AC,TV,Bathroom,Geyser', '1')
ON DUPLICATE KEY UPDATE roomno=roomno;

SELECT '✅ Demo rooms created!' AS Status;

-- Insert demo tenant
INSERT INTO users (id, hostel_id, room_id, name, phone, email, address, roomno, rent, joining_date_time, last_paid_date_time, expiry_date_time, payment_status, status)
VALUES (
    'user001',
    'hostel001',
    'room001',
    'John Doe',
    '9123456789',
    'john.doe@email.com',
    '456 Park Avenue, Hyderabad',
    '101',
    5000.00,
    NOW(),
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 DAY),
    '1',
    '1'
) ON DUPLICATE KEY UPDATE name=name;

SELECT '✅ Demo tenant created!' AS Status;

-- ============================================
-- PART 5: Verification
-- ============================================

SELECT '========================================' AS '';
SELECT '✅ DATABASE SETUP COMPLETE!' AS Status;
SELECT '========================================' AS '';

-- Show table counts
SELECT 
    (SELECT COUNT(*) FROM admins) AS Admins,
    (SELECT COUNT(*) FROM hostels) AS Hostels,
    (SELECT COUNT(*) FROM rooms) AS Rooms,
    (SELECT COUNT(*) FROM users) AS Tenants,
    (SELECT COUNT(*) FROM employees) AS Employees,
    (SELECT COUNT(*) FROM bills) AS Bills,
    (SELECT COUNT(*) FROM issues) AS Issues,
    (SELECT COUNT(*) FROM notices) AS Notices,
    (SELECT COUNT(*) FROM payments) AS Payments,
    (SELECT COUNT(*) FROM admin_permissions) AS Permissions;

-- Show RBAC columns in admins table
SELECT '========================================' AS '';
SELECT 'RBAC Columns in Admins Table:' AS '';
SELECT '========================================' AS '';

SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'admins' 
  AND COLUMN_NAME IN ('role', 'parent_admin_id', 'assigned_hostel_ids')
ORDER BY ORDINAL_POSITION;

-- Show demo admin credentials
SELECT '========================================' AS '';
SELECT 'Demo Login Credentials:' AS '';
SELECT '========================================' AS '';

SELECT 
    username AS Username,
    password AS Password,
    role AS Role,
    name AS Name
FROM admins 
WHERE id = 'admin001';

SELECT '========================================' AS '';
SELECT '🚀 Ready to use!' AS Status;
SELECT '========================================' AS '';

-- ============================================
-- End of Setup
-- ============================================

