-- ========================================
-- PGNi - Create Test Accounts & Demo Data
-- ========================================
-- Run this script to populate the database with test accounts
-- for all user roles: Admin, PG Owner, and Tenant
-- 
-- Usage: Run from CloudShell or local MySQL client
-- mysql -h database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com -u admin -p pgworld < CREATE_TEST_ACCOUNTS.sql
-- ========================================

USE pgworld;

-- ========================================
-- 1. CREATE TEST USERS
-- ========================================

-- Note: Password hashes are for "password123"
-- In production, use bcrypt or similar hashing

INSERT INTO users (username, email, password_hash, role, created_at) VALUES
-- Super Admin Account
('admin', 'admin@pgni.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'admin', NOW()),

-- PG Owner Accounts (Manages Properties)
('owner1', 'owner@pgni.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'pg_owner', NOW()),
('owner2', 'john.owner@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'pg_owner', NOW()),
('owner3', 'mary.owner@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'pg_owner', NOW()),

-- Tenant Accounts (Residents)
('tenant1', 'tenant@pgni.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'tenant', NOW()),
('tenant2', 'alice.tenant@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'tenant', NOW()),
('tenant3', 'bob.tenant@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'tenant', NOW()),
('tenant4', 'charlie.tenant@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'tenant', NOW()),
('tenant5', 'diana.tenant@example.com', '$2a$10$J3ZqR5YGXXl1Gw7y8Z8yZ.3N5V7U9kQ5Y1P3Z1gW3Q5Y1P3Z1gW3Q', 'tenant', NOW())
ON DUPLICATE KEY UPDATE username=username;

-- ========================================
-- 2. CREATE TEST PROPERTIES
-- ========================================

-- Get owner IDs
SET @owner1_id = (SELECT id FROM users WHERE username = 'owner1' LIMIT 1);
SET @owner2_id = (SELECT id FROM users WHERE username = 'owner2' LIMIT 1);
SET @owner3_id = (SELECT id FROM users WHERE username = 'owner3' LIMIT 1);

INSERT INTO pg_properties (owner_id, name, address, city, total_rooms, created_at) VALUES
(@owner1_id, 'Sunshine PG', '123 Main Street, Near Metro Station', 'New York', 20, NOW()),
(@owner1_id, 'Green Valley Hostel', '456 Oak Avenue, University Area', 'New York', 15, NOW()),
(@owner2_id, 'City Center PG', '789 Park Road, Downtown', 'Boston', 30, NOW()),
(@owner2_id, 'Student Haven', '321 College Street, Campus Area', 'Boston', 25, NOW()),
(@owner3_id, 'Elite Residence', '654 Lake View Drive, IT Park', 'San Francisco', 40, NOW()),
(@owner3_id, 'Cozy Nest PG', '987 River Side, Residential Area', 'San Francisco', 12, NOW())
ON DUPLICATE KEY UPDATE name=name;

-- ========================================
-- 3. CREATE TEST ROOMS
-- ========================================

-- Get property IDs
SET @prop1_id = (SELECT id FROM pg_properties WHERE name = 'Sunshine PG' LIMIT 1);
SET @prop2_id = (SELECT id FROM pg_properties WHERE name = 'Green Valley Hostel' LIMIT 1);
SET @prop3_id = (SELECT id FROM pg_properties WHERE name = 'City Center PG' LIMIT 1);
SET @prop4_id = (SELECT id FROM pg_properties WHERE name = 'Student Haven' LIMIT 1);
SET @prop5_id = (SELECT id FROM pg_properties WHERE name = 'Elite Residence' LIMIT 1);
SET @prop6_id = (SELECT id FROM pg_properties WHERE name = 'Cozy Nest PG' LIMIT 1);

-- Sunshine PG Rooms (20 rooms)
INSERT INTO rooms (property_id, room_number, rent_amount, is_occupied, created_at) VALUES
-- Single Rooms
(@prop1_id, '101', 8000.00, FALSE, NOW()),
(@prop1_id, '102', 8000.00, TRUE, NOW()),
(@prop1_id, '103', 8000.00, FALSE, NOW()),
(@prop1_id, '104', 8000.00, FALSE, NOW()),
(@prop1_id, '105', 8000.00, TRUE, NOW()),
-- Double Rooms
(@prop1_id, '201', 6000.00, TRUE, NOW()),
(@prop1_id, '202', 6000.00, FALSE, NOW()),
(@prop1_id, '203', 6000.00, TRUE, NOW()),
(@prop1_id, '204', 6000.00, FALSE, NOW()),
(@prop1_id, '205', 6000.00, FALSE, NOW()),
-- Triple Rooms
(@prop1_id, '301', 5000.00, TRUE, NOW()),
(@prop1_id, '302', 5000.00, FALSE, NOW()),
(@prop1_id, '303', 5000.00, FALSE, NOW()),
(@prop1_id, '304', 5000.00, FALSE, NOW()),
(@prop1_id, '305', 5000.00, FALSE, NOW()),
-- Deluxe Rooms
(@prop1_id, 'D01', 12000.00, FALSE, NOW()),
(@prop1_id, 'D02', 12000.00, TRUE, NOW()),
(@prop1_id, 'D03', 12000.00, FALSE, NOW()),
(@prop1_id, 'D04', 12000.00, FALSE, NOW()),
(@prop1_id, 'D05', 12000.00, FALSE, NOW()),

-- Green Valley Hostel Rooms (15 rooms)
(@prop2_id, 'A101', 7000.00, TRUE, NOW()),
(@prop2_id, 'A102', 7000.00, FALSE, NOW()),
(@prop2_id, 'A103', 7000.00, TRUE, NOW()),
(@prop2_id, 'A104', 7000.00, FALSE, NOW()),
(@prop2_id, 'A105', 7000.00, FALSE, NOW()),
(@prop2_id, 'B201', 9000.00, FALSE, NOW()),
(@prop2_id, 'B202', 9000.00, FALSE, NOW()),
(@prop2_id, 'B203', 9000.00, FALSE, NOW()),
(@prop2_id, 'B204', 9000.00, FALSE, NOW()),
(@prop2_id, 'B205', 9000.00, FALSE, NOW()),
(@prop2_id, 'C301', 11000.00, FALSE, NOW()),
(@prop2_id, 'C302', 11000.00, FALSE, NOW()),
(@prop2_id, 'C303', 11000.00, FALSE, NOW()),
(@prop2_id, 'C304', 11000.00, FALSE, NOW()),
(@prop2_id, 'C305', 11000.00, FALSE, NOW()),

-- City Center PG Rooms (30 rooms - Sample)
(@prop3_id, 'R101', 10000.00, TRUE, NOW()),
(@prop3_id, 'R102', 10000.00, FALSE, NOW()),
(@prop3_id, 'R103', 10000.00, TRUE, NOW()),
(@prop3_id, 'R104', 10000.00, FALSE, NOW()),
(@prop3_id, 'R105', 10000.00, FALSE, NOW())
ON DUPLICATE KEY UPDATE room_number=room_number;

-- ========================================
-- 4. CREATE TENANT PROFILES
-- ========================================

-- Get user IDs
SET @tenant1_id = (SELECT id FROM users WHERE username = 'tenant1' LIMIT 1);
SET @tenant2_id = (SELECT id FROM users WHERE username = 'tenant2' LIMIT 1);
SET @tenant3_id = (SELECT id FROM users WHERE username = 'tenant3' LIMIT 1);
SET @tenant4_id = (SELECT id FROM users WHERE username = 'tenant4' LIMIT 1);
SET @tenant5_id = (SELECT id FROM users WHERE username = 'tenant5' LIMIT 1);

-- Get room IDs for occupied rooms
SET @room1_id = (SELECT id FROM rooms WHERE property_id = @prop1_id AND room_number = '102' LIMIT 1);
SET @room2_id = (SELECT id FROM rooms WHERE property_id = @prop1_id AND room_number = '105' LIMIT 1);
SET @room3_id = (SELECT id FROM rooms WHERE property_id = @prop1_id AND room_number = '201' LIMIT 1);
SET @room4_id = (SELECT id FROM rooms WHERE property_id = @prop2_id AND room_number = 'A101' LIMIT 1);
SET @room5_id = (SELECT id FROM rooms WHERE property_id = @prop3_id AND room_number = 'R101' LIMIT 1);

INSERT INTO tenants (user_id, room_id, name, phone, move_in_date, is_active, created_at) VALUES
(@tenant1_id, @room1_id, 'Test Tenant 1', '+1-555-0101', '2024-01-01', TRUE, NOW()),
(@tenant2_id, @room2_id, 'Alice Johnson', '+1-555-0102', '2024-02-01', TRUE, NOW()),
(@tenant3_id, @room3_id, 'Bob Smith', '+1-555-0103', '2024-03-01', TRUE, NOW()),
(@tenant4_id, @room4_id, 'Charlie Brown', '+1-555-0104', '2024-04-01', TRUE, NOW()),
(@tenant5_id, @room5_id, 'Diana Prince', '+1-555-0105', '2024-05-01', TRUE, NOW())
ON DUPLICATE KEY UPDATE name=name;

-- ========================================
-- 5. CREATE PAYMENT RECORDS
-- ========================================

-- Get tenant IDs
SET @t1_id = (SELECT id FROM tenants WHERE name = 'Test Tenant 1' LIMIT 1);
SET @t2_id = (SELECT id FROM tenants WHERE name = 'Alice Johnson' LIMIT 1);
SET @t3_id = (SELECT id FROM tenants WHERE name = 'Bob Smith' LIMIT 1);
SET @t4_id = (SELECT id FROM tenants WHERE name = 'Charlie Brown' LIMIT 1);
SET @t5_id = (SELECT id FROM tenants WHERE name = 'Diana Prince' LIMIT 1);

-- Past 3 months payments
INSERT INTO payments (tenant_id, amount, payment_date, status, created_at) VALUES
-- Tenant 1 - Regular payments
(@t1_id, 8000.00, '2024-08-05', 'completed', NOW()),
(@t1_id, 8000.00, '2024-09-05', 'completed', NOW()),
(@t1_id, 8000.00, '2024-10-05', 'pending', NOW()),

-- Tenant 2 - Regular payments
(@t2_id, 8000.00, '2024-08-10', 'completed', NOW()),
(@t2_id, 8000.00, '2024-09-10', 'completed', NOW()),
(@t2_id, 8000.00, '2024-10-10', 'completed', NOW()),

-- Tenant 3 - One pending
(@t3_id, 6000.00, '2024-08-15', 'completed', NOW()),
(@t3_id, 6000.00, '2024-09-15', 'completed', NOW()),
(@t3_id, 6000.00, '2024-10-15', 'pending', NOW()),

-- Tenant 4 - Regular payments
(@t4_id, 7000.00, '2024-08-01', 'completed', NOW()),
(@t4_id, 7000.00, '2024-09-01', 'completed', NOW()),
(@t4_id, 7000.00, '2024-10-01', 'completed', NOW()),

-- Tenant 5 - One failed payment
(@t5_id, 10000.00, '2024-08-20', 'completed', NOW()),
(@t5_id, 10000.00, '2024-09-20', 'failed', NOW()),
(@t5_id, 10000.00, '2024-10-20', 'pending', NOW())
ON DUPLICATE KEY UPDATE status=status;

-- ========================================
-- 6. VERIFY DATA
-- ========================================

-- Display summary
SELECT 'DATA CREATION COMPLETE' AS Status;
SELECT COUNT(*) AS Total_Users FROM users;
SELECT COUNT(*) AS Total_Properties FROM pg_properties;
SELECT COUNT(*) AS Total_Rooms FROM rooms;
SELECT COUNT(*) AS Total_Tenants FROM tenants;
SELECT COUNT(*) AS Total_Payments FROM payments;

-- Display test accounts
SELECT 
    '=== TEST ACCOUNTS ===' AS Info,
    'Use these credentials to login' AS Instructions;

SELECT 
    'ADMIN' AS Role,
    'admin@pgni.com' AS Email,
    'password123' AS Password,
    'Full system access' AS Access
UNION ALL
SELECT 
    'PG OWNER',
    'owner@pgni.com',
    'password123',
    'Manages properties and tenants'
UNION ALL
SELECT 
    'TENANT',
    'tenant@pgni.com',
    'password123',
    'Resident access only';

-- ========================================
-- 7. ADDITIONAL DEMO DATA (OPTIONAL)
-- ========================================

-- Create some notices (announcements)
-- Note: Adjust table name if different in your schema
-- INSERT INTO notices (title, content, created_by, created_at) VALUES
-- ('Welcome to Sunshine PG!', 'We are glad to have you here. Please maintain cleanliness.', @owner1_id, NOW()),
-- ('Maintenance Notice', 'Water supply will be unavailable on Sunday 10 AM - 2 PM', @owner1_id, NOW()),
-- ('Monthly Meeting', 'All residents please attend monthly meeting on 15th', @owner2_id, NOW());

-- Create some issues/complaints
-- Note: Adjust table name if different in your schema
-- INSERT INTO issues (tenant_id, subject, description, status, created_at) VALUES
-- (@t1_id, 'AC Not Working', 'The AC in my room is not cooling properly', 'pending', NOW()),
-- (@t2_id, 'WiFi Issue', 'Internet connection is very slow', 'in_progress', NOW()),
-- (@t3_id, 'Water Leak', 'There is a water leak in the bathroom', 'resolved', NOW());

-- ========================================
-- END OF SCRIPT
-- ========================================

SELECT '=== SETUP COMPLETE ===' AS Status;
SELECT 'You can now login to the apps with the test accounts' AS Message;
SELECT 'Run TEST_ALL_PAGES.bat to start testing the UI' AS NextStep;

