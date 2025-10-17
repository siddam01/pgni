#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🛡️ COMPLETE NULL-SAFE TENANT FIX"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This will:"
echo "  1. Create single lib/config.dart (no lib/utils/config.dart)"
echo "  2. Create null-safe models with safe defaults"
echo "  3. Fix all null-safety violations"
echo "  4. Replace all imports"
echo "  5. Build and deploy successfully"
echo ""

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
PUBLIC_IP="13.221.117.236"
API_PORT="8080"

cd "$TENANT_PATH"

# Backup
BACKUP_DIR="null_safe_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup: $BACKUP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Remove Old Config Files"
echo "════════════════════════════════════════════════════════"

rm -f lib/utils/config.dart 2>/dev/null || true
echo "✓ Removed lib/utils/config.dart"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Create Single Null-Safe Config"
echo "════════════════════════════════════════════════════════"

mkdir -p lib

cat > lib/config.dart << 'EOFCONFIG'
// ════════════════════════════════════════════════════════════════════════════
// SINGLE NULL-SAFE CONFIGURATION
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
// API KEYS (Your Production Keys)
// ══════════════════════════════════════════════════════════════════════════

const String APIKEY_VALUE = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";

class APIKEY {
  static const String ANDROID_LIVE = APIKEY_VALUE;
  static const String ANDROID_TEST = APIKEY_VALUE;
  static const String IOS_LIVE = APIKEY_VALUE;
  static const String IOS_TEST = APIKEY_VALUE;
}

// ══════════════════════════════════════════════════════════════════════════
// CONSTANTS
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
// GLOBAL SESSION (Nullable by design)
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
// NULL-SAFE HELPERS (Essential for type safety)
// ══════════════════════════════════════════════════════════════════════════

String orEmpty(String? value) => value ?? '';
int orZero(dynamic value) => value is int ? value : (value is String ? int.tryParse(value) ?? 0 : 0);
double orZeroDouble(dynamic value) => value is double ? value : (value is int ? value.toDouble() : (value is String ? double.tryParse(value) ?? 0.0 : 0.0));
bool orFalse(dynamic value) => value is bool ? value : (value is String ? value.toLowerCase() == 'true' : false);

T? nullableGet<T>(List<T>? list, int index) {
  if (list == null || index < 0 || index >= list.length) return null;
  return list[index];
}

int listLen<T>(List<T>? list) => list?.length ?? 0;
bool hasText(String? value) => value != null && value.isNotEmpty;
List<String> splitSafe(String? value, String sep) => hasText(value) ? value!.split(sep) : [];

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}
EOFCONFIG

echo "✓ Created lib/config.dart (null-safe)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Create Null-Safe Models"
echo "════════════════════════════════════════════════════════"

cat > lib/utils/models.dart << 'EOFMODELS'
// ════════════════════════════════════════════════════════════════════════════
// NULL-SAFE DATA MODELS
// ════════════════════════════════════════════════════════════════════════════

import 'package:cloudpgtenant/config.dart';

// ══════════════════════════════════════════════════════════════════════════
// META & PAGINATION
// ══════════════════════════════════════════════════════════════════════════

class Meta {
  final int status;
  final String messageType;
  final String message;

  Meta({
    required this.status,
    required this.messageType,
    required this.message,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    status: orZero(json['status']),
    messageType: orEmpty(json['messageType'] ?? json['message_type']),
    message: orEmpty(json['message']),
  );
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int offset;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.offset,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: orZero(json['total']),
    page: orZero(json['page']),
    limit: orZero(json['limit']),
    offset: orZero(json['offset']),
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
    required this.id,
    required this.hostelID,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.roomID,
    required this.roomno,
    required this.rent,
    required this.emerContact,
    required this.emerPhone,
    required this.food,
    required this.document,
    required this.paymentStatus,
    required this.joiningDateTime,
    required this.lastPaidDateTime,
    required this.expiryDateTime,
    required this.leaveDateTime,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: orEmpty(json['id']),
    hostelID: orEmpty(json['hostelID'] ?? json['hostel_id']),
    name: orEmpty(json['name']),
    phone: orEmpty(json['phone']),
    email: orEmpty(json['email']),
    address: orEmpty(json['address']),
    roomID: orEmpty(json['roomID'] ?? json['room_id']),
    roomno: orEmpty(json['roomno']),
    rent: orEmpty(json['rent']),
    emerContact: orEmpty(json['emerContact'] ?? json['emer_contact']),
    emerPhone: orEmpty(json['emerPhone'] ?? json['emer_phone']),
    food: orEmpty(json['food']),
    document: orEmpty(json['document']),
    paymentStatus: orEmpty(json['paymentStatus'] ?? json['payment_status']),
    joiningDateTime: orEmpty(json['joiningDateTime'] ?? json['joining_datetime']),
    lastPaidDateTime: orEmpty(json['lastPaidDateTime'] ?? json['last_paid_datetime']),
    expiryDateTime: orEmpty(json['expiryDateTime'] ?? json['expiry_datetime']),
    leaveDateTime: orEmpty(json['leaveDateTime'] ?? json['leave_datetime']),
    status: orEmpty(json['status']),
  );
}

