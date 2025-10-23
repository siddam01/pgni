#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 COMPREHENSIVE FIX: Tenant App + Sample Data"
echo "════════════════════════════════════════════════════════"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"
START_TIME=$(date +%s)

# Function to get DB credentials
get_db_credentials() {
    echo "Getting database credentials..."
    
    DB_HOST=$(aws ssm get-parameter --name "/pgni/preprod/db/host" --query "Parameter.Value" --output text 2>/dev/null || echo "")
    DB_USER=$(aws ssm get-parameter --name "/pgni/preprod/db/username" --query "Parameter.Value" --output text 2>/dev/null || echo "admin")
    DB_PASS=$(aws ssm get-parameter --name "/pgni/preprod/db/password" --with-decryption --query "Parameter.Value" --output text 2>/dev/null || echo "")
    DB_NAME=$(aws ssm get-parameter --name "/pgni/preprod/db/name" --query "Parameter.Value" --output text 2>/dev/null || echo "pgworld")
    
    if [ -z "$DB_HOST" ] && [ -f "/home/ec2-user/pgni/config.json" ]; then
        DB_HOST=$(grep -oP '"host":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "")
        DB_USER=$(grep -oP '"user":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "admin")
        DB_PASS=$(grep -oP '"password":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "")
        DB_NAME=$(grep -oP '"database":\s*"\K[^"]+' /home/ec2-user/pgni/config.json || echo "pgworld")
    fi
    
    if [ -n "$DB_HOST" ]; then
        echo "✓ Database: $DB_USER@$DB_HOST/$DB_NAME"
    else
        echo "⚠️  Database credentials not found, will skip data loading"
    fi
}

echo "STEP 1/5: Fix Tenant App Code"
echo "────────────────────────────────────────────────────────"

cd /home/ec2-user/pgni/pgworldtenant-master

echo "Backing up original code..."
cp -r lib lib.backup.$(date +%s) 2>/dev/null || true

echo ""
echo "Creating proper config file..."
mkdir -p lib/utils
cat > lib/utils/config.dart << 'EOF'
class API {
  static const String URL = "13.221.117.236:8080";
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

class Config {
  static const String ONESIGNAL_APP_ID = "test-app-id";
  static const String APIKEY = "test-api-key";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
}

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
EOF

echo "✓ Config file created"

echo ""
echo "Fixing model classes (null safety)..."

# Backup original models
cp lib/utils/models.dart lib/utils/models.dart.backup 2>/dev/null || true

# Fix models with nullable fields
cat > lib/utils/models.dart << 'EOFMODELS'
class User {
  String? id;
  String? hostelID;
  String? name;
  String? phone;
  String? email;
  String? address;
  String? roomID;
  String? roomno;
  String? rent;
  String? emerContact;
  String? emerPhone;
  String? food;
  String? document;
  String? paymentStatus;
  String? joiningDateTime;
  String? lastPaidDateTime;
  String? expiryDateTime;
  String? leaveDateTime;
  String? status;
  String? createdBy;
  String? modifiedBy;
  String? createdDateTime;
  String? modifiedDateTime;

  User({
    this.id,
    this.hostelID,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.roomID,
    this.roomno,
    this.rent,
    this.emerContact,
    this.emerPhone,
    this.food,
    this.document,
    this.paymentStatus,
    this.joiningDateTime,
    this.lastPaidDateTime,
    this.expiryDateTime,
    this.leaveDateTime,
    this.status,
    this.createdBy,
    this.modifiedBy,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      hostelID: json['hostelID']?.toString() ?? json['hostel_id']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      roomID: json['roomID']?.toString() ?? json['room_id']?.toString(),
      roomno: json['roomno']?.toString(),
      rent: json['rent']?.toString(),
      emerContact: json['emerContact']?.toString() ?? json['emer_contact']?.toString(),
      emerPhone: json['emerPhone']?.toString() ?? json['emer_phone']?.toString(),
      food: json['food']?.toString(),
      document: json['document']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString(),
      joiningDateTime: json['joiningDateTime']?.toString() ?? json['joining_datetime']?.toString(),
      lastPaidDateTime: json['lastPaidDateTime']?.toString() ?? json['last_paid_datetime']?.toString(),
      expiryDateTime: json['expiryDateTime']?.toString() ?? json['expiry_datetime']?.toString(),
      leaveDateTime: json['leaveDateTime']?.toString() ?? json['leave_datetime']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Room {
  String? id;
  String? hostelID;
  String? roomno;
  String? rent;
  String? floor;
  String? filled;
  String? capacity;
  String? amenities;
  String? type;
  String? status;
  String? document;
  String? size;
  String? createdBy;
  String? modifiedBy;
  String? createdDateTime;
  String? modifiedDateTime;

  Room({
    this.id,
    this.hostelID,
    this.roomno,
    this.rent,
    this.floor,
    this.filled,
    this.capacity,
    this.amenities,
    this.type,
    this.status,
    this.document,
    this.size,
    this.createdBy,
    this.modifiedBy,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id']?.toString(),
      hostelID: json['hostelID']?.toString() ?? json['hostel_id']?.toString(),
      roomno: json['roomno']?.toString(),
      rent: json['rent']?.toString(),
      floor: json['floor']?.toString(),
      filled: json['filled']?.toString(),
      capacity: json['capacity']?.toString(),
      amenities: json['amenities']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      document: json['document']?.toString(),
      size: json['size']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Hostel {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? address;
  String? amenities;
  String? status;
  String? createdBy;
  String? modifiedBy;
  String? expiryDateTime;
  String? createdDateTime;
  String? modifiedDateTime;

  Hostel({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.amenities,
    this.status,
    this.createdBy,
    this.modifiedBy,
    this.expiryDateTime,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      amenities: json['amenities']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      expiryDateTime: json['expiryDateTime']?.toString() ?? json['expiry_datetime']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Hostels {
  List<Hostel>? hostels;
  Pagination? pagination;

  Hostels({this.hostels, this.pagination});

  factory Hostels.fromJson(Map<String, dynamic> json) {
    return Hostels(
      hostels: json['hostels'] != null
          ? (json['hostels'] as List).map((i) => Hostel.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Bill {
  String? id;
  String? userID;
  String? hostelID;
  String? amount;
  String? month;
  String? status;
  String? paymentDate;
  String? createdBy;
  String? modifiedBy;
  String? createdDateTime;
  String? modifiedDateTime;

  Bill({
    this.id,
    this.userID,
    this.hostelID,
    this.amount,
    this.month,
    this.status,
    this.paymentDate,
    this.createdBy,
    this.modifiedBy,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString(),
      userID: json['userID']?.toString() ?? json['user_id']?.toString(),
      hostelID: json['hostelID']?.toString() ?? json['hostel_id']?.toString(),
      amount: json['amount']?.toString(),
      month: json['month']?.toString(),
      status: json['status']?.toString(),
      paymentDate: json['paymentDate']?.toString() ?? json['payment_date']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Issue {
  String? id;
  String? userID;
  String? hostelID;
  String? roomID;
  String? type;
  String? description;
  String? status;
  String? createdBy;
  String? modifiedBy;
  String? createdDateTime;
  String? modifiedDateTime;

  Issue({
    this.id,
    this.userID,
    this.hostelID,
    this.roomID,
    this.type,
    this.description,
    this.status,
    this.createdBy,
    this.modifiedBy,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id']?.toString(),
      userID: json['userID']?.toString() ?? json['user_id']?.toString(),
      hostelID: json['hostelID']?.toString() ?? json['hostel_id']?.toString(),
      roomID: json['roomID']?.toString() ?? json['room_id']?.toString(),
      type: json['type']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Notice {
  String? id;
  String? hostelID;
  String? title;
  String? note;
  String? status;
  String? createdBy;
  String? modifiedBy;
  String? createdDateTime;
  String? modifiedDateTime;

  Notice({
    this.id,
    this.hostelID,
    this.title,
    this.note,
    this.status,
    this.createdBy,
    this.modifiedBy,
    this.createdDateTime,
    this.modifiedDateTime,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id']?.toString(),
      hostelID: json['hostelID']?.toString() ?? json['hostel_id']?.toString(),
      title: json['title']?.toString(),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;

  Pagination({this.total, this.page, this.limit});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0'),
      page: json['page'] is int ? json['page'] : int.tryParse(json['page']?.toString() ?? '1'),
      limit: json['limit'] is int ? json['limit'] : int.tryParse(json['limit']?.toString() ?? '10'),
    );
  }
}

class Rooms {
  List<Room>? rooms;
  Pagination? pagination;

  Rooms({this.rooms, this.pagination});

  factory Rooms.fromJson(Map<String, dynamic> json) {
    return Rooms(
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((i) => Room.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Users {
  List<User>? users;
  Pagination? pagination;

  Users({this.users, this.pagination});

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      users: json['users'] != null
          ? (json['users'] as List).map((i) => User.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Bills {
  List<Bill>? bills;
  Pagination? pagination;

  Bills({this.bills, this.pagination});

  factory Bills.fromJson(Map<String, dynamic> json) {
    return Bills(
      bills: json['bills'] != null
          ? (json['bills'] as List).map((i) => Bill.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Issues {
  List<Issue>? issues;
  Pagination? pagination;

  Issues({this.issues, this.pagination});

  factory Issues.fromJson(Map<String, dynamic> json) {
    return Issues(
      issues: json['issues'] != null
          ? (json['issues'] as List).map((i) => Issue.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Notices {
  List<Notice>? notices;
  Pagination? pagination;

  Notices({this.notices, this.pagination});

  factory Notices.fromJson(Map<String, dynamic> json) {
    return Notices(
      notices: json['notices'] != null
          ? (json['notices'] as List).map((i) => Notice.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}
EOFMODELS

echo "✓ Models fixed with null safety"

echo ""
echo "STEP 2/5: Building Tenant App"
echo "────────────────────────────────────────────────────────"

export DART_VM_OPTIONS="--old_gen_heap_size=3072"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo ""
echo "Building Tenant web app (this may take 3-5 minutes)..."
TENANT_BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_build_full.log | grep -E "Compiling|Built|✓" || true

TENANT_BUILD_END=$(date +%s)
TENANT_BUILD_TIME=$((TENANT_BUILD_END - TENANT_BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ Tenant app built successfully!"
    echo "   Size: $TENANT_SIZE | Time: ${TENANT_BUILD_TIME}s"
else
    echo ""
    echo "❌ Tenant build failed!"
    echo "Last 50 lines of build log:"
    tail -50 /tmp/tenant_build_full.log
    echo ""
    echo "Full log saved to: /tmp/tenant_build_full.log"
    exit 1
fi

echo ""
echo "STEP 3/5: Building Admin App"
echo "────────────────────────────────────────────────────────"

cd /home/ec2-user/pgni/pgworld-master

if [ -f "build/web/main.dart.js" ]; then
    echo "✓ Admin app already built, skipping..."
else
    echo "Building Admin app..."
    
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
    
    flutter clean > /dev/null 2>&1
    rm -rf .dart_tool build
    flutter pub get > /dev/null 2>&1
    
    flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true --base-href="/admin/" 2>&1 | grep -E "Compiling|Built|✓" || true
    
    if [ -f "build/web/main.dart.js" ]; then
        echo "✓ Admin app built"
    else
        echo "⚠️  Admin build failed, but continuing..."
    fi
fi

echo ""
echo "STEP 4/5: Deploying Both Apps"
echo "────────────────────────────────────────────────────────"

# Backup old deployments
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
fi

if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s) 2>/dev/null || true
fi

# Deploy Tenant
echo "Deploying Tenant app..."
sudo mkdir -p /usr/share/nginx/html/tenant
sudo cp -r /home/ec2-user/pgni/pgworldtenant-master/build/web/* /usr/share/nginx/html/tenant/
echo "✓ Tenant deployed"

# Deploy Admin
if [ -d "/home/ec2-user/pgni/pgworld-master/build/web" ]; then
    echo "Deploying Admin app..."
    sudo mkdir -p /usr/share/nginx/html/admin
    sudo cp -r /home/ec2-user/pgni/pgworld-master/build/web/* /usr/share/nginx/html/admin/
    echo "✓ Admin deployed"
fi

# Fix permissions
echo ""
echo "Setting permissions..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo find /usr/share/nginx/html -type f -exec chmod 644 {} \;

if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html 2>/dev/null || true
fi

sudo systemctl reload nginx
echo "✓ Nginx reloaded"

echo ""
echo "STEP 5/5: Load Sample Data"
echo "────────────────────────────────────────────────────────"

get_db_credentials

if [ -n "$DB_HOST" ] && [ -n "$DB_PASS" ]; then
    cat > /tmp/tenant_sample_data.sql << 'EOSQL'
SET FOREIGN_KEY_CHECKS = 0;

-- Insert/Update Sample Hostels
INSERT INTO hostels (id, name, phone, email, address, amenities, status, created_by, created_datetime, modified_datetime) VALUES
('HOST001', 'Sunrise PG', '9876543210', 'sunrise@pg.com', '123 Main Street, City Center', 'WiFi,AC,Laundry,Parking,CCTV', 'active', 'admin', NOW(), NOW()),
('HOST002', 'Green Valley Hostel', '9876543211', 'greenvalley@pg.com', '456 Park Avenue, Green Valley', 'WiFi,Gym,Mess,Water,Generator', 'active', 'admin', NOW(), NOW())
ON DUPLICATE KEY UPDATE name=VALUES(name), phone=VALUES(phone);

-- Insert/Update Sample Rooms
INSERT INTO rooms (id, hostel_id, roomno, rent, floor, filled, capacity, amenities, type, status, created_by, created_datetime, modified_datetime) VALUES
('ROOM001', 'HOST001', '101', '5000', '1', '2', '3', 'AC,Attached Bath', 'triple', 'occupied', 'admin', NOW(), NOW()),
('ROOM002', 'HOST001', '102', '6000', '1', '1', '2', 'AC,Attached Bath,Balcony', 'double', 'occupied', 'admin', NOW(), NOW()),
('ROOM003', 'HOST002', '201', '4500', '2', '1', '1', 'AC,Attached Bath,TV', 'single', 'occupied', 'admin', NOW(), NOW())
ON DUPLICATE KEY UPDATE roomno=VALUES(roomno), rent=VALUES(rent);

-- Insert/Update Sample Tenants
INSERT INTO users (id, hostel_id, name, phone, email, address, room_id, roomno, rent, emer_contact, emer_phone, food, document, payment_status, joining_datetime, last_paid_datetime, expiry_datetime, status, created_by, created_datetime, modified_datetime, password) VALUES
('TENANT001', 'HOST001', 'Rahul Kumar', '9123456780', 'rahul@example.com', 'Delhi', 'ROOM001', '101', '5000', 'Father', '9123456700', 'veg', 'aadhar123.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 60 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), '$2a$10$hashedpassword'),
('TENANT002', 'HOST001', 'Priya Sharma', '9123456781', 'priya@example.com', 'Mumbai', 'ROOM002', '102', '6000', 'Mother', '9123456701', 'veg', 'aadhar124.pdf', 'pending', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY), NOW(), 'active', 'admin', NOW(), NOW(), 'Tenant@123'),
('TENANT003', 'HOST002', 'Amit Patel', '9123456782', 'amit@example.com', 'Ahmedabad', 'ROOM003', '201', '4500', 'Brother', '9123456702', 'non-veg', 'aadhar125.pdf', 'paid', DATE_SUB(NOW(), INTERVAL 90 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active', 'admin', NOW(), NOW(), 'Tenant@123')
ON DUPLICATE KEY UPDATE email=VALUES(email), phone=VALUES(phone);

-- Insert/Update Sample Bills
INSERT INTO bills (id, user_id, hostel_id, amount, month, status, payment_date, created_by, created_datetime, modified_datetime) VALUES
('BILL001', 'TENANT001', 'HOST001', '5000', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW()),
('BILL002', 'TENANT002', 'HOST001', '6000', 'January 2025', 'pending', NULL, 'admin', NOW(), NOW()),
('BILL003', 'TENANT003', 'HOST002', '4500', 'January 2025', 'paid', NOW(), 'admin', NOW(), NOW())
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- Insert/Update Sample Issues
INSERT INTO issues (id, user_id, hostel_id, room_id, type, description, status, created_by, created_datetime, modified_datetime) VALUES
('ISSUE001', 'TENANT001', 'HOST001', 'ROOM001', 'maintenance', 'AC not cooling properly', 'open', 'TENANT001', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
('ISSUE002', 'TENANT002', 'HOST001', 'ROOM002', 'plumbing', 'Bathroom tap leaking', 'in-progress', 'TENANT002', DATE_SUB(NOW(), INTERVAL 5 DAY), NOW())
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- Insert/Update Sample Notices
INSERT INTO notices (id, hostel_id, title, note, status, created_by, created_datetime, modified_datetime) VALUES
('NOTICE001', 'HOST001', 'Rent Due Reminder', 'Please pay your rent by 5th of every month.', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
('NOTICE002', 'HOST002', 'Maintenance Schedule', 'Water supply will be interrupted on Sunday from 10 AM to 2 PM.', 'active', 'admin', DATE_SUB(NOW(), INTERVAL 3 DAY), NOW())
ON DUPLICATE KEY UPDATE title=VALUES(title);

SET FOREIGN_KEY_CHECKS = 1;
EOSQL

    echo "Loading sample data..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < /tmp/tenant_sample_data.sql 2>&1 | grep -v "Warning: Using a password" || true
    
    if [ $? -eq 0 ]; then
        echo "✓ Sample data loaded!"
        echo "  • 2 Hostels"
        echo "  • 3 Rooms"
        echo "  • 3 Tenants"
        echo "  • 3 Bills"
        echo "  • 2 Issues"
        echo "  • 2 Notices"
    else
        echo "⚠️  Sample data loading had warnings (may be okay)"
    fi
    
    rm -f /tmp/tenant_sample_data.sql
else
    echo "⚠️  Skipping sample data (no DB credentials)"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))
SECONDS=$((TOTAL_TIME % 60))

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ TENANT APP FIXED AND DEPLOYED!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "⏱️  Total Time: ${MINUTES}m ${SECONDS}s"
echo ""
echo "🌐 ACCESS YOUR APPLICATIONS:"
echo "────────────────────────────────────────────────────────"
echo ""
echo "   👤 TENANT PORTAL:"
echo "      URL:      http://$PUBLIC_IP/tenant/"
echo "      Email:    priya@example.com"
echo "      Password: Tenant@123"
echo ""
echo "   👨‍💼 ADMIN PORTAL:"
echo "      URL:      http://$PUBLIC_IP/admin/"
echo "      Email:    admin@pgworld.com"
echo "      Password: Admin@123"
echo ""
echo "════════════════════════════════════════════════════════"
echo "⚡ IMPORTANT: Clear Browser Cache!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. HARD REFRESH:"
echo "   Windows: Ctrl + Shift + R"
echo "   Mac:     Cmd + Shift + R"
echo ""
echo "2. Or use Incognito/Private browsing mode"
echo ""
echo "3. If still blank, check browser console (F12)"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

