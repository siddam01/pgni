-- ============================================
-- PG Owner Onboarding - Database Migration
-- Version: 1.0
-- Date: December 19, 2024
-- ============================================

USE pgworld_db;

-- ============================================
-- 1. ENHANCE ADMINS TABLE (Owner/Manager)
-- ============================================

-- Add new columns to admins table
ALTER TABLE admins 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'owner' COMMENT 'owner, manager',
ADD COLUMN IF NOT EXISTS gstin VARCHAR(20) COMMENT 'GST Identification Number',
ADD COLUMN IF NOT EXISTS pan VARCHAR(20) COMMENT 'PAN Card Number',
ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(1) DEFAULT '0' COMMENT '0=pending, 1=verified, 2=rejected',
ADD COLUMN IF NOT EXISTS kyc_documents TEXT COMMENT 'JSON: KYC document URLs',
ADD COLUMN IF NOT EXISTS assigned_hostel_ids TEXT COMMENT 'For managers: comma-separated hostel IDs',
ADD COLUMN IF NOT EXISTS parent_admin_id VARCHAR(50) COMMENT 'For managers: owner admin ID',
ADD COLUMN IF NOT EXISTS payout_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS business_name VARCHAR(200) COMMENT 'Business/Company name',
ADD COLUMN IF NOT EXISTS business_address TEXT COMMENT 'Registered business address';

-- Add indexes
ALTER TABLE admins ADD INDEX IF NOT EXISTS idx_role (role);
ALTER TABLE admins ADD INDEX IF NOT EXISTS idx_gstin (gstin);
ALTER TABLE admins ADD INDEX IF NOT EXISTS idx_pan (pan);
ALTER TABLE admins ADD INDEX IF NOT EXISTS idx_kyc_status (kyc_status);
ALTER TABLE admins ADD INDEX IF NOT EXISTS idx_parent_admin (parent_admin_id);

-- Add foreign key for parent admin
ALTER TABLE admins 
ADD CONSTRAINT fk_parent_admin 
FOREIGN KEY (parent_admin_id) REFERENCES admins(id) 
ON DELETE CASCADE;

