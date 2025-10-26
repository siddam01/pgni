-- ============================================
-- PG Owner Onboarding - Database Migration (MySQL Compatible)
-- Version: 1.0 FIXED
-- Date: December 19, 2024
-- ============================================

USE pgworld;

-- ============================================
-- 1. ENHANCE ADMINS TABLE (Owner/Manager)
-- ============================================

-- MySQL doesn't support ADD COLUMN IF NOT EXISTS
-- We'll use a stored procedure to check and add columns

DELIMITER $$

CREATE PROCEDURE AddColumnIfNotExists(
    IN tableName VARCHAR(64),
    IN columnName VARCHAR(64),
    IN columnDefinition VARCHAR(255)
)
BEGIN
    DECLARE columnExists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO columnExists 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = tableName 
    AND COLUMN_NAME = columnName;
    
    IF columnExists = 0 THEN
        SET @sql = CONCAT('ALTER TABLE ', tableName, ' ADD COLUMN ', columnName, ' ', columnDefinition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- Now add columns using the procedure
CALL AddColumnIfNotExists('admins', 'role', 'VARCHAR(20) DEFAULT "owner" COMMENT "owner, manager"');
CALL AddColumnIfNotExists('admins', 'gstin', 'VARCHAR(20) COMMENT "GST Identification Number"');
CALL AddColumnIfNotExists('admins', 'pan', 'VARCHAR(20) COMMENT "PAN Card Number"');
CALL AddColumnIfNotExists('admins', 'kyc_status', 'VARCHAR(1) DEFAULT "0" COMMENT "0=pending, 1=verified, 2=rejected"');
CALL AddColumnIfNotExists('admins', 'kyc_documents', 'TEXT COMMENT "JSON: KYC document URLs"');
CALL AddColumnIfNotExists('admins', 'assigned_hostel_ids', 'TEXT COMMENT "For managers: comma-separated hostel IDs"');
CALL AddColumnIfNotExists('admins', 'parent_admin_id', 'VARCHAR(50) COMMENT "For managers: owner admin ID"');
CALL AddColumnIfNotExists('admins', 'payout_enabled', 'BOOLEAN DEFAULT FALSE');
CALL AddColumnIfNotExists('admins', 'business_name', 'VARCHAR(200) COMMENT "Business/Company name"');
CALL AddColumnIfNotExists('admins', 'business_address', 'TEXT COMMENT "Registered business address"');

-- Drop the helper procedure
DROP PROCEDURE IF EXISTS AddColumnIfNotExists;

-- Add indexes if not exist (using error suppression)
SET @sql = 'CREATE INDEX idx_role ON admins(role)';
SET @ignore_error = (SELECT IF(
    (SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admins' AND INDEX_NAME = 'idx_role') = 0,
    @sql, 'SELECT 1'));
PREPARE stmt FROM @ignore_error;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 2. PAYMENT GATEWAYS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS payment_gateways (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL COMMENT 'Owner admin ID',
    hostel_id VARCHAR(50) COMMENT 'Specific property, NULL = all properties',
    gateway_type VARCHAR(20) NOT NULL COMMENT 'razorpay, phonepe, paytm',
    
    api_key_encrypted TEXT NOT NULL COMMENT 'Encrypted API key',
    api_secret_encrypted TEXT COMMENT 'Encrypted API secret',
    merchant_id VARCHAR(100) COMMENT 'Merchant ID for gateway',
    encryption_iv VARCHAR(100) COMMENT 'Initialization vector for decryption',
    
    qr_code_url TEXT COMMENT 'Generated QR code image URL',
    payment_link TEXT COMMENT 'UPI payment link',
    upi_id VARCHAR(100) COMMENT 'UPI ID for payments',
    
    kyc_verified BOOLEAN DEFAULT FALSE,
    payout_enabled BOOLEAN DEFAULT FALSE,
    webhook_secret VARCHAR(100) COMMENT 'Webhook verification secret',
    
    auto_capture BOOLEAN DEFAULT TRUE COMMENT 'Auto-capture payments',
    settlement_days INT DEFAULT 1 COMMENT 'Settlement period in days',
    
    status VARCHAR(1) DEFAULT '1' COMMENT '1=active, 0=inactive',
    verified_at TIMESTAMP NULL,
    last_used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_gateway_type (gateway_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- 3. ADMIN PERMISSIONS TABLE (RBAC)
-- ============================================

CREATE TABLE IF NOT EXISTS admin_permissions (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL COMMENT 'Admin/Manager ID',
    hostel_id VARCHAR(50) NOT NULL COMMENT 'Property ID',
    role VARCHAR(20) NOT NULL COMMENT 'owner, manager',
    
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
    
    permissions_json JSON COMMENT 'Additional custom permissions',
    
    assigned_by VARCHAR(50) COMMENT 'Owner who assigned this',
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_role (role),
    UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- 4. KYC DOCUMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS kyc_documents (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    
    document_type VARCHAR(50) NOT NULL COMMENT 'pan, gstin, aadhar, address_proof, bank_statement',
    document_number VARCHAR(100) COMMENT 'Document identification number',
    document_url TEXT NOT NULL COMMENT 'S3 URL of uploaded document',
    
    verification_status VARCHAR(20) DEFAULT 'pending' COMMENT 'pending, verified, rejected',
    verified_by VARCHAR(50) COMMENT 'Admin who verified',
    verified_at TIMESTAMP NULL,
    rejection_reason TEXT,
    
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE COMMENT 'Document expiry if applicable',
    
    INDEX idx_admin_id (admin_id),
    INDEX idx_document_type (document_type),
    INDEX idx_verification_status (verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

SELECT 'Database migration completed successfully!' AS Status;

