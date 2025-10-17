#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔥 ULTIMATE FIX - ALL ERRORS RESOLVED"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

BACKUP="ultimate_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
cp -r lib "$BACKUP/" 2>/dev/null || true
echo "✓ Backup: $BACKUP"

echo ""
echo "STEP 1: Delete ALL old configs"
rm -f lib/utils/config.dart lib/utils/Config.dart 2>/dev/null || true
echo "✓ Deleted old configs"

echo ""
echo "STEP 2: Create COMPLETE config with all helpers"

cat > lib/config.dart << 'EOFCONFIG'
import 'package:flutter/foundation.dart';

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

const String APIKEY_VALUE = "mrk-1b96d9eeccf649e695ed6ac2b13cb619";
const String ONESIGNAL_APP_ID = "AKIA2FFQRNMAP3IDZD6V";

class APIKEY {
  static const String ANDROID_LIVE = APIKEY_VALUE;
  static const String ANDROID_TEST = APIKEY_VALUE;
  static const String IOS_LIVE = APIKEY_VALUE;
  static const String IOS_TEST = APIKEY_VALUE;
}

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

String safe(dynamic v) => v?.toString() ?? '';
int safeInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
bool safeBool(dynamic v) => v is bool ? v : (v is String ? v.toLowerCase() == 'true' : false);

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}
EOFCONFIG

echo "✓ Created lib/config.dart with Config class"

echo ""
echo "STEP 3: Create COMPLETE models with ALL fields"

cat > lib/utils/models.dart << 'EOFMODELS'
import 'package:cloudpgtenant/config.dart';

class Meta {
  final int status;
  final String messageType;
  final String message;

  Meta({this.status = 0, this.messageType = '', this.message = ''});

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    status: safeInt(json['status']),
    messageType: safe(json['messageType'] ?? json['message_type']),
    message: safe(json['message']),
  );
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int offset;

  Pagination({this.total = 0, this.page = 1, this.limit = 10, this.offset = 0});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: safeInt(json['total']),
    page: safeInt(json['page']),
    limit: safeInt(json['limit']),
    offset: safeInt(json['offset']),
  );
}

class Graph {
  final String label;
  final String value;
  final String color;

  Graph({this.label = '', this.value = '', this.color = ''});

  factory Graph.fromJson(Map<String, dynamic> json) => Graph(
    label: safe(json['label']),
    value: safe(json['value']),
    color: safe(json['color']),
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
    this.totalRooms = '',
    this.occupiedRooms = '',
    this.vacantRooms = '',
    this.totalTenants = '',
    this.pendingPayments = '',
    this.totalRevenue = '',
    this.graphs = const [],
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    totalRooms: safe(json['totalRooms'] ?? json['total_rooms']),
    occupiedRooms: safe(json['occupiedRooms'] ?? json['occupied_rooms']),
    vacantRooms: safe(json['vacantRooms'] ?? json['vacant_rooms']),
    totalTenants: safe(json['totalTenants'] ?? json['total_tenants']),
    pendingPayments: safe(json['pendingPayments'] ?? json['pending_payments']),
    totalRevenue: safe(json['totalRevenue'] ?? json['total_revenue']),
    graphs: json['graphs'] != null
        ? (json['graphs'] as List).map((e) => Graph.fromJson(e)).toList()
        : [],
  );
}

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
    this.rent = '',
    this.emerContact = '',
    this.emerPhone = '',
    this.food = '',
    this.document = '',
    this.paymentStatus = '',
    this.joiningDateTime = '',
    this.lastPaidDateTime = '',
    this.expiryDateTime = '',
    this.leaveDateTime = '',
    this.status = '',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: safe(json['id']),
    hostelID: safe(json['hostelID'] ?? json['hostel_id']),
    name: safe(json['name']),
    phone: safe(json['phone']),
    email: safe(json['email']),
    address: safe(json['address']),
    roomID: safe(json['roomID'] ?? json['room_id']),
    roomno: safe(json['roomno']),
    rent: safe(json['rent']),
    emerContact: safe(json['emerContact'] ?? json['emer_contact']),
    emerPhone: safe(json['emerPhone'] ?? json['emer_phone']),
    food: safe(json['food']),
    document: safe(json['document']),
    paymentStatus: safe(json['paymentStatus'] ?? json['payment_status']),
    joiningDateTime: safe(json['joiningDateTime'] ?? json['joining_datetime']),
    lastPaidDateTime: safe(json['lastPaidDateTime'] ?? json['last_paid_datetime']),
    expiryDateTime: safe(json['expiryDateTime'] ?? json['expiry_datetime']),
    leaveDateTime: safe(json['leaveDateTime'] ?? json['leave_datetime']),
    status: safe(json['status']),
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
    this.rent = '',
    this.floor = '',
    this.filled = '',
    this.capacity = '',
    this.amenities = '',
    this.type = '',
    this.size = '',
    this.status = '',
    this.document = '',
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: safe(json['id']),
    hostelID: safe(json['hostelID'] ?? json['hostel_id']),
    roomno: safe(json['roomno']),
    rent: safe(json['rent']),
    floor: safe(json['floor']),
    filled: safe(json['filled']),
    capacity: safe(json['capacity']),
    amenities: safe(json['amenities']),
    type: safe(json['type']),
    size: safe(json['size']),
    status: safe(json['status']),
    document: safe(json['document']),
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
    this.amount = '',
    this.month = '',
    this.status = '',
    this.paymentDate = '',
    this.paidDateTime = '',
    this.paid = '',
    this.title = '',
    this.description = '',
    this.document = '',
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: safe(json['id']),
    userID: safe(json['userID'] ?? json['user_id']),
    hostelID: safe(json['hostelID'] ?? json['hostel_id']),
    amount: safe(json['amount']),
    month: safe(json['month']),
    status: safe(json['status']),
    paymentDate: safe(json['paymentDate'] ?? json['payment_date']),
    paidDateTime: safe(json['paidDateTime'] ?? json['paid_datetime']),
    paid: safe(json['paid']),
    title: safe(json['title']),
    description: safe(json['description']),
    document: safe(json['document']),
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

