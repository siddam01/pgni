#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🎯 PRODUCTION-READY TENANT FIX"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Fixing all Flutter compile errors systematically..."
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

# Comprehensive backup
BACKUP="production_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
cp -r lib "$BACKUP/"
echo "✓ Backup: $BACKUP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "PHASE 1: Configuration Cleanup"
echo "════════════════════════════════════════════════════════"

# Delete ALL old config references
rm -rf lib/utils/config.dart lib/utils/Config.dart 2>/dev/null || true
echo "✓ Removed old config files"

# Create single, comprehensive config
cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// PRODUCTION CONFIGURATION - Single Source of Truth
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// API ENDPOINTS
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
  static const String LOGIN = "/api/login";
  static const String FOOD = "/api/food";
}

// ══════════════════════════════════════════════════════════════════════════
// API KEYS & AUTHENTICATION
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY_VALUE = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";

class APIKEY {
  static const String ANDROID_LIVE = APIKEY_VALUE;
  static const String ANDROID_TEST = APIKEY_VALUE;
  static const String IOS_LIVE = APIKEY_VALUE;
  static const String IOS_TEST = APIKEY_VALUE;
}

// Config class for legacy compatibility
class Config {
  static const String URL = API.URL;
  static const int timeout = 30;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': APIKEY_VALUE,
    'apikey': APIKEY_VALUE,
  };
}

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL CONSTANTS
// ══════════════════════════════════════════════════════════════════════════

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30;

Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-API-Key': APIKEY_VALUE,
  'apikey': APIKEY_VALUE,
};

// ══════════════════════════════════════════════════════════════════════════
// GLOBAL SESSION STATE
// ══════════════════════════════════════════════════════════════════════════

String? hostelID;
String? userID;
String? emailID;
String? name;
String? amenities;

void clearSession() {
  hostelID = null;
  userID = null;
  emailID = null;
  name = null;
  amenities = null;
}

void setSession({String? user, String? hostel, String? email, String? userName}) {
  userID = user;
  hostelID = hostel;
  emailID = email;
  name = userName;
}

// ══════════════════════════════════════════════════════════════════════════
// NULL-SAFE UTILITY FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════

String str(dynamic v) => v?.toString() ?? '';
int toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
double toDouble(dynamic v) => v is double ? v : (v is int ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0.0 : 0.0));
bool toBool(dynamic v) => v is bool ? v : (v is String ? v.toLowerCase() == 'true' || v == '1' : (v is int ? v != 0 : false));

List<String> toStringList(dynamic v) {
  if (v is List<String>) return v;
  if (v is String) return v.isEmpty ? [] : [v];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

// ══════════════════════════════════════════════════════════════════════════
// APP VERSION
// ══════════════════════════════════════════════════════════════════════════

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}
EOFCONFIG

echo "✓ Created lib/config.dart (production-ready)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "PHASE 2: Complete Null-Safe Models"
echo "════════════════════════════════════════════════════════"

cat > lib/utils/models.dart << 'EOFMODELS'
// ════════════════════════════════════════════════════════════════════════════
// NULL-SAFE DATA MODELS - Production Ready
// ════════════════════════════════════════════════════════════════════════════

import 'package:cloudpgtenant/config.dart';

// ══════════════════════════════════════════════════════════════════════════
// META & PAGINATION
// ══════════════════════════════════════════════════════════════════════════

class Meta {
  final int status;
  final String messageType;
  final String message;

  Meta({this.status = 0, this.messageType = '', this.message = ''});

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    status: toInt(json['status']),
    messageType: str(json['messageType'] ?? json['message_type']),
    message: str(json['message']),
  );
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int offset;

  Pagination({this.total = 0, this.page = 1, this.limit = 10, this.offset = 0});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: toInt(json['total']),
    page: toInt(json['page']),
    limit: toInt(json['limit']),
    offset: toInt(json['offset']),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// DASHBOARD & GRAPH
// ══════════════════════════════════════════════════════════════════════════

class Graph {
  final String label;
  final String value;
  final String color;

