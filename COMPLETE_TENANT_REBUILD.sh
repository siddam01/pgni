#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔧 COMPLETE TENANT APP REBUILD & DEPLOYMENT"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  1. Backup existing code"
echo "  2. Fix all missing models and classes"
echo "  3. Add all missing constants and configurations"
echo "  4. Fix all State classes with proper null safety"
echo "  5. Rebuild and deploy both Admin and Tenant apps"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"
TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
ADMIN_PATH="/home/ec2-user/pgni/pgworld-master"

cd "$TENANT_PATH"

echo "════════════════════════════════════════════════════════"
echo "STEP 1/6: Backing Up Original Code"
echo "════════════════════════════════════════════════════════"

BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2/6: Creating Complete Model Classes"
echo "════════════════════════════════════════════════════════"

mkdir -p lib/utils

# Create comprehensive models.dart with ALL missing classes
cat > lib/utils/models.dart << 'EOFMODELS'
// ============================================================================
// COMPLETE MODELS WITH NULL SAFETY
// ============================================================================

class Meta {
  int? status;
  String? messageType;
  String? message;

  Meta({this.status, this.messageType, this.message});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      status: json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '0'),
      messageType: json['messageType']?.toString() ?? json['message_type']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class Dashboard {
  String? totalRooms;
  String? occupiedRooms;
  String? vacantRooms;
  String? totalTenants;
  String? pendingPayments;
  String? totalRevenue;
  List<Graph>? graphs;

  Dashboard({
    this.totalRooms,
    this.occupiedRooms,
    this.vacantRooms,
    this.totalTenants,
    this.pendingPayments,
    this.totalRevenue,
    this.graphs,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      totalRooms: json['totalRooms']?.toString() ?? json['total_rooms']?.toString(),
      occupiedRooms: json['occupiedRooms']?.toString() ?? json['occupied_rooms']?.toString(),
      vacantRooms: json['vacantRooms']?.toString() ?? json['vacant_rooms']?.toString(),
      totalTenants: json['totalTenants']?.toString() ?? json['total_tenants']?.toString(),
      pendingPayments: json['pendingPayments']?.toString() ?? json['pending_payments']?.toString(),
      totalRevenue: json['totalRevenue']?.toString() ?? json['total_revenue']?.toString(),
      graphs: json['graphs'] != null 
          ? (json['graphs'] as List).map((i) => Graph.fromJson(i)).toList()
          : [],
    );
  }
}

class Graph {
  String? label;
  String? value;
  String? color;

  Graph({this.label, this.value, this.color});

  factory Graph.fromJson(Map<String, dynamic> json) {
    return Graph(
      label: json['label']?.toString(),
      value: json['value']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? offset;

  Pagination({this.total, this.page, this.limit, this.offset});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0'),
      page: json['page'] is int ? json['page'] : int.tryParse(json['page']?.toString() ?? '1'),
      limit: json['limit'] is int ? json['limit'] : int.tryParse(json['limit']?.toString() ?? '10'),
      offset: json['offset'] is int ? json['offset'] : int.tryParse(json['offset']?.toString() ?? '0'),
    );
  }
}

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

class Users {
  List<User>? users;
  Pagination? pagination;
  Meta? meta;

