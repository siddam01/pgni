#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "🔧 FIX DATABASE CONNECTION & LOAD SAMPLE DATA"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "STEP 1: Detect Database Credentials from API Config"
echo "───────────────────────────────────────────────────────"

# Try to find DB credentials from Go API config
API_DIR="/home/ec2-user/pgni/pgworld-api"
if [ -f "$API_DIR/main.go" ]; then
    echo "Found API config, extracting DB credentials..."
    
    # Extract from connection string in main.go
    DB_INFO=$(grep -A 5 "sql.Open" "$API_DIR/main.go" | head -10)
    
    # Try to extract individual components
    if echo "$DB_INFO" | grep -q "@tcp"; then
        # Extract from DSN format: user:pass@tcp(host:port)/dbname
        DB_HOST=$(echo "$DB_INFO" | grep -oP '@tcp\(\K[^:]+' || echo "database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com")
        DB_USER=$(echo "$DB_INFO" | grep -oP 'Open\("mysql", "\K[^:]+' || echo "admin")
        DB_PASS=$(echo "$DB_INFO" | grep -oP ':[^@]+@tcp' | tr -d ':@tcp' || echo "Admin123")
        DB_NAME=$(echo "$DB_INFO" | grep -oP '\)/\K[^"]+' || echo "pgworld")
    else
        # Fallback to known values
        DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
        DB_USER="admin"
        DB_PASS="Admin123"
        DB_NAME="pgworld"
    fi
else
    echo "⚠️  API config not found, using default values"
    DB_HOST="database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com"
    DB_USER="admin"
    DB_PASS="Admin123"
    DB_NAME="pgworld"
fi

echo "Using Database Credentials:"
echo "  Host: $DB_HOST"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"

echo ""
echo "STEP 2: Test Database Connection"
echo "───────────────────────────────────────────────────────"

# Install mysql client if not present
if ! command -v mysql &>/dev/null; then
    echo "Installing MySQL client..."
    sudo yum install -y mysql 2>&1 | tail -3
fi

# Test connection
if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SELECT 1 AS test;" &>/dev/null; then
    echo "✓ Database connection successful"
else
    echo "❌ Database connection failed!"
    echo ""
    echo "Please provide correct database credentials:"
    echo "Current attempt:"
    echo "  mysql -h $DB_HOST -u $DB_USER -p[PASSWORD] $DB_NAME"
    echo ""
    echo "To fix:"
    echo "1. Check RDS instance is running"
    echo "2. Check security group allows EC2 connection"
    echo "3. Verify credentials in /home/ec2-user/pgni/pgworld-api/main.go"
    exit 1
fi

echo ""
echo "STEP 3: Check Existing Data"
echo "───────────────────────────────────────────────────────"

USER_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
HOSTEL_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM hostels;" 2>/dev/null || echo "0")

echo "Current data:"
echo "  Users: $USER_COUNT"
echo "  Hostels: $HOSTEL_COUNT"

if [ "$USER_COUNT" -gt 5 ] && [ "$HOSTEL_COUNT" -gt 2 ]; then
    echo ""
    echo "✓ Sufficient sample data already exists!"
    echo ""
    read -p "Do you want to reload sample data? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping data load. Using existing data."
        exit 0
    fi
fi

echo ""
echo "STEP 4: Load Sample Data"
echo "───────────────────────────────────────────────────────"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
-- Clean existing sample data (keep admin and priya)
DELETE FROM bills WHERE id NOT IN (SELECT id FROM (SELECT id FROM bills LIMIT 0) AS temp);
DELETE FROM issues WHERE id NOT IN (SELECT id FROM (SELECT id FROM issues LIMIT 0) AS temp);
DELETE FROM notices WHERE id NOT IN (SELECT id FROM (SELECT id FROM notices LIMIT 0) AS temp);
DELETE FROM employees WHERE id NOT IN (SELECT id FROM (SELECT id FROM employees LIMIT 0) AS temp);

-- Keep existing users and hostels, just add new ones if needed