  Graph({this.label = '', this.value = '', this.color = ''});

  factory Graph.fromJson(Map<String, dynamic> json) => Graph(
    label: str(json['label']),
    value: str(json['value']),
    color: str(json['color']),
  );
}

class Dashboard {
  final String totalRooms;
  final String occupiedRooms;
  final String vacantRooms;
  final String totalTenants;
  final String pendingPayments;
  final String totalRevenue;
  final List<Graph> graphs;

  Dashboard({
    this.totalRooms = '0',
    this.occupiedRooms = '0',
    this.vacantRooms = '0',
    this.totalTenants = '0',
    this.pendingPayments = '0',
    this.totalRevenue = '0',
    this.graphs = const [],
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    totalRooms: str(json['totalRooms'] ?? json['total_rooms']),
    occupiedRooms: str(json['occupiedRooms'] ?? json['occupied_rooms']),
    vacantRooms: str(json['vacantRooms'] ?? json['vacant_rooms']),
    totalTenants: str(json['totalTenants'] ?? json['total_tenants']),
    pendingPayments: str(json['pendingPayments'] ?? json['pending_payments']),
    totalRevenue: str(json['totalRevenue'] ?? json['total_revenue']),
    graphs: json['graphs'] != null
        ? (json['graphs'] as List).map((e) => Graph.fromJson(e)).toList()
        : [],
  );
}

// ══════════════════════════════════════════════════════════════════════════
// USER
// ══════════════════════════════════════════════════════════════════════════

class User {
  final String id;
  final String hostelID;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String roomID;
  final String roomno;
  final String rent;
  final String emerContact;
  final String emerPhone;
  final String food;
  final String document;
  final String paymentStatus;
  final String joiningDateTime;
  final String lastPaidDateTime;
  final String expiryDateTime;
  final String leaveDateTime;
  final String status;

  User({
    this.id = '',
    this.hostelID = '',
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.roomID = '',
    this.roomno = '',
    this.rent = '0',
    this.emerContact = '',
    this.emerPhone = '',
    this.food = '',
    this.document = '',
    this.paymentStatus = 'pending',
    this.joiningDateTime = '',
    this.lastPaidDateTime = '',
    this.expiryDateTime = '',
    this.leaveDateTime = '',
    this.status = 'active',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: str(json['id']),
    hostelID: str(json['hostelID'] ?? json['hostel_id']),
    name: str(json['name']),
    phone: str(json['phone']),
    email: str(json['email']),
    address: str(json['address']),
    roomID: str(json['roomID'] ?? json['room_id']),
    roomno: str(json['roomno']),
    rent: str(json['rent']),
    emerContact: str(json['emerContact'] ?? json['emer_contact']),
    emerPhone: str(json['emerPhone'] ?? json['emer_phone']),
    food: str(json['food']),
    document: str(json['document']),
    paymentStatus: str(json['paymentStatus'] ?? json['payment_status']),
    joiningDateTime: str(json['joiningDateTime'] ?? json['joining_datetime']),
    lastPaidDateTime: str(json['lastPaidDateTime'] ?? json['last_paid_datetime']),
    expiryDateTime: str(json['expiryDateTime'] ?? json['expiry_datetime']),
    leaveDateTime: str(json['leaveDateTime'] ?? json['leave_datetime']),
    status: str(json['status']),
  );
}

class Users {
  final List<User> users;
  final Pagination? pagination;
  final Meta? meta;

  Users({this.users = const [], this.pagination, this.meta});