-- ============================================
-- 2. PAYMENT GATEWAYS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS payment_gateways (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL COMMENT 'Owner admin ID',
    hostel_id VARCHAR(50) COMMENT 'Specific property, NULL = all properties',
    gateway_type VARCHAR(20) NOT NULL COMMENT 'razorpay, phonepe, paytm',
    
    -- Encrypted credentials
    api_key_encrypted TEXT NOT NULL COMMENT 'Encrypted API key',
    api_secret_encrypted TEXT COMMENT 'Encrypted API secret',
    merchant_id VARCHAR(100) COMMENT 'Merchant ID for gateway',
    encryption_iv VARCHAR(100) COMMENT 'Initialization vector for decryption',
    
    -- Payment details
    qr_code_url TEXT COMMENT 'Generated QR code image URL',
    payment_link TEXT COMMENT 'UPI payment link',
    upi_id VARCHAR(100) COMMENT 'UPI ID for payments',
    
    -- Verification
    kyc_verified BOOLEAN DEFAULT FALSE,
    payout_enabled BOOLEAN DEFAULT FALSE,
    webhook_secret VARCHAR(100) COMMENT 'Webhook verification secret',
    
    -- Configuration
    auto_capture BOOLEAN DEFAULT TRUE COMMENT 'Auto-capture payments',
    settlement_days INT DEFAULT 1 COMMENT 'Settlement period in days',
    
    -- Metadata
    status VARCHAR(1) DEFAULT '1' COMMENT '1=active, 0=inactive',
    verified_at TIMESTAMP NULL,
    last_used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    FOREIGN KEY (hostel_id) REFERENCES hostels(id) ON DELETE CASCADE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_gateway_type (gateway_type),
    INDEX idx_status (status),
    UNIQUE KEY unique_admin_hostel_gateway (admin_id, hostel_id, gateway_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Owner-specific payment gateway configurations';

-- ============================================
-- 3. ADMIN PERMISSIONS TABLE (RBAC)
-- ============================================

CREATE TABLE IF NOT EXISTS admin_permissions (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL COMMENT 'Admin/Manager ID',
    hostel_id VARCHAR(50) NOT NULL COMMENT 'Property ID',
    role VARCHAR(20) NOT NULL COMMENT 'owner, manager',
    
    -- Permissions (JSON or individual columns)
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
    
    -- Advanced permissions
    permissions_json JSON COMMENT 'Additional custom permissions',
    
    -- Metadata
    assigned_by VARCHAR(50) COMMENT 'Owner who assigned this',
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    FOREIGN KEY (hostel_id) REFERENCES hostels(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_admin_id (admin_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_role (role),
    UNIQUE KEY unique_admin_hostel (admin_id, hostel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Role-based access control for admins';

-- ============================================
-- 4. KYC DOCUMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS kyc_documents (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    
    -- Document types
    document_type VARCHAR(50) NOT NULL COMMENT 'pan, gstin, aadhar, address_proof, bank_statement',
    document_number VARCHAR(100) COMMENT 'Document identification number',
    document_url TEXT NOT NULL COMMENT 'S3 URL of uploaded document',
    
    -- Verification
    verification_status VARCHAR(20) DEFAULT 'pending' COMMENT 'pending, verified, rejected',
    verified_by VARCHAR(50) COMMENT 'Admin who verified',
    verified_at TIMESTAMP NULL,
    rejection_reason TEXT,
    
    -- Metadata
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE COMMENT 'Document expiry if applicable',
    
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES admins(id) ON DELETE SET NULL,
    INDEX idx_admin_id (admin_id),
    INDEX idx_document_type (document_type),
    INDEX idx_verification_status (verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='KYC document storage and verification';

-- ============================================
-- 5. PAYMENT TRANSACTIONS TABLE (Enhanced)
-- ============================================

CREATE TABLE IF NOT EXISTS payment_transactions (
    id VARCHAR(50) PRIMARY KEY,
    
    -- Relationships
    user_id VARCHAR(50) NOT NULL COMMENT 'Tenant who paid',
    hostel_id VARCHAR(50) NOT NULL COMMENT 'Property',
    admin_id VARCHAR(50) NOT NULL COMMENT 'Owner receiving payment',
    gateway_id VARCHAR(50) COMMENT 'Payment gateway used',
    
    -- Transaction details
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_method VARCHAR(50) COMMENT 'upi, card, netbanking, wallet',
    
    -- Gateway response
    gateway_order_id VARCHAR(100) COMMENT 'Gateway order ID',
    gateway_payment_id VARCHAR(100) COMMENT 'Gateway payment ID',
    gateway_signature VARCHAR(255) COMMENT 'Payment signature for verification',
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'initiated' COMMENT 'initiated, success, failed, refunded',
    failure_reason TEXT,
    
    -- Settlement
    settled BOOLEAN DEFAULT FALSE,
    settled_at TIMESTAMP NULL,
    settlement_amount DECIMAL(10,2) COMMENT 'Amount after fees',
    platform_fee DECIMAL(10,2) DEFAULT 0.00,
    
    -- Metadata
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (hostel_id) REFERENCES hostels(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    FOREIGN KEY (gateway_id) REFERENCES payment_gateways(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_admin_id (admin_id),
    INDEX idx_status (status),
    INDEX idx_payment_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='All payment transactions with gateway details';

-- ============================================
-- 6. QR CODES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS qr_codes (
    id VARCHAR(50) PRIMARY KEY,
    hostel_id VARCHAR(50) NOT NULL,
    admin_id VARCHAR(50) NOT NULL,
    gateway_id VARCHAR(50) NOT NULL,
    
    -- QR Code details
    qr_code_image_url TEXT NOT NULL COMMENT 'S3 URL of QR code image',
    qr_code_data TEXT NOT NULL COMMENT 'QR code data string',
    upi_id VARCHAR(100) NOT NULL,
    
    -- Usage tracking
    scan_count INT DEFAULT 0,
    successful_payments INT DEFAULT 0,
    total_amount_collected DECIMAL(12,2) DEFAULT 0.00,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    status VARCHAR(1) DEFAULT '1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (hostel_id) REFERENCES hostels(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    FOREIGN KEY (gateway_id) REFERENCES payment_gateways(id) ON DELETE CASCADE,
    INDEX idx_hostel_id (hostel_id),
    INDEX idx_admin_id (admin_id),
    INDEX idx_is_active (is_active),
    UNIQUE KEY unique_hostel_gateway (hostel_id, gateway_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='QR codes for property payments';

-- ============================================
-- 7. ONBOARDING PROGRESS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS onboarding_progress (
    id VARCHAR(50) PRIMARY KEY,
    admin_id VARCHAR(50) NOT NULL,
    
    -- Progress steps
    step_registration BOOLEAN DEFAULT FALSE,
    step_property_setup BOOLEAN DEFAULT FALSE,
    step_kyc_upload BOOLEAN DEFAULT FALSE,
    step_kyc_verification BOOLEAN DEFAULT FALSE,
    step_payment_gateway BOOLEAN DEFAULT FALSE,
    step_qr_generation BOOLEAN DEFAULT FALSE,
    step_completed BOOLEAN DEFAULT FALSE,
    
    -- Current step
    current_step INT DEFAULT 1 COMMENT '1-7',
    
    -- Metadata
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_current_step (current_step),
    UNIQUE KEY unique_admin (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Track owner onboarding progress';

-- ============================================
-- 8. UPDATE EXISTING TABLES
-- ============================================

-- Add gateway_id to payments table if not exists
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS gateway_id VARCHAR(50) COMMENT 'Payment gateway used',
ADD COLUMN IF NOT EXISTS admin_id VARCHAR(50) COMMENT 'Owner who received payment';

-- Add indexes
ALTER TABLE payments ADD INDEX IF NOT EXISTS idx_gateway_id (gateway_id);
ALTER TABLE payments ADD INDEX IF NOT EXISTS idx_admin_id (admin_id);

-- ============================================
-- 9. SEED DATA - Super Admin
-- ============================================

-- Create super admin for platform management
INSERT INTO admins (
    id, username, password, name, email, phone, 
    role, hostel_ids, status
) VALUES (
    'superadmin001',
    'superadmin',
    'Super@123',  -- Change this in production!
    'Platform Super Admin',
    'superadmin@pgworld.com',
    '0000000000',
    'superadmin',
    '',
    '1'
) ON DUPLICATE KEY UPDATE username=username;

-- ============================================
-- 10. VIEWS FOR REPORTING
-- ============================================

-- Owner Dashboard View
CREATE OR REPLACE VIEW v_owner_dashboard AS
SELECT 
    a.id as admin_id,
    a.name as owner_name,
    a.email,
    a.kyc_status,
    a.payout_enabled,
    COUNT(DISTINCT h.id) as total_properties,
    COUNT(DISTINCT r.id) as total_rooms,
    COUNT(DISTINCT u.id) as total_tenants,
    COUNT(DISTINCT pg.id) as payment_gateways_connected,
    COALESCE(SUM(pt.amount), 0) as total_revenue
FROM admins a
LEFT JOIN hostels h ON FIND_IN_SET(h.id, a.hostel_ids) > 0
LEFT JOIN rooms r ON r.hostel_id = h.id
LEFT JOIN users u ON u.hostel_id = h.id AND u.status = '1'
LEFT JOIN payment_gateways pg ON pg.admin_id = a.id AND pg.status = '1'
LEFT JOIN payment_transactions pt ON pt.admin_id = a.id AND pt.status = 'success'
WHERE a.role = 'owner'
GROUP BY a.id;

-- Manager Access View
CREATE OR REPLACE VIEW v_manager_access AS
SELECT 
    a.id as manager_id,
    a.name as manager_name,
    a.parent_admin_id as owner_id,
    ap.hostel_id,
    h.name as property_name,
    ap.role,
    ap.can_manage_rooms,
    ap.can_manage_tenants,
    ap.can_manage_bills
FROM admins a
JOIN admin_permissions ap ON a.id = ap.admin_id
JOIN hostels h ON ap.hostel_id = h.id
WHERE a.role = 'manager';

-- ============================================
-- 11. TRIGGERS
-- ============================================

-- Trigger to create onboarding progress on admin creation
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS after_admin_insert
AFTER INSERT ON admins
FOR EACH ROW
BEGIN
    IF NEW.role = 'owner' THEN
        INSERT INTO onboarding_progress (id, admin_id, step_registration)
        VALUES (CONCAT('onb_', NEW.id), NEW.id, TRUE);
    END IF;
END$$

-- Trigger to update onboarding progress on property creation
CREATE TRIGGER IF NOT EXISTS after_hostel_insert
AFTER INSERT ON hostels
FOR EACH ROW
BEGIN
    UPDATE onboarding_progress 
    SET step_property_setup = TRUE,
        current_step = GREATEST(current_step, 2)
    WHERE admin_id = NEW.admin_id;
END$$

-- Trigger to update onboarding on KYC verification
CREATE TRIGGER IF NOT EXISTS after_kyc_verified
AFTER UPDATE ON admins
FOR EACH ROW
BEGIN
    IF NEW.kyc_status = '1' AND OLD.kyc_status != '1' THEN
        UPDATE onboarding_progress 
        SET step_kyc_verification = TRUE,
            current_step = GREATEST(current_step, 4)
        WHERE admin_id = NEW.id;
    END IF;
END$$

-- Trigger to update onboarding on payment gateway connection
CREATE TRIGGER IF NOT EXISTS after_gateway_created
AFTER INSERT ON payment_gateways
FOR EACH ROW
BEGIN
    UPDATE onboarding_progress 
    SET step_payment_gateway = TRUE,
        current_step = GREATEST(current_step, 5)
    WHERE admin_id = NEW.admin_id;
END$$

-- Trigger to update onboarding on QR code generation
CREATE TRIGGER IF NOT EXISTS after_qr_generated
AFTER INSERT ON qr_codes
FOR EACH ROW
BEGIN
    UPDATE onboarding_progress 
    SET step_qr_generation = TRUE,
        step_completed = TRUE,
        current_step = 7,
        completed_at = CURRENT_TIMESTAMP
    WHERE admin_id = NEW.admin_id;
END$$

DELIMITER ;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

SELECT 'Database migration completed successfully!' AS Status;
SELECT 'Total tables created/modified: 10' AS Summary;
SELECT 'Total views created: 2' AS Summary;
SELECT 'Total triggers created: 4' AS Summary;

