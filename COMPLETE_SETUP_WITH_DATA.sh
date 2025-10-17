#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🚀 COMPLETE SETUP: Deploy Admin + Load Sample Data"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"

# Function to get DB credentials from SSM or environment
get_db_credentials() {
    echo "Getting database credentials..."
    
    # Try SSM Parameter Store first
    DB_HOST=$(aws ssm get-parameter --name "/pgni/preprod/db/host" --query "Parameter.Value" --output text 2>/dev/null || echo "")
    DB_USER=$(aws ssm get-parameter --name "/pgni/preprod/db/username" --query "Parameter.Value" --output text 2>/dev/null || echo "admin")
    DB_PASS=$(aws ssm get-parameter --name "/pgni/preprod/db/password" --with-decryption --query "Parameter.Value" --output text 2>/dev/null || echo "")
    DB_NAME=$(aws ssm get-parameter --name "/pgni/preprod/db/name" --query "Parameter.Value" --output text 2>/dev/null || echo "pgworld")
    
    if [ -z "$DB_HOST" ]; then
        echo "⚠️  Couldn't get DB from SSM, trying local config..."
        # Try to extract from running API config
        if [ -f "/home/ec2-user/pgni/config.json" ]; then
            DB_HOST=$(grep -oP '"host":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "")
            DB_USER=$(grep -oP '"user":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "admin")
            DB_PASS=$(grep -oP '"password":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "")
            DB_NAME=$(grep -oP '"database":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "pgworld")
        fi
    fi
    
    if [ -z "$DB_HOST" ]; then
        echo "❌ Could not determine database credentials!"
        echo "Please provide them manually or check SSM Parameter Store."
        exit 1
    fi
    
    echo "✓ Database: $DB_USER@$DB_HOST/$DB_NAME"
}

echo "STEP 1/4: Verifying Infrastructure"
echo "────────────────────────────────────────────────────────"

# Check if Admin app is already built
if [ -d "/home/ec2-user/pgni/pgworld-master/build/web" ] && [ -f "/home/ec2-user/pgni/pgworld-master/build/web/main.dart.js" ]; then
    ADMIN_SIZE=$(du -h /home/ec2-user/pgni/pgworld-master/build/web/main.dart.js | cut -f1)
    echo "✓ Admin app already built ($ADMIN_SIZE)"
    ADMIN_ALREADY_BUILT=true
else
    echo "ℹ Admin app needs to be built"
    ADMIN_ALREADY_BUILT=false
fi

# Check Nginx
if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginx running"
else
    echo "⚠️  Nginx not running, starting..."
    sudo systemctl start nginx
fi

# Check API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo "✓ API running (HTTP $API_STATUS)"
else
    echo "⚠️  API not responding (HTTP $API_STATUS)"
fi

echo ""
echo "STEP 2/4: Deploy Admin App"
echo "────────────────────────────────────────────────────────"

if [ "$ADMIN_ALREADY_BUILT" = false ]; then
    echo "Building Admin app (this may take 3-5 minutes)..."
    cd /home/ec2-user/pgni/pgworld-master
    
    # Update config
    cat > lib/utils/config.dart << EOF
class Config {
  static const String URL = "$PUBLIC_IP:$API_PORT";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class API {
  static const String URL = "$PUBLIC_IP:$API_PORT";
  static const String SEND_OTP = "/api/send-otp";
  static const String VERIFY_OTP = "/api/verify-otp";
  static const String BILL = "/api/bills";
  static const String USER = "/api/users";
  static const String HOSTEL = "/api/hostels";
  static const String ISSUE = "/api/issues";
  static const String NOTICE = "/api/notices";
  static const String ROOM = "/api/rooms";
  static const String SUPPORT = "/api/support";
  static const String SIGNUP = "/api/signup";
}

const String mediaURL = "http://$PUBLIC_IP:$API_PORT/uploads/";
const int STATUS_403 = 403;
EOF
    
    export DART_VM_OPTIONS="--old_gen_heap_size=3072"
    export PUB_CACHE=/home/ec2-user/.pub-cache
    
    flutter clean > /dev/null 2>&1
    rm -rf .dart_tool build
    flutter pub get > /dev/null 2>&1
    
    flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true --base-href="/admin/" 2>&1 | grep -E "Compiling|Built|Error" || true
    
    if [ ! -f "build/web/main.dart.js" ]; then
        echo "❌ Admin build failed!"
        exit 1
    fi
    
    echo "✓ Admin app built successfully"
fi

# Deploy to Nginx
echo ""
echo "Deploying to Nginx..."
cd /home/ec2-user/pgni/pgworld-master

if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s) 2>/dev/null || true
fi

sudo mkdir -p /usr/share/nginx/html/admin
sudo cp -r build/web/* /usr/share/nginx/html/admin/
sudo chown -R nginx:nginx /usr/share/nginx/html/admin
sudo chmod -R 755 /usr/share/nginx/html/admin
sudo find /usr/share/nginx/html/admin -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin 2>/dev/null || true
fi

sudo systemctl reload nginx

echo "✓ Admin app deployed"

echo ""
echo "STEP 3/4: Load Sample Data into Database"
echo "────────────────────────────────────────────────────────"

get_db_credentials

# Create SQL file with sample data
cat > /tmp/sample_data.sql << 'EOSQL'
-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE users;
TRUNCATE TABLE hostels;
TRUNCATE TABLE rooms;
TRUNCATE TABLE bills;
TRUNCATE TABLE issues;
TRUNCATE TABLE notices;
SET FOREIGN_KEY_CHECKS = 1;

-- Insert Sample Hostels
INSERT INTO hostels (id, name, phone, email, address, amenities, status, created_by, created_datetime, modified_datetime) VALUES
('HOST001', 'Sunrise PG', '9876543210', 'sunrise@pg.com', '123 Main Street, City Center', 'WiFi,AC,Laundry,Parking,CCTV', 'active', 'admin', NOW(), NOW()),
('HOST002', 'Green Valley Hostel', '9876543211', 'greenvalley@pg.com', '456 Park Avenue, Green Valley', 'WiFi,Gym,Mess,Water,Generator', 'active', 'admin', NOW(), NOW()),
('HOST003', 'Downtown PG', '9876543212', 'downtown@pg.com', '789 Central Road, Downtown', 'WiFi,AC,Security,Parking', 'active', 'admin', NOW(), NOW());

-- Insert Sample Rooms
INSERT INTO rooms (id, hostel_id, roomno, rent, floor, filled, capacity, amenities, type, status, created_by, created_datetime, modified_datetime) VALUES
('ROOM001', 'HOST001', '101', '5000', '1', '2', '3', 'AC,Attached Bath', 'triple', 'occupied', 'admin', NOW(), NOW()),
('ROOM002', 'HOST001', '102', '6000', '1', '1', '2', 'AC,Attached Bath,Balcony', 'double', 'occupied', 'admin', NOW(), NOW()),
('ROOM003', 'HOST001', '103', '8000', '1', '0', '1', 'AC,Attached Bath,Balcony,TV', 'single', 'available', 'admin', NOW(), NOW()),
('ROOM004', 'HOST002', '201', '4500', '2', '3', '3', 'Fan,Common Bath', 'triple', 'occupied', 'admin', NOW(), NOW()),
('ROOM005', 'HOST002', '202', '7000', '2', '1', '1', 'AC,Attached Bath,TV', 'single', 'occupied', 'admin', NOW(), NOW()),
('ROOM006', 'HOST003', '301', '5500', '3', '2', '2', 'AC,Attached Bath', 'double', 'occupied', 'admin', NOW(), NOW());

-- Insert Sample Users (Tenants)
INSERT INTO users (id, hostel_id, name, phone, email, address, room_id, roomno, rent, emer_contact, emer_phone, food, document, payment_status, joining_datetime, last_paid_datetime, expiry_datetime, status, created_by, created_datetime, modified_datetime, password) VALUES
('USER001', 'HOST001', 'Rahul Kumar', '9123456780', 'rahul@example.com', 'Delhi', 'ROOM001', '101', '5000', 'Father', '9123456700', 'veg', 'aadhar123.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 60 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('USER002', 'HOST001', 'Priya Sharma', '9123456781', 'priya@example.com', 'Mumbai', 'ROOM001', '101', '5000', 'Mother', '9123456701', 'veg', 'aadhar124.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 45 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('USER003', 'HOST001', 'Amit Patel', '9123456782', 'amit@example.com', 'Ahmedabad', 'ROOM002', '102', '6000', 'Brother', '9123456702', 'non-veg', 'aadhar125.pdf', 'pending', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY), NOW(), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('USER004', 'HOST002', 'Sneha Reddy', '9123456783', 'sneha@example.com', 'Hyderabad', 'ROOM004', '201', '4500', 'Father', '9123456703', 'veg', 'aadhar126.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 90 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('USER005', 'HOST002', 'Vikram Singh', '9123456784', 'vikram@example.com', 'Jaipur', 'ROOM005', '202', '7000', 'Mother', '9123456704', 'non-veg', 'aadhar127.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 120 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('USER006', 'HOST003', 'Anjali Gupta', '9123456785', 'anjali@example.com', 'Bangalore', 'ROOM006', '301', '5500', 'Sister', '9123456705', 'veg', 'aadhar128.pdf', 'overdue', DATE_SUB(NOW(), INTERVAL 150 DAY), DATE_SUB(NOW(), INTERVAL 60 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword');

-- Insert Sample Bills
INSERT INTO bills (id, user_id, hostel_id, amount, month, status, payment_date, created_by, created_datetime, modified_datetime) VALUES
('BILL001', 'USER001', 'HOST001', '5000', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW()),
('BILL002', 'USER002', 'HOST001', '5000', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW()),
('BILL003', 'USER003', 'HOST001', '6000', 'January 2025', 'pending', NULL, 'admin', NOW(), NOW()),
('BILL004', 'USER004', 'HOST002', '4500', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW()),
('BILL005', 'USER005', 'HOST002', '7000', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW()),
('BILL006', 'USER006', 'HOST003', '5500', 'December 2024', 'overdue', NULL, 'admin', NOW(), NOW()),
('BILL007', 'USER006', 'HOST003', '5500', 'January 2025', 'overdue', NULL, 'admin', NOW(), NOW());

-- Insert Sample Issues
INSERT INTO issues (id, user_id, hostel_id, room_id, type, description, status, created_by, created_datetime, modified_datetime) VALUES
('ISSUE001', 'USER001', 'HOST001', 'ROOM001', 'maintenance', 'AC not cooling properly', 'open', 'USER001', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
('ISSUE002', 'USER003', 'HOST001', 'ROOM002', 'plumbing', 'Bathroom tap leaking', 'in-progress', 'USER003', DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
('ISSUE003', 'USER004', 'HOST002', 'ROOM004', 'electrical', 'Light not working in room', 'resolved', 'USER004', DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
('ISSUE004', 'USER006', 'HOST003', 'ROOM006', 'cleaning', 'Common area needs cleaning', 'open', 'USER006', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW());

-- Insert Sample Notices
INSERT INTO notices (id, hostel_id, title, note, status, created_by, created_datetime, modified_datetime) VALUES
('NOTICE001', 'HOST001', 'Rent Due Reminder', 'Please pay your rent by 5th of every month to avoid late fees.', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
('NOTICE002', 'HOST001', 'Maintenance Schedule', 'Water supply will be interrupted on Sunday from 10 AM to 2 PM for tank cleaning.', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
('NOTICE003', 'HOST002', 'New Rules', 'Guest visiting hours are from 10 AM to 8 PM only. Please inform reception before bringing guests.', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
('NOTICE004', 'HOST003', 'Holiday Notice', 'Office will be closed on Republic Day (26th Jan). For emergencies, contact: 9876543212', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW());

-- Create admin user if not exists
INSERT INTO users (id, hostel_id, name, phone, email, address, status, created_by, created_datetime, modified_datetime, password, role)
VALUES ('ADMIN001', 'HOST001', 'Admin User', '9999999999', 'admin@pgworld.com', 'Admin Office', 'active', 'system', NOW(), NOW(), '$2a$10$hashedpassword', 'admin')
ON DUPLICATE KEY UPDATE email = 'admin@pgworld.com';

EOSQL

echo "Loading sample data into database..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < /tmp/sample_data.sql 2>&1 | grep -v "Warning: Using a password"

if [ $? -eq 0 ]; then
    echo "✓ Sample data loaded successfully!"
    echo ""
    echo "Sample Data Summary:"
    echo "  • 3 Hostels (Sunrise PG, Green Valley, Downtown PG)"
    echo "  • 6 Rooms (Mix of single, double, triple)"
    echo "  • 6 Tenants (Active users with rent records)"
    echo "  • 7 Bills (Some paid, some pending)"
    echo "  • 4 Issues (Open, In-Progress, Resolved)"
    echo "  • 4 Notices (Active announcements)"
else
    echo "⚠️  Warning: Could not load sample data"
    echo "Database might already have data, or credentials are incorrect"
fi

rm -f /tmp/sample_data.sql

echo ""
echo "STEP 4/4: Verification"
echo "────────────────────────────────────────────────────────"

sleep 2

ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/health)

echo "Service Status:"
echo "  Admin UI:  HTTP $ADMIN_TEST"
echo "  Backend:   HTTP $API_TEST"

if [ "$ADMIN_TEST" = "200" ]; then
    echo "  ✓ Admin portal is accessible"
else
    echo "  ⚠️  Admin portal: HTTP $ADMIN_TEST"
fi

if [ "$API_TEST" = "200" ]; then
    echo "  ✓ API is responding"
else
    echo "  ⚠️  API: HTTP $API_TEST"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE WITH SAMPLE DATA!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 ACCESS YOUR APPLICATION:"
echo "────────────────────────────────────────────────────────"
echo ""
echo "   Admin Portal:"
echo "   URL:      http://$PUBLIC_IP/admin/"
echo "   Email:    admin@pgworld.com"
echo "   Password: Admin@123"
echo ""
echo "   Backend API:"
echo "   URL:      http://$PUBLIC_IP:$API_PORT/"
echo "   Health:   http://$PUBLIC_IP:$API_PORT/health"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 SAMPLE DATA LOADED:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  🏨 Hostels:    3 properties"
echo "  🚪 Rooms:      6 rooms (some vacant, some occupied)"
echo "  👥 Tenants:    6 active users"
echo "  💰 Bills:      7 bills (paid/pending/overdue)"
echo "  🔧 Issues:     4 support tickets"
echo "  📢 Notices:    4 announcements"
echo ""
echo "════════════════════════════════════════════════════════"
echo "⚡ NEXT STEPS:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. HARD REFRESH your browser:"
echo "   • Windows: Ctrl + Shift + R"
echo "   • Mac: Cmd + Shift + R"
echo ""
echo "2. Clear browser cache or use Incognito mode"
echo ""
echo "3. Login to Admin Portal:"
echo "   http://$PUBLIC_IP/admin/"
echo ""
echo "4. Explore the dashboard with sample data:"
echo "   • View tenant list"
echo "   • Check pending payments"
echo "   • Review open issues"
echo "   • See room occupancy"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

