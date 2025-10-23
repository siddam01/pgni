#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "📊 LOAD SAMPLE DATA FOR VALIDATION"
echo "═══════════════════════════════════════════════════════"
echo ""

# Database credentials
DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="Admin123"
DB_NAME="pgworld"

echo "STEP 1: Verify Database Connection"
echo "───────────────────────────────────────────────────────"

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SELECT 1;" &>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

echo ""
echo "STEP 2: Clean Existing Sample Data"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
-- Keep admin and existing tenant user
DELETE FROM bills WHERE id != 'keep';
DELETE FROM issues WHERE id != 'keep';
DELETE FROM notices WHERE id != 'keep';
DELETE FROM employees WHERE id != 'keep';
DELETE FROM food WHERE id != 'keep';
-- Delete users except admin and priya
DELETE FROM users WHERE email NOT IN ('admin@example.com', 'priya@example.com');
-- Delete rooms and hostels will cascade
DELETE FROM rooms WHERE id != 'keep';
DELETE FROM hostels WHERE id != 'keep';
SQL

echo "✓ Existing sample data cleaned"

echo ""
echo "STEP 3: Load Sample Hostels"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO hostels (id, name, phone, email, address, amenities, status, expiryDateTime, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('hostel-001', 'Green Valley PG', '9876543210', 'greenvalley@example.com', '123 MG Road, Bangalore, Karnataka - 560001', 'WiFi,AC,TV,Parking,Security,Laundry', 'active', '2025-12-31 23:59:59', 'admin', 'admin', NOW(), NOW()),
('hostel-002', 'Sunrise Hostel', '9876543211', 'sunrise@example.com', '456 Park Street, Mumbai, Maharashtra - 400001', 'WiFi,TV,Parking,Security,Food,Gym', 'active', '2025-12-31 23:59:59', 'admin', 'admin', NOW(), NOW()),
('hostel-003', 'Comfort Stay PG', '9876543212', 'comfort@example.com', '789 Anna Salai, Chennai, Tamil Nadu - 600002', 'WiFi,AC,Security,Laundry,Food', 'active', '2025-12-31 23:59:59', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Loaded 3 sample hostels"

echo ""
echo "STEP 4: Load Sample Rooms"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO rooms (id, hostelID, roomno, rent, floor, filled, capacity, amenities, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
-- Green Valley PG rooms
('room-001', 'hostel-001', '101', '8000', '1', '2', '2', 'AC,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-002', 'hostel-001', '102', '10000', '1', '1', '1', 'AC,Attached Bathroom,Balcony', 'active', 'admin', 'admin', NOW(), NOW()),
('room-003', 'hostel-001', '103', '6000', '1', '0', '3', 'Fan,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-004', 'hostel-001', '201', '12000', '2', '1', '1', 'AC,Attached Bathroom,Balcony,Furnished', 'active', 'admin', 'admin', NOW(), NOW()),
-- Sunrise Hostel rooms
('room-005', 'hostel-002', '101', '9000', '1', '2', '2', 'AC,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-006', 'hostel-002', '102', '7000', '1', '0', '3', 'Fan,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-007', 'hostel-002', '201', '11000', '2', '1', '1', 'AC,Attached Bathroom,Furnished', 'active', 'admin', 'admin', NOW(), NOW()),
-- Comfort Stay PG rooms
('room-008', 'hostel-003', '101', '8500', '1', '1', '2', 'AC,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-009', 'hostel-003', '102', '7500', '1', '0', '2', 'Fan,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-010', 'hostel-003', '201', '10000', '2', '1', '1', 'AC,Attached Bathroom,Balcony', 'active', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Loaded 10 sample rooms"

echo ""
echo "STEP 5: Load Sample Tenants/Users"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO users (id, hostelID, name, phone, email, address, roomID, roomno, rent, emerContact, emerPhone, food, document, paymentStatus, joiningDateTime, lastPaidDateTime, expiryDateTime, leaveDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
-- Priya already exists, add more tenants
('user-002', 'hostel-001', 'Rahul Kumar', '9876543213', 'rahul@example.com', 'Delhi', 'room-001', '101', '8000', 'Mrs. Kumar', '9876543220', 'yes', 'aadhar.pdf', 'paid', '2024-01-01 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-003', 'hostel-001', 'Sneha Reddy', '9876543214', 'sneha@example.com', 'Hyderabad', 'room-002', '102', '10000', 'Mr. Reddy', '9876543221', 'yes', 'aadhar.pdf', 'paid', '2024-02-01 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-004', 'hostel-001', 'Amit Patel', '9876543215', 'amit@example.com', 'Ahmedabad', 'room-004', '201', '12000', 'Mrs. Patel', '9876543222', 'no', 'aadhar.pdf,pan.pdf', 'pending', '2024-03-01 00:00:00', '2024-09-01 00:00:00', '2024-10-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-005', 'hostel-002', 'Divya Sharma', '9876543216', 'divya@example.com', 'Pune', 'room-005', '101', '9000', 'Mr. Sharma', '9876543223', 'yes', 'aadhar.pdf', 'paid', '2024-01-15 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-006', 'hostel-002', 'Vikram Singh', '9876543217', 'vikram@example.com', 'Jaipur', 'room-007', '201', '11000', 'Mrs. Singh', '9876543224', 'yes', 'aadhar.pdf', 'pending', '2024-04-01 00:00:00', '2024-09-01 00:00:00', '2024-10-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-007', 'hostel-003', 'Anjali Nair', '9876543218', 'anjali@example.com', 'Kochi', 'room-008', '101', '8500', 'Mr. Nair', '9876543225', 'yes', 'aadhar.pdf,passport.pdf', 'paid', '2024-02-15 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-008', 'hostel-003', 'Karthik Rao', '9876543219', 'karthik@example.com', 'Mangalore', 'room-010', '201', '10000', 'Mrs. Rao', '9876543226', 'no', 'aadhar.pdf', 'paid', '2024-03-15 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Loaded 7 new sample tenants (8 total with Priya)"

echo ""
echo "STEP 6: Load Sample Bills"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO bills (id, user, room, bill, note, paid, expiryDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('bill-001', 'user-002', 'room-001', '8000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-05 00:00:00'),
('bill-002', 'user-003', 'room-002', '10000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-03 00:00:00'),
('bill-003', 'user-004', 'room-004', '12000', 'October Rent', 'no', '2024-10-31 23:59:59', 'pending', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-01 00:00:00'),
('bill-004', 'user-005', 'room-005', '9000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-02 00:00:00'),
('bill-005', 'user-006', 'room-007', '11000', 'October Rent', 'no', '2024-10-31 23:59:59', 'pending', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-01 00:00:00'),
('bill-006', 'user-007', 'room-008', '8500', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-04 00:00:00'),
('bill-007', 'user-008', 'room-010', '10000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-06 00:00:00'),
('bill-008', 'user-002', 'room-001', '500', 'Electricity Bill', 'no', '2024-10-15 23:59:59', 'pending', 'admin', 'admin', '2024-10-05 00:00:00', '2024-10-05 00:00:00'),
('bill-009', 'user-003', 'room-002', '600', 'Maintenance Charge', 'yes', '2024-10-20 23:59:59', 'paid', 'admin', 'admin', '2024-10-05 00:00:00', '2024-10-08 00:00:00'),
('bill-010', 'user-005', 'room-005', '450', 'Electricity Bill', 'no', '2024-10-15 23:59:59', 'pending', 'admin', 'admin', '2024-10-05 00:00:00', '2024-10-05 00:00:00');
SQL

echo "✓ Loaded 10 sample bills"

echo ""
echo "STEP 7: Load Sample Issues"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO issues (id, log, \`by\`, type, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('issue-001', 'AC not working in room 101', 'user-002', 'maintenance', 'open', 'user-002', 'user-002', '2024-10-15 10:00:00', '2024-10-15 10:00:00'),
('issue-002', 'Water leakage in bathroom', 'user-003', 'plumbing', 'in-progress', 'user-003', 'admin', '2024-10-14 14:30:00', '2024-10-16 09:00:00'),
('issue-003', 'WiFi connection problem', 'user-005', 'network', 'open', 'user-005', 'user-005', '2024-10-16 16:00:00', '2024-10-16 16:00:00'),
('issue-004', 'Door lock broken', 'user-004', 'maintenance', 'resolved', 'user-004', 'admin', '2024-10-10 11:00:00', '2024-10-12 15:00:00'),
('issue-005', 'Noise complaint from neighbors', 'user-006', 'complaint', 'in-progress', 'user-006', 'admin', '2024-10-13 20:00:00', '2024-10-14 10:00:00'),
('issue-006', 'Bed replacement needed', 'user-007', 'maintenance', 'open', 'user-007', 'user-007', '2024-10-17 09:00:00', '2024-10-17 09:00:00'),
('issue-007', 'Electrical socket not working', 'user-008', 'electrical', 'resolved', 'user-008', 'admin', '2024-10-11 14:00:00', '2024-10-12 16:00:00'),
('issue-008', 'Room cleaning not done', 'user-002', 'complaint', 'resolved', 'user-002', 'admin', '2024-10-09 08:00:00', '2024-10-09 12:00:00');
SQL

echo "✓ Loaded 8 sample issues"

echo ""
echo "STEP 8: Load Sample Notices"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO notices (id, note, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('notice-001', 'Water supply will be interrupted on 25th Oct from 10 AM to 2 PM for maintenance', 'active', 'admin', 'admin', '2024-10-18 09:00:00', '2024-10-18 09:00:00'),
('notice-002', 'Monthly rent payment deadline: 5th of every month', 'active', 'admin', 'admin', '2024-10-01 08:00:00', '2024-10-01 08:00:00'),
('notice-003', 'Diwali holiday: Office closed from 28th to 30th October', 'active', 'admin', 'admin', '2024-10-15 10:00:00', '2024-10-15 10:00:00'),
('notice-004', 'New WiFi password: GreenValley2024', 'active', 'admin', 'admin', '2024-10-10 15:00:00', '2024-10-10 15:00:00'),
('notice-005', 'Parking area cleaning scheduled for Saturday 8 AM', 'active', 'admin', 'admin', '2024-10-17 12:00:00', '2024-10-17 12:00:00'),
('notice-006', 'Guest policy: Maximum 2 guests allowed, prior approval required', 'active', 'admin', 'admin', '2024-10-05 09:00:00', '2024-10-05 09:00:00'),
('notice-007', 'Fire safety drill on 1st November at 4 PM', 'active', 'admin', 'admin', '2024-10-19 11:00:00', '2024-10-19 11:00:00');
SQL

echo "✓ Loaded 7 sample notices"

echo ""
echo "STEP 9: Load Sample Employees"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO employees (id, name, designation, phone, email, address, document, salary, joiningDateTime, lastPaidDateTime, expiryDateTime, leaveDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('emp-001', 'Rajesh Kumar', 'Manager', '9876000001', 'rajesh.manager@example.com', 'Bangalore', 'aadhar.pdf,pan.pdf', '35000', '2023-01-01 00:00:00', '2024-10-01 00:00:00', '2025-01-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('emp-002', 'Sunita Devi', 'Cleaner', '9876000002', 'sunita.cleaner@example.com', 'Bangalore', 'aadhar.pdf', '15000', '2023-06-01 00:00:00', '2024-10-01 00:00:00', '2025-06-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('emp-003', 'Ramesh Yadav', 'Security Guard', '9876000003', 'ramesh.security@example.com', 'Bangalore', 'aadhar.pdf', '18000', '2023-03-01 00:00:00', '2024-10-01 00:00:00', '2025-03-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('emp-004', 'Lakshmi Bai', 'Cook', '9876000004', 'lakshmi.cook@example.com', 'Bangalore', 'aadhar.pdf,health.pdf', '20000', '2023-02-01 00:00:00', '2024-10-01 00:00:00', '2025-02-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('emp-005', 'Anil Sharma', 'Maintenance', '9876000005', 'anil.maintenance@example.com', 'Bangalore', 'aadhar.pdf,pan.pdf', '22000', '2023-04-01 00:00:00', '2024-10-01 00:00:00', '2025-04-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Loaded 5 sample employees"

echo ""
echo "STEP 10: Load Sample Food Menu"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
-- Create food table if it doesn't exist
CREATE TABLE IF NOT EXISTS food (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    img VARCHAR(500),
    hostelID VARCHAR(36),
    type VARCHAR(50),
    status VARCHAR(50),
    createdBy VARCHAR(36),
    modifiedBy VARCHAR(36),
    createdDateTime DATETIME,
    modifiedDateTime DATETIME
);

INSERT INTO food (id, title, img, hostelID, type, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('food-001', 'Idli Sambar', 'idli.jpg', 'hostel-001', 'breakfast', 'active', 'admin', 'admin', NOW(), NOW()),
('food-002', 'Poha', 'poha.jpg', 'hostel-001', 'breakfast', 'active', 'admin', 'admin', NOW(), NOW()),
('food-003', 'Chapati with Dal', 'chapati.jpg', 'hostel-001', 'lunch', 'active', 'admin', 'admin', NOW(), NOW()),
('food-004', 'Rice with Sambar', 'rice.jpg', 'hostel-001', 'lunch', 'active', 'admin', 'admin', NOW(), NOW()),
('food-005', 'Vegetable Biryani', 'biryani.jpg', 'hostel-001', 'dinner', 'active', 'admin', 'admin', NOW(), NOW()),
('food-006', 'Paneer Butter Masala', 'paneer.jpg', 'hostel-001', 'dinner', 'active', 'admin', 'admin', NOW(), NOW()),
('food-007', 'Dosa', 'dosa.jpg', 'hostel-002', 'breakfast', 'active', 'admin', 'admin', NOW(), NOW()),
('food-008', 'Upma', 'upma.jpg', 'hostel-002', 'breakfast', 'active', 'admin', 'admin', NOW(), NOW()),
('food-009', 'Mixed Vegetable Curry', 'veg.jpg', 'hostel-002', 'lunch', 'active', 'admin', 'admin', NOW(), NOW()),
('food-010', 'Curd Rice', 'curdrice.jpg', 'hostel-002', 'lunch', 'active', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Loaded 10 sample food items"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ SAMPLE DATA LOADED SUCCESSFULLY!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  - Hostels: 3"
echo "  - Rooms: 10"
echo "  - Tenants/Users: 8 (including Priya)"
echo "  - Bills: 10"
echo "  - Issues: 8"
echo "  - Notices: 7"
echo "  - Employees: 5"
echo "  - Food Items: 10"
echo ""
echo "✅ Total Sample Records: 61"
echo ""
echo "🎯 Next Steps:"
echo "  1. Verify data in admin portal"
echo "  2. Run validation tests: bash RUN_VALIDATION_TESTS.sh"
echo "  3. Perform manual testing"
echo ""
echo "═══════════════════════════════════════════════════════"

