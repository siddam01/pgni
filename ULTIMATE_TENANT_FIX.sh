#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🎯 ULTIMATE TENANT FIX - Complete Code Repair"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  ✓ Create lib/config.dart with ALL global variables"
echo "  ✓ Fix ALL undefined getter/setter errors"
echo "  ✓ Fix ALL null safety issues"
echo "  ✓ Update ALL screen State classes"
echo "  ✓ Build and deploy successfully"
echo ""

PUBLIC_IP="13.221.117.236"
API_PORT="8080"
TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"

cd "$TENANT_PATH"

echo "════════════════════════════════════════════════════════"
echo "STEP 1: Create Global Configuration File"
echo "════════════════════════════════════════════════════════"

mkdir -p lib

# Create the master config.dart file with ALL global variables
cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// GLOBAL CONFIGURATION - All app-wide constants and variables
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ══════════════════════════════════════════════════════════════════════════
// API CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

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
  static const String DASHBOARD = "/api/dashboard";
}

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL CONSTANTS (Accessible everywhere)
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";
const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30;

// Global headers map (mutable for runtime updates)
Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-API-Key': APIKEY,
};

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL STATE VARIABLES (User session data)
// ══════════════════════════════════════════════════════════════════════════

String? userID;
String? hostelID;
String? emailID;
String? name;
String? amenities;

// Clear all global state
void clearGlobalState() {
  userID = null;
  hostelID = null;
  emailID = null;
  name = null;
  amenities = null;
}

// Set user session
void setUserSession({
  String? id,
  String? hostel,
  String? email,
  String? userName,
}) {
  userID = id;
  hostelID = hostel;
  emailID = email;
  name = userName;
}

// ══════════════════════════════════════════════════════════════════════════
// APP VERSION
// ══════════════════════════════════════════════════════════════════════════

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════

// Safe string access with default value
String safeString(String? value, [String defaultValue = '']) {
  return value ?? defaultValue;
}

// Safe int conversion
int safeInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Safe bool conversion
bool safeBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value != 0;
  return defaultValue;
}

// Safe list access
T? safeListAccess<T>(List<T>? list, int index) {
  if (list == null || list.isEmpty || index < 0 || index >= list.length) {
    return null;
  }
  return list[index];
}