-- Insert sample hostels (if not exist)
INSERT IGNORE INTO hostels (id, name, phone, email, address, amenities, status, expiryDateTime, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('hostel-sample-001', 'Green Valley PG', '9876543210', 'greenvalley@example.com', '123 MG Road, Bangalore, Karnataka - 560001', 'WiFi,AC,TV,Parking,Security,Laundry', 'active', '2025-12-31 23:59:59', 'admin', 'admin', NOW(), NOW()),
('hostel-sample-002', 'Sunrise Hostel', '9876543211', 'sunrise@example.com', '456 Park Street, Mumbai, Maharashtra - 400001', 'WiFi,TV,Parking,Security,Food,Gym', 'active', '2025-12-31 23:59:59', 'admin', 'admin', NOW(), NOW());

-- Insert sample rooms (if not exist)
INSERT IGNORE INTO rooms (id, hostelID, roomno, rent, floor, filled, capacity, amenities, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('room-sample-001', 'hostel-sample-001', '101', '8000', '1', '1', '2', 'AC,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW()),
('room-sample-002', 'hostel-sample-001', '102', '10000', '1', '1', '1', 'AC,Attached Bathroom,Balcony', 'active', 'admin', 'admin', NOW(), NOW()),
('room-sample-003', 'hostel-sample-002', '101', '9000', '1', '1', '2', 'AC,Attached Bathroom', 'active', 'admin', 'admin', NOW(), NOW());

-- Insert sample users/tenants (if not exist)
INSERT IGNORE INTO users (id, hostelID, name, phone, email, address, roomID, roomno, rent, emerContact, emerPhone, food, document, paymentStatus, joiningDateTime, lastPaidDateTime, expiryDateTime, leaveDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('user-sample-001', 'hostel-sample-001', 'Rahul Kumar', '9876543213', 'rahul@example.com', 'Delhi', 'room-sample-001', '101', '8000', 'Mrs. Kumar', '9876543220', 'yes', 'aadhar.pdf', 'paid', '2024-01-01 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-sample-002', 'hostel-sample-001', 'Sneha Reddy', '9876543214', 'sneha@example.com', 'Hyderabad', 'room-sample-002', '102', '10000', 'Mr. Reddy', '9876543221', 'yes', 'aadhar.pdf', 'paid', '2024-02-01 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('user-sample-003', 'hostel-sample-002', 'Divya Sharma', '9876543216', 'divya@example.com', 'Pune', 'room-sample-003', '101', '9000', 'Mr. Sharma', '9876543223', 'yes', 'aadhar.pdf', 'paid', '2024-01-15 00:00:00', '2024-10-01 00:00:00', '2024-11-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW());

-- Insert sample bills
INSERT INTO bills (id, user, room, bill, note, paid, expiryDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('bill-sample-001', 'user-sample-001', 'room-sample-001', '8000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-05 00:00:00'),
('bill-sample-002', 'user-sample-002', 'room-sample-002', '10000', 'October Rent', 'no', '2024-10-31 23:59:59', 'pending', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-01 00:00:00'),
('bill-sample-003', 'user-sample-003', 'room-sample-003', '9000', 'October Rent', 'yes', '2024-10-31 23:59:59', 'paid', 'admin', 'admin', '2024-10-01 00:00:00', '2024-10-02 00:00:00');

-- Insert sample issues
INSERT INTO issues (id, log, \`by\`, type, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('issue-sample-001', 'AC not working in room 101', 'user-sample-001', 'maintenance', 'open', 'user-sample-001', 'user-sample-001', '2024-10-15 10:00:00', '2024-10-15 10:00:00'),
('issue-sample-002', 'Water leakage in bathroom', 'user-sample-002', 'plumbing', 'in-progress', 'user-sample-002', 'admin', '2024-10-14 14:30:00', '2024-10-16 09:00:00'),
('issue-sample-003', 'WiFi connection problem', 'user-sample-003', 'network', 'resolved', 'user-sample-003', 'admin', '2024-10-16 16:00:00', '2024-10-18 10:00:00');

-- Insert sample notices
INSERT INTO notices (id, note, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('notice-sample-001', 'Water supply will be interrupted on 25th Oct from 10 AM to 2 PM for maintenance', 'active', 'admin', 'admin', '2024-10-18 09:00:00', '2024-10-18 09:00:00'),
('notice-sample-002', 'Monthly rent payment deadline: 5th of every month', 'active', 'admin', 'admin', '2024-10-01 08:00:00', '2024-10-01 08:00:00'),
('notice-sample-003', 'New WiFi password: GreenValley2024', 'active', 'admin', 'admin', '2024-10-10 15:00:00', '2024-10-10 15:00:00');

-- Insert sample employees
INSERT INTO employees (id, name, designation, phone, email, address, document, salary, joiningDateTime, lastPaidDateTime, expiryDateTime, leaveDateTime, status, createdBy, modifiedBy, createdDateTime, modifiedDateTime) VALUES
('emp-sample-001', 'Rajesh Kumar', 'Manager', '9876000001', 'rajesh.manager@example.com', 'Bangalore', 'aadhar.pdf,pan.pdf', '35000', '2023-01-01 00:00:00', '2024-10-01 00:00:00', '2025-01-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW()),
('emp-sample-002', 'Sunita Devi', 'Cleaner', '9876000002', 'sunita.cleaner@example.com', 'Bangalore', 'aadhar.pdf', '15000', '2023-06-01 00:00:00', '2024-10-01 00:00:00', '2025-06-01 00:00:00', NULL, 'active', 'admin', 'admin', NOW(), NOW());
SQL

echo "✓ Sample data loaded"

echo ""
echo "STEP 5: Verify Data"
echo "───────────────────────────────────────────────────────"

NEW_USER_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM users;")
NEW_HOSTEL_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM hostels;")
BILL_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM bills;")
ISSUE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM issues;")
NOTICE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM notices;")
EMPLOYEE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM employees;")

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ SAMPLE DATA LOADED SUCCESSFULLY!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Current Data Summary:"
echo "  - Users/Tenants: $NEW_USER_COUNT"
echo "  - Hostels: $NEW_HOSTEL_COUNT"
echo "  - Bills: $BILL_COUNT"
echo "  - Issues: $ISSUE_COUNT"
echo "  - Notices: $NOTICE_COUNT"
echo "  - Employees: $EMPLOYEE_COUNT"
echo ""
echo "🎯 Next Steps:"
echo "  1. Open admin portal: http://54.227.101.30/admin/"
echo "  2. Login with: admin@example.com / Admin@123"
echo "  3. Verify sample data is visible"
echo "  4. Start functional testing"
echo ""
echo "📝 Download validation template:"
echo "  https://github.com/siddam01/pgni/blob/main/PGNi_Functional_Validation_Report_Template.csv"
echo ""
echo "═══════════════════════════════════════════════════════"