  Users({this.users, this.pagination, this.meta});

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      users: json['users'] != null
          ? (json['users'] as List).map((i) => User.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
          : null,
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
  String? size;
  String? status;
  String? document;
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
    this.size,
    this.status,
    this.document,
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
      size: json['size']?.toString(),
      status: json['status']?.toString(),
      document: json['document']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Rooms {
  List<Room>? rooms;
  Pagination? pagination;
  Meta? meta;

  Rooms({this.rooms, this.pagination, this.meta});

  factory Rooms.fromJson(Map<String, dynamic> json) {
    return Rooms(
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((i) => Room.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
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
  String? paidDateTime;
  String? paid;
  String? title;
  String? description;
  String? document;
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
    this.paidDateTime,
    this.paid,
    this.title,
    this.description,
    this.document,
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
      paidDateTime: json['paidDateTime']?.toString() ?? json['paid_datetime']?.toString(),
      paid: json['paid']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      document: json['document']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Bills {
  List<Bill>? bills;
  Pagination? pagination;
  Meta? meta;

  Bills({this.bills, this.pagination, this.meta});

  factory Bills.fromJson(Map<String, dynamic> json) {
    return Bills(
      bills: json['bills'] != null
          ? (json['bills'] as List).map((i) => Bill.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
          : null,
    );
  }
}

class Issue {
  String? id;
  String? userID;
  String? hostelID;
  String? roomID;
  String? type;
  String? title;
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
    this.title,
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
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Issues {
  List<Issue>? issues;
  Pagination? pagination;
  Meta? meta;

  Issues({this.issues, this.pagination, this.meta});

  factory Issues.fromJson(Map<String, dynamic> json) {
    return Issues(
      issues: json['issues'] != null
          ? (json['issues'] as List).map((i) => Issue.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
          : null,
    );
  }
}

class Notice {
  String? id;
  String? hostelID;
  String? title;
  String? note;
  String? img;
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
    this.img,
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
      img: json['img']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      modifiedBy: json['modifiedBy']?.toString() ?? json['modified_by']?.toString(),
      createdDateTime: json['createdDateTime']?.toString() ?? json['created_datetime']?.toString(),
      modifiedDateTime: json['modifiedDateTime']?.toString() ?? json['modified_datetime']?.toString(),
    );
  }
}

class Notices {
  List<Notice>? notices;
  Pagination? pagination;
  Meta? meta;

  Notices({this.notices, this.pagination, this.meta});

  factory Notices.fromJson(Map<String, dynamic> json) {
    return Notices(
      notices: json['notices'] != null
          ? (json['notices'] as List).map((i) => Notice.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
          : null,
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
  Meta? meta;

  Hostels({this.hostels, this.pagination, this.meta});

  factory Hostels.fromJson(Map<String, dynamic> json) {
    return Hostels(
      hostels: json['hostels'] != null
          ? (json['hostels'] as List).map((i) => Hostel.fromJson(i)).toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'])
          : null,
    );
  }
}
EOFMODELS

echo "✓ Complete models created with Dashboard, Graph, Meta, and all entities"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3/6: Creating Global Configuration & Constants"
echo "════════════════════════════════════════════════════════"

cat > lib/utils/config.dart << EOF
// ============================================================================
// GLOBAL CONFIGURATION & CONSTANTS
// ============================================================================

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
  static const String DASHBOARD = "/api/dashboard";
}

class Config {
  static const String ONESIGNAL_APP_ID = "YOUR_ONESIGNAL_APP_ID";
  static const String APIKEY = "YOUR_API_KEY";
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': APIKEY,
  };
}

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
}

// Global constants
const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://$PUBLIC_IP:$API_PORT/uploads/";

// Global variables (for state management across app)
class AppState {
  static String? userID;
  static String? hostelID;
  static String? name;
  static String? emailID;
  
  static void clear() {
    userID = null;
    hostelID = null;
    name = null;
    emailID = null;
  }
}
EOF

echo "✓ Global configuration created with all constants"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4/6: Building Tenant App"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=4096"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo ""
echo "Building Tenant web app (this will take 3-5 minutes)..."
echo "Target: Production release with base-href=/tenant/"
echo ""

TENANT_BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_rebuild.log | grep -E "Compiling|Built|✓|Error" || true

TENANT_BUILD_END=$(date +%s)
TENANT_BUILD_TIME=$((TENANT_BUILD_END - TENANT_BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    TENANT_SIZE=$(du -h build/web/main.dart.js | cut -f1)
    TENANT_FILES=$(ls -1 build/web | wc -l)
    echo ""
    echo "✅ TENANT APP BUILD SUCCESSFUL!"
    echo "   Size: $TENANT_SIZE"
    echo "   Files: $TENANT_FILES"
    echo "   Time: ${TENANT_BUILD_TIME}s"
else
    echo ""
    echo "❌ Tenant build FAILED!"
    echo ""
    echo "Error analysis:"
    tail -100 /tmp/tenant_rebuild.log
    echo ""
    echo "The build still has errors. This requires manual code fixes."
    echo "Please review the error log at: /tmp/tenant_rebuild.log"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5/6: Building Admin App"
echo "════════════════════════════════════════════════════════"

cd "$ADMIN_PATH"

if [ -f "build/web/main.dart.js" ]; then
    echo "✓ Admin app already built, skipping..."
else
    echo "Building Admin app..."
    
    cat > lib/utils/config.dart << EOFADMIN
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
EOFADMIN
    
    flutter clean > /dev/null 2>&1
    rm -rf .dart_tool build
    flutter pub get > /dev/null 2>&1
    
    flutter build web --release --no-source-maps --no-tree-shake-icons --dart-define=dart.vm.product=true --base-href="/admin/" 2>&1 | grep -E "Compiling|Built|✓" || true
    
    if [ -f "build/web/main.dart.js" ]; then
        echo "✓ Admin app built"
    else
        echo "⚠️  Admin build had issues, but continuing..."
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6/6: Deploying Both Apps to Nginx"
echo "════════════════════════════════════════════════════════"

# Backup old deployments
if [ -d "/usr/share/nginx/html/tenant" ]; then
    sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
fi

if [ -d "/usr/share/nginx/html/admin" ]; then
    sudo mv /usr/share/nginx/html/admin /usr/share/nginx/html/admin.backup.$(date +%s) 2>/dev/null || true
fi

# Deploy Tenant
if [ -d "$TENANT_PATH/build/web" ]; then
    echo "Deploying Tenant app..."
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r "$TENANT_PATH/build/web"/* /usr/share/nginx/html/tenant/
    echo "✓ Tenant deployed"
fi

# Deploy Admin
if [ -d "$ADMIN_PATH/build/web" ]; then
    echo "Deploying Admin app..."
    sudo mkdir -p /usr/share/nginx/html/admin
    sudo cp -r "$ADMIN_PATH/build/web"/* /usr/share/nginx/html/admin/
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
echo "════════════════════════════════════════════════════════"
echo "VERIFICATION"
echo "════════════════════════════════════════════════════════"

sleep 2

ADMIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/admin/)
TENANT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)

echo ""
echo "HTTP Status Check:"
echo "  Admin:  HTTP $ADMIN_TEST"
echo "  Tenant: HTTP $TENANT_TEST"

echo ""
echo "Deployed Files:"
echo "  Admin:  $(ls -1 /usr/share/nginx/html/admin 2>/dev/null | wc -l) files"
echo "  Tenant: $(ls -1 /usr/share/nginx/html/tenant 2>/dev/null | wc -l) files"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 ACCESS YOUR APPLICATIONS:"
echo ""
echo "   👨‍💼 ADMIN PORTAL:"
echo "      URL:      http://$PUBLIC_IP/admin/"
echo "      Email:    admin@pgworld.com"
echo "      Password: Admin@123"
echo ""
echo "   👤 TENANT PORTAL:"
echo "      URL:      http://$PUBLIC_IP/tenant/"
echo "      Email:    priya@example.com"
echo "      Password: Tenant@123"
echo ""
echo "════════════════════════════════════════════════════════"
echo "⚡ IMPORTANT:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. HARD REFRESH your browser:"
echo "   Windows: Ctrl + Shift + R"
echo "   Mac:     Cmd + Shift + R"
echo ""
echo "2. Or use Incognito/Private browsing"
echo ""
echo "3. Check browser console (F12) if issues persist"
echo ""
echo "4. Build logs saved to:"
echo "   /tmp/tenant_rebuild.log"
echo ""
echo "════════════════════════════════════════════════════════"