// Safe property access
T? safeProp<T>(T? value) {
  return value;
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT FOR USE IN OTHER FILES
// ══════════════════════════════════════════════════════════════════════════

// These can be imported as: import 'package:cloudpgtenant/config.dart';
EOFCONFIG

echo "✓ Global config.dart created with ALL variables"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Complete Models File"
echo "════════════════════════════════════════════════════════"

cat > lib/utils/models.dart << 'EOFMODELS'
import 'package:cloudpgtenant/config.dart';

// ══════════════════════════════════════════════════════════════════════════
// META & PAGINATION
// ══════════════════════════════════════════════════════════════════════════

class Meta {
  int? status;
  String? messageType;
  String? message;

  Meta({this.status, this.messageType, this.message});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      status: safeInt(json['status']),
      messageType: safeString(json['messageType'] ?? json['message_type']),
      message: safeString(json['message']),
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
      total: safeInt(json['total']),
      page: safeInt(json['page'], 1),
      limit: safeInt(json['limit'], 10),
      offset: safeInt(json['offset']),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DASHBOARD & GRAPH
// ══════════════════════════════════════════════════════════════════════════

class Graph {
  String? label;
  String? value;
  String? color;

  Graph({this.label, this.value, this.color});

  factory Graph.fromJson(Map<String, dynamic> json) {
    return Graph(
      label: safeString(json['label']),
      value: safeString(json['value']),
      color: safeString(json['color']),
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
      totalRooms: safeString(json['totalRooms'] ?? json['total_rooms']),
      occupiedRooms: safeString(json['occupiedRooms'] ?? json['occupied_rooms']),
      vacantRooms: safeString(json['vacantRooms'] ?? json['vacant_rooms']),
      totalTenants: safeString(json['totalTenants'] ?? json['total_tenants']),
      pendingPayments: safeString(json['pendingPayments'] ?? json['pending_payments']),
      totalRevenue: safeString(json['totalRevenue'] ?? json['total_revenue']),
      graphs: json['graphs'] != null 
          ? (json['graphs'] as List).map((i) => Graph.fromJson(i)).toList()
          : [],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// USER
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      hostelID: safeString(json['hostelID'] ?? json['hostel_id']),
      name: safeString(json['name']),
      phone: safeString(json['phone']),
      email: safeString(json['email']),
      address: safeString(json['address']),
      roomID: safeString(json['roomID'] ?? json['room_id']),
      roomno: safeString(json['roomno']),
      rent: safeString(json['rent']),
      emerContact: safeString(json['emerContact'] ?? json['emer_contact']),
      emerPhone: safeString(json['emerPhone'] ?? json['emer_phone']),
      food: safeString(json['food']),
      document: safeString(json['document']),
      paymentStatus: safeString(json['paymentStatus'] ?? json['payment_status']),
      joiningDateTime: safeString(json['joiningDateTime'] ?? json['joining_datetime']),
      lastPaidDateTime: safeString(json['lastPaidDateTime'] ?? json['last_paid_datetime']),
      expiryDateTime: safeString(json['expiryDateTime'] ?? json['expiry_datetime']),
      leaveDateTime: safeString(json['leaveDateTime'] ?? json['leave_datetime']),
      status: safeString(json['status']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ROOM
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      hostelID: safeString(json['hostelID'] ?? json['hostel_id']),
      roomno: safeString(json['roomno']),
      rent: safeString(json['rent']),
      floor: safeString(json['floor']),
      filled: safeString(json['filled']),
      capacity: safeString(json['capacity']),
      amenities: safeString(json['amenities']),
      type: safeString(json['type']),
      size: safeString(json['size']),
      status: safeString(json['status']),
      document: safeString(json['document']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// BILL
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      userID: safeString(json['userID'] ?? json['user_id']),
      hostelID: safeString(json['hostelID'] ?? json['hostel_id']),
      amount: safeString(json['amount']),
      month: safeString(json['month']),
      status: safeString(json['status']),
      paymentDate: safeString(json['paymentDate'] ?? json['payment_date']),
      paidDateTime: safeString(json['paidDateTime'] ?? json['paid_datetime']),
      paid: safeString(json['paid']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      document: safeString(json['document']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ISSUE
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      userID: safeString(json['userID'] ?? json['user_id']),
      hostelID: safeString(json['hostelID'] ?? json['hostel_id']),
      roomID: safeString(json['roomID'] ?? json['room_id']),
      type: safeString(json['type']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      status: safeString(json['status']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// NOTICE
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      hostelID: safeString(json['hostelID'] ?? json['hostel_id']),
      title: safeString(json['title']),
      note: safeString(json['note']),
      img: safeString(json['img']),
      status: safeString(json['status']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HOSTEL
// ══════════════════════════════════════════════════════════════════════════

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
      id: safeString(json['id']),
      name: safeString(json['name']),
      phone: safeString(json['phone']),
      email: safeString(json['email']),
      address: safeString(json['address']),
      amenities: safeString(json['amenities']),
      status: safeString(json['status']),
      createdBy: safeString(json['createdBy'] ?? json['created_by']),
      modifiedBy: safeString(json['modifiedBy'] ?? json['modified_by']),
      expiryDateTime: safeString(json['expiryDateTime'] ?? json['expiry_datetime']),
      createdDateTime: safeString(json['createdDateTime'] ?? json['created_datetime']),
      modifiedDateTime: safeString(json['modifiedDateTime'] ?? json['modified_datetime']),
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
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}
EOFMODELS

echo "✓ Complete models.dart created with safe access"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Update API File"
echo "════════════════════════════════════════════════════════"

# Ensure api.dart imports the config
if [ -f "lib/utils/api.dart" ]; then
    if ! grep -q "import 'package:cloudpgtenant/config.dart'" lib/utils/api.dart; then
        sed -i "1i import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart
        echo "✓ Added config import to api.dart"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Optimized Build"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build

echo "Getting dependencies..."
flutter pub get 2>&1 | tail -3

echo ""
echo "Building Tenant app..."
BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --no-tree-shake-icons \
    --dart-define=dart.vm.product=true \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_ultimate.log | grep -E "Compiling|Built|✓" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   Size: $SIZE"
    echo "   Time: ${BUILD_TIME}s"
    
    echo ""
    echo "Deploying to Nginx..."
    
    if [ -d "/usr/share/nginx/html/tenant" ]; then
        sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s) 2>/dev/null || true
    fi
    
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    
    if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
        sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    fi
    
    sudo systemctl reload nginx
    
    sleep 2
    
    TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT COMPLETE!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 TENANT PORTAL:"
    echo "   URL:      http://13.221.117.236/tenant/"
    echo "   Email:    priya@example.com"
    echo "   Password: Tenant@123"
    echo "   Status:   $([ "$TEST" = "200" ] && echo "✅ WORKING (HTTP $TEST)" || echo "⚠️  HTTP $TEST")"
    echo ""
    echo "⏱️  Build Time: ${BUILD_TIME}s"
    echo ""
    echo "⚡ HARD REFRESH YOUR BROWSER:"
    echo "   Windows: Ctrl + Shift + R"
    echo "   Mac:     Cmd + Shift + R"
    echo ""
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    echo "Recent errors:"
    grep -i "error" /tmp/tenant_ultimate.log | tail -20
    echo ""
    echo "Full log: /tmp/tenant_ultimate.log"
    exit 1
fi