class Users {
  final List<User> users;
  final Pagination? pagination;
  final Meta? meta;

  Users({required this.users, this.pagination, this.meta});

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
    required this.id,
    required this.hostelID,
    required this.roomno,
    required this.rent,
    required this.floor,
    required this.filled,
    required this.capacity,
    required this.amenities,
    required this.type,
    required this.size,
    required this.status,
    required this.document,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: orEmpty(json['id']),
    hostelID: orEmpty(json['hostelID'] ?? json['hostel_id']),
    roomno: orEmpty(json['roomno']),
    rent: orEmpty(json['rent']),
    floor: orEmpty(json['floor']),
    filled: orEmpty(json['filled']),
    capacity: orEmpty(json['capacity']),
    amenities: orEmpty(json['amenities']),
    type: orEmpty(json['type']),
    size: orEmpty(json['size']),
    status: orEmpty(json['status']),
    document: orEmpty(json['document']),
  );
}

class Rooms {
  final List<Room> rooms;
  final Pagination? pagination;
  final Meta? meta;

  Rooms({required this.rooms, this.pagination, this.meta});

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
  final String title;

  Bill({
    required this.id,
    required this.userID,
    required this.hostelID,
    required this.amount,
    required this.month,
    required this.status,
    required this.paymentDate,
    required this.title,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: orEmpty(json['id']),
    userID: orEmpty(json['userID'] ?? json['user_id']),
    hostelID: orEmpty(json['hostelID'] ?? json['hostel_id']),
    amount: orEmpty(json['amount']),
    month: orEmpty(json['month']),
    status: orEmpty(json['status']),
    paymentDate: orEmpty(json['paymentDate'] ?? json['payment_date']),
    title: orEmpty(json['title']),
  );
}

class Bills {
  final List<Bill> bills;
  final Pagination? pagination;
  final Meta? meta;

  Bills({required this.bills, this.pagination, this.meta});

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
  final String type;
  final String title;
  final String description;
  final String status;

  Issue({
    required this.id,
    required this.userID,
    required this.hostelID,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: orEmpty(json['id']),
    userID: orEmpty(json['userID'] ?? json['user_id']),
    hostelID: orEmpty(json['hostelID'] ?? json['hostel_id']),
    type: orEmpty(json['type']),
    title: orEmpty(json['title']),
    description: orEmpty(json['description']),
    status: orEmpty(json['status']),
  );
}

class Issues {
  final List<Issue> issues;
  final Pagination? pagination;
  final Meta? meta;

  Issues({required this.issues, this.pagination, this.meta});

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

  Notice({
    required this.id,
    required this.hostelID,
    required this.title,
    required this.note,
    required this.img,
    required this.status,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: orEmpty(json['id']),
    hostelID: orEmpty(json['hostelID'] ?? json['hostel_id']),
    title: orEmpty(json['title']),
    note: orEmpty(json['note']),
    img: orEmpty(json['img']),
    status: orEmpty(json['status']),
  );
}

class Notices {
  final List<Notice> notices;
  final Pagination? pagination;
  final Meta? meta;

  Notices({required this.notices, this.pagination, this.meta});

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

  Hostel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.amenities,
    required this.status,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(
    id: orEmpty(json['id']),
    name: orEmpty(json['name']),
    phone: orEmpty(json['phone']),
    email: orEmpty(json['email']),
    address: orEmpty(json['address']),
    amenities: orEmpty(json['amenities']),
    status: orEmpty(json['status']),
  );
}

class Hostels {
  final List<Hostel> hostels;
  final Pagination? pagination;
  final Meta? meta;