class Issue {
  final String id;
  final String userID;
  final String hostelID;
  final String type;
  final String title;
  final String description;
  final String status;

  Issue({
    this.id = '',
    this.userID = '',
    this.hostelID = '',
    this.type = '',
    this.title = '',
    this.description = '',
    this.status = '',
  });

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: safe(json['id']),
    userID: safe(json['userID'] ?? json['user_id']),
    hostelID: safe(json['hostelID'] ?? json['hostel_id']),
    type: safe(json['type']),
    title: safe(json['title']),
    description: safe(json['description']),
    status: safe(json['status']),
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
    this.status = '',
    this.createdDateTime = '',
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: safe(json['id']),
    hostelID: safe(json['hostelID'] ?? json['hostel_id']),
    title: safe(json['title']),
    note: safe(json['note']),
    img: safe(json['img']),
    status: safe(json['status']),
    createdDateTime: safe(json['createdDateTime'] ?? json['created_datetime']),
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
    this.status = '',
    this.expiryDateTime = '',
  });

  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(
    id: safe(json['id']),
    name: safe(json['name']),
    phone: safe(json['phone']),
    email: safe(json['email']),
    address: safe(json['address']),
    amenities: safe(json['amenities']),
    status: safe(json['status']),
    expiryDateTime: safe(json['expiryDateTime'] ?? json['expiry_datetime']),
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

echo "✓ Created complete models with ALL fields"

echo ""
echo "STEP 4: Fix all imports everywhere"

find lib -name "*.dart" -type f ! -name "config.dart" -exec sed -i \
  -e "s|package:cloudpgtenant/utils/config.dart|package:cloudpgtenant/config.dart|g" \
  -e "s|import 'package:cloudpgtenant/config.dart' as config;|import 'package:cloudpgtenant/config.dart';|g" \
  {} \;

echo "✓ Fixed all imports"

echo ""
echo "STEP 5: Build"

export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache
export PATH="/opt/flutter/bin:$PATH"

flutter clean > /dev/null 2>&1
flutter pub get 2>&1 | tail -3

BUILD_START=$(date +%s)

flutter build web --release --no-source-maps --base-href="/tenant/" \
  2>&1 | tee /tmp/ultimate_build.log | grep -E "Compiling|Built|✓|Error:" || true

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

if [ -f "build/web/main.dart.js" ]; then
    SIZE=$(du -h build/web/main.dart.js | cut -f1)
    
    [ -d "/usr/share/nginx/html/tenant" ] && sudo mv /usr/share/nginx/html/tenant /usr/share/nginx/html/tenant.backup.$(date +%s)
    sudo mkdir -p /usr/share/nginx/html/tenant
    sudo cp -r build/web/* /usr/share/nginx/html/tenant/
    sudo chown -R nginx:nginx /usr/share/nginx/html/tenant
    sudo chmod -R 755 /usr/share/nginx/html/tenant
    sudo systemctl reload nginx
    
    sleep 2
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/tenant/)
    
    echo ""
    echo "✅ SUCCESS!"
    echo "URL: http://13.221.117.236/tenant/"
    echo "Status: HTTP $STATUS"
    echo "Build: ${BUILD_TIME}s | Size: $SIZE"
else
    echo ""
    echo "❌ FAILED"
    grep "Error:" /tmp/ultimate_build.log | head -30
    exit 1
fi