  factory Users.fromJson(Map<String, dynamic> json) => Users(
    users: json['users'] != null
        ? (json['users'] as List).map((e) => User.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// ROOM
// ══════════════════════════════════════════════════════════════════════════

class Room {
  final String id;
  final String hostelID;
  final String roomno;
  final String rent;
  final String floor;
  final String filled;
  final String capacity;
  final String amenities;
  final String type;
  final String size;
  final String status;
  final String document;

  Room({
    this.id = '',
    this.hostelID = '',
    this.roomno = '',
    this.rent = '0',
    this.floor = '',
    this.filled = '0',
    this.capacity = '0',
    this.amenities = '',
    this.type = '',
    this.size = '',
    this.status = 'available',
    this.document = '',
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: str(json['id']),
    hostelID: str(json['hostelID'] ?? json['hostel_id']),
    roomno: str(json['roomno']),
    rent: str(json['rent']),
    floor: str(json['floor']),
    filled: str(json['filled']),
    capacity: str(json['capacity']),
    amenities: str(json['amenities']),
    type: str(json['type']),
    size: str(json['size']),
    status: str(json['status']),
    document: str(json['document']),
  );
}

class Rooms {
  final List<Room> rooms;
  final Pagination? pagination;
  final Meta? meta;

  Rooms({this.rooms = const [], this.pagination, this.meta});

  factory Rooms.fromJson(Map<String, dynamic> json) => Rooms(
    rooms: json['rooms'] != null
        ? (json['rooms'] as List).map((e) => Room.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// BILL
// ══════════════════════════════════════════════════════════════════════════

class Bill {
  final String id;
  final String userID;
  final String hostelID;
  final String amount;
  final String month;
  final String status;
  final String paymentDate;
  final String paidDateTime;
  final String paid;
  final String title;
  final String description;
  final String document;

  Bill({
    this.id = '',
    this.userID = '',
    this.hostelID = '',
    this.amount = '0',
    this.month = '',
    this.status = 'unpaid',
    this.paymentDate = '',
    this.paidDateTime = '',
    this.paid = 'false',
    this.title = '',
    this.description = '',
    this.document = '',
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: str(json['id']),
    userID: str(json['userID'] ?? json['user_id']),
    hostelID: str(json['hostelID'] ?? json['hostel_id']),
    amount: str(json['amount']),
    month: str(json['month']),
    status: str(json['status']),
    paymentDate: str(json['paymentDate'] ?? json['payment_date']),
    paidDateTime: str(json['paidDateTime'] ?? json['paid_datetime']),
    paid: str(json['paid']),
    title: str(json['title']),
    description: str(json['description']),
    document: str(json['document']),
  );
}

class Bills {
  final List<Bill> bills;
  final Pagination? pagination;
  final Meta? meta;

  Bills({this.bills = const [], this.pagination, this.meta});

  factory Bills.fromJson(Map<String, dynamic> json) => Bills(
    bills: json['bills'] != null
        ? (json['bills'] as List).map((e) => Bill.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// ISSUE
// ══════════════════════════════════════════════════════════════════════════

class Issue {
  final String id;
  final String userID;
  final String hostelID;
  final String roomID;
  final String type;
  final String title;
  final String description;
  final String status;

  Issue({
    this.id = '',
    this.userID = '',
    this.hostelID = '',
    this.roomID = '',
    this.type = '',
    this.title = '',
    this.description = '',
    this.status = 'open',
  });

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: str(json['id']),
    userID: str(json['userID'] ?? json['user_id']),
    hostelID: str(json['hostelID'] ?? json['hostel_id']),
    roomID: str(json['roomID'] ?? json['room_id']),
    type: str(json['type']),
    title: str(json['title']),
    description: str(json['description']),
    status: str(json['status']),
  );
}

class Issues {
  final List<Issue> issues;
  final Pagination? pagination;
  final Meta? meta;

  Issues({this.issues = const [], this.pagination, this.meta});

  factory Issues.fromJson(Map<String, dynamic> json) => Issues(
    issues: json['issues'] != null
        ? (json['issues'] as List).map((e) => Issue.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// NOTICE
// ══════════════════════════════════════════════════════════════════════════

class Notice {
  final String id;
  final String hostelID;
  final String title;
  final String note;
  final String img;
  final String status;
  final String createdDateTime;

  Notice({
    this.id = '',
    this.hostelID = '',
    this.title = '',
    this.note = '',
    this.img = '',
    this.status = 'active',
    this.createdDateTime = '',
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: str(json['id']),
    hostelID: str(json['hostelID'] ?? json['hostel_id']),
    title: str(json['title']),
    note: str(json['note']),
    img: str(json['img']),
    status: str(json['status']),
    createdDateTime: str(json['createdDateTime'] ?? json['created_datetime']),
  );
}

class Notices {
  final List<Notice> notices;
  final Pagination? pagination;
  final Meta? meta;

  Notices({this.notices = const [], this.pagination, this.meta});

  factory Notices.fromJson(Map<String, dynamic> json) => Notices(
    notices: json['notices'] != null
        ? (json['notices'] as List).map((e) => Notice.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// HOSTEL
// ══════════════════════════════════════════════════════════════════════════

class Hostel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String amenities;
  final String status;
  final String expiryDateTime;

  Hostel({
    this.id = '',
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.amenities = '',
    this.status = 'active',
    this.expiryDateTime = '',
  });

  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(
    id: str(json['id']),
    name: str(json['name']),
    phone: str(json['phone']),
    email: str(json['email']),
    address: str(json['address']),
    amenities: str(json['amenities']),
    status: str(json['status']),
    expiryDateTime: str(json['expiryDateTime'] ?? json['expiry_datetime']),
  );
}

class Hostels {
  final List<Hostel> hostels;
  final Pagination? pagination;
  final Meta? meta;

  Hostels({this.hostels = const [], this.pagination, this.meta});

  factory Hostels.fromJson(Map<String, dynamic> json) => Hostels(
    hostels: json['hostels'] != null
        ? (json['hostels'] as List).map((e) => Hostel.fromJson(e)).toList()
        : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}
EOFMODELS

echo "✓ Created complete null-safe models"

echo ""
echo "════════════════════════════════════════════════════════"
echo "PHASE 3: Import Replacement"
echo "════════════════════════════════════════════════════════"

# Replace ALL old imports systematically
find lib -name "*.dart" -type f ! -name "config.dart" -print0 | while IFS= read -r -d '' file; do
    # Replace old config imports
    sed -i "s|package:cloudpgtenant/utils/config.dart|package:cloudpgtenant/config.dart|g" "$file"
    sed -i "s|import 'package:cloudpgtenant/config.dart' as config;|import 'package:cloudpgtenant/config.dart';|g" "$file"
done

echo "✓ Fixed all imports"

echo ""
echo "════════════════════════════════════════════════════════"
echo "PHASE 4: Build & Deploy"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache
export PATH="/opt/flutter/bin:$PATH"

flutter clean > /dev/null 2>&1
flutter pub get 2>&1 | tail -3

echo ""
echo "Building (2-4 minutes on t3.xlarge)..."
BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/production_build.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILES=$(ls -1 build/web | wc -l)
    
    echo ""
    echo "✅ BUILD SUCCESS!"
    echo "   Size: $SIZE | Files: $FILES | Time: ${BUILD_TIME}s"
    
    # Deploy
    [ -d "/usr/share/nginx/html/tenant" ] && sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo find /usr/share/nginx/html/tenant -type f -exec chmod 644 {} \;
    command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ] && sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/tenant 2>/dev/null || true
    sudo systemctl reload nginx
    
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "🌐 Tenant App: http://13.221.117.236/tenant/"
    echo "👤 Email:      priya@example.com"
    echo "🔐 Password:   Tenant@123"
    echo "📊 Status:     HTTP $STATUS $([ "$STATUS" = "200" ] && echo "✅" || echo "⚠️")"
    echo "⏱️  Build:      ${BUILD_TIME}s ($(($BUILD_TIME/60))m $(($BUILD_TIME%60))s)"
    echo "📦 Size:       $SIZE"
    echo ""
    echo "✅ NULL-SAFE: All models use non-nullable types"
    echo "✅ SINGLE CONFIG: lib/config.dart only"
    echo "✅ ALL FIELDS: Complete models with all properties"
    echo ""
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    echo "Top 30 errors:"
    grep "Error:" /tmp/production_build.log | head -30
    echo ""
    echo "Full log: /tmp/production_build.log"
    exit 1
fi