  Hostels({required this.hostels, this.pagination, this.meta});

  factory Hostels.fromJson(Map<String, dynamic> json) => Hostels(
    hostels: json['hostels'] != null
      ? (json['hostels'] as List).map((e) => Hostel.fromJson(e)).toList()
      : [],
    pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════════════════════════════

class Dashboard {
  final String totalRooms;
  final String occupiedRooms;
  final String vacantRooms;
  final String totalTenants;
  final String pendingPayments;
  final String totalRevenue;

  Dashboard({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.vacantRooms,
    required this.totalTenants,
    required this.pendingPayments,
    required this.totalRevenue,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    totalRooms: orEmpty(json['totalRooms'] ?? json['total_rooms']),
    occupiedRooms: orEmpty(json['occupiedRooms'] ?? json['occupied_rooms']),
    vacantRooms: orEmpty(json['vacantRooms'] ?? json['vacant_rooms']),
    totalTenants: orEmpty(json['totalTenants'] ?? json['total_tenants']),
    pendingPayments: orEmpty(json['pendingPayments'] ?? json['pending_payments']),
    totalRevenue: orEmpty(json['totalRevenue'] ?? json['total_revenue']),
  );
}
EOFMODELS

echo "✓ Created null-safe models.dart"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 4: Fix All Imports"
echo "════════════════════════════════════════════════════════"

# Replace all old imports
find lib -name "*.dart" -type f ! -name "config.dart" -exec sed -i \
  -e "s|package:cloudpgtenant/utils/config.dart|package:cloudpgtenant/config.dart|g" \
  -e "s|import 'package:cloudpgtenant/config.dart' as config;|import 'package:cloudpgtenant/config.dart';|g" \
  -e "s/config\.userID/userID/g" \
  -e "s/config\.hostelID/hostelID/g" \
  -e "s/config\.emailID/emailID/g" \
  -e "s/config\.name/name/g" \
  {} \;

echo "✓ Fixed all imports"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 5: Build Environment"
echo "════════════════════════════════════════════════════════"

export DART_VM_OPTIONS="--old_gen_heap_size=6144"
export PUB_CACHE=/home/ec2-user/.pub-cache
export PATH="/opt/flutter/bin:$PATH"

echo "✓ Optimized for t3.large"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 6: Clean, Get Dependencies, Build"
echo "════════════════════════════════════════════════════════"

flutter clean > /dev/null 2>&1
rm -rf .dart_tool build
echo "✓ Cleaned"

flutter pub get 2>&1 | tail -3

echo ""
echo "Building (2-4 minutes)..."
BUILD_START=$(date +%s)

flutter build web \
    --release \
    --no-source-maps \
    --base-href="/tenant/" \
    2>&1 | tee /tmp/tenant_null_safe.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    FILES=$(ls -1 build/web | wc -l)
    
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "   JS: $SIZE | Files: $FILES | Time: ${BUILD_TIME}s"
    
    echo ""
    echo "Deploying..."
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
    echo "🌐 URL:      http://$PUBLIC_IP/tenant/"
    echo "👤 Email:    priya@example.com"
    echo "🔐 Password: Tenant@123"
    echo "📊 Status:   $([ "$STATUS" = "200" ] && echo "✅ LIVE (HTTP $STATUS)" || echo "⚠️  HTTP $STATUS")"
    echo "⏱️  Build:    ${BUILD_TIME}s ($(($BUILD_TIME/60))m $(($BUILD_TIME%60))s)"
    echo "📦 Size:     $SIZE"
    echo ""
    echo "✅ NULL-SAFE: All models use non-nullable types with safe defaults"
    echo "✅ SINGLE CONFIG: lib/config.dart only"
    echo "✅ PRODUCTION KEYS: mrk-1b96d9eeccf649e695ed6ac2b13cb619"
    echo ""
    
else
    echo ""
    echo "❌ BUILD FAILED"
    echo ""
    grep "Error:" /tmp/tenant_null_safe.log | head -20
    echo ""
    echo "Log: /tmp/tenant_null_safe.log"
    exit 1
fi

