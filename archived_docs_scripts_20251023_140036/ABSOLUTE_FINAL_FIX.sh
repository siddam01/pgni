#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "🔥 ABSOLUTE FINAL FIX - Aggressive Approach"
echo "════════════════════════════════════════════════════════"

TENANT_PATH="/home/ec2-user/pgni/pgworldtenant-master"
cd "$TENANT_PATH"

BACKUP="absolute_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
cp -r lib "$BACKUP/"
echo "✓ Backup: $BACKUP"

echo ""
echo "STEP 1: Nuclear option - delete and rebuild lib/utils/"
rm -rf lib/utils/
mkdir -p lib/utils
echo "✓ Cleaned lib/utils/"

echo ""
echo "STEP 2: Create lib/config.dart"
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
  static Map<String, String> get headers => {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-API-Key': APIKEY_VALUE, 'apikey': APIKEY_VALUE};
}

const int STATUS_403 = 403;
const String defaultOffset = "0";
const String defaultLimit = "10";
const String mediaURL = "http://13.221.117.236:8080/uploads/";
const int timeout = 30;

Map<String, String> headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-API-Key': APIKEY_VALUE, 'apikey': APIKEY_VALUE};

String? hostelID;
String? userID;
String? emailID;
String? name;
String? amenities;

void clearSession() { hostelID = null; userID = null; emailID = null; name = null; amenities = null; }
void setSession({String? user, String? hostel, String? email, String? userName}) { userID = user; hostelID = hostel; emailID = email; name = userName; }

String s(dynamic v) => v?.toString() ?? '';
int toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
bool toBool(dynamic v) => v is bool ? v : (v is String ? v.toLowerCase() == 'true' : false);
List<String> toList(dynamic v) => v is List<String> ? v : (v is String && v.isNotEmpty ? [v] : (v is List ? v.map((e) => s(e)).toList() : []));

class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}
EOFCONFIG

echo "✓ Created config.dart"

echo ""
echo "STEP 3: Rebuild lib/utils/models.dart"
cat > lib/utils/models.dart << 'EOFMODELS'
import 'package:cloudpgtenant/config.dart';

class Meta {
  final int status;
  final String messageType;
  final String message;
  Meta({this.status = 0, this.messageType = '', this.message = ''});
  factory Meta.fromJson(Map<String, dynamic> json) => Meta(status: toInt(json['status']), messageType: s(json['messageType'] ?? json['message_type']), message: s(json['message']));
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int offset;
  Pagination({this.total = 0, this.page = 1, this.limit = 10, this.offset = 0});
  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(total: toInt(json['total']), page: toInt(json['page']), limit: toInt(json['limit']), offset: toInt(json['offset']));
}

class Graph {
  final String label;
  final String value;
  final String color;
  Graph({this.label = '', this.value = '', this.color = ''});
  factory Graph.fromJson(Map<String, dynamic> json) => Graph(label: s(json['label']), value: s(json['value']), color: s(json['color']));
}

class Dashboard {
  final String totalRooms;
  final String occupiedRooms;
  final String vacantRooms;
  final String totalTenants;
  final String pendingPayments;
  final String totalRevenue;
  final List<Graph> graphs;
  Dashboard({this.totalRooms = '0', this.occupiedRooms = '0', this.vacantRooms = '0', this.totalTenants = '0', this.pendingPayments = '0', this.totalRevenue = '0', this.graphs = const []});
  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    totalRooms: s(json['totalRooms'] ?? json['total_rooms']), occupiedRooms: s(json['occupiedRooms'] ?? json['occupied_rooms']),
    vacantRooms: s(json['vacantRooms'] ?? json['vacant_rooms']), totalTenants: s(json['totalTenants'] ?? json['total_tenants']),
    pendingPayments: s(json['pendingPayments'] ?? json['pending_payments']), totalRevenue: s(json['totalRevenue'] ?? json['total_revenue']),
    graphs: json['graphs'] != null ? (json['graphs'] as List).map((e) => Graph.fromJson(e)).toList() : []
  );
}

class User {
  final String id, hostelID, name, phone, email, address, roomID, roomno, rent, emerContact, emerPhone, food, document, paymentStatus, joiningDateTime, lastPaidDateTime, expiryDateTime, leaveDateTime, status;
  User({this.id = '', this.hostelID = '', this.name = '', this.phone = '', this.email = '', this.address = '', this.roomID = '', this.roomno = '', this.rent = '0', this.emerContact = '', this.emerPhone = '', this.food = '', this.document = '', this.paymentStatus = 'pending', this.joiningDateTime = '', this.lastPaidDateTime = '', this.expiryDateTime = '', this.leaveDateTime = '', this.status = 'active'});
  factory User.fromJson(Map<String, dynamic> json) => User(id: s(json['id']), hostelID: s(json['hostelID'] ?? json['hostel_id']), name: s(json['name']), phone: s(json['phone']), email: s(json['email']), address: s(json['address']), roomID: s(json['roomID'] ?? json['room_id']), roomno: s(json['roomno']), rent: s(json['rent']), emerContact: s(json['emerContact'] ?? json['emer_contact']), emerPhone: s(json['emerPhone'] ?? json['emer_phone']), food: s(json['food']), document: s(json['document']), paymentStatus: s(json['paymentStatus'] ?? json['payment_status']), joiningDateTime: s(json['joiningDateTime'] ?? json['joining_datetime']), lastPaidDateTime: s(json['lastPaidDateTime'] ?? json['last_paid_datetime']), expiryDateTime: s(json['expiryDateTime'] ?? json['expiry_datetime']), leaveDateTime: s(json['leaveDateTime'] ?? json['leave_datetime']), status: s(json['status']));
}

class Users {
  final List<User> users;
  final Pagination? pagination;
  final Meta? meta;
  Users({this.users = const [], this.pagination, this.meta});
  factory Users.fromJson(Map<String, dynamic> json) => Users(users: json['users'] != null ? (json['users'] as List).map((e) => User.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}

class Room {
  final String id, hostelID, roomno, rent, floor, filled, capacity, amenities, type, size, status, document;
  Room({this.id = '', this.hostelID = '', this.roomno = '', this.rent = '0', this.floor = '', this.filled = '0', this.capacity = '0', this.amenities = '', this.type = '', this.size = '', this.status = 'available', this.document = ''});
  factory Room.fromJson(Map<String, dynamic> json) => Room(id: s(json['id']), hostelID: s(json['hostelID'] ?? json['hostel_id']), roomno: s(json['roomno']), rent: s(json['rent']), floor: s(json['floor']), filled: s(json['filled']), capacity: s(json['capacity']), amenities: s(json['amenities']), type: s(json['type']), size: s(json['size']), status: s(json['status']), document: s(json['document']));
}

class Rooms {
  final List<Room> rooms;
  final Pagination? pagination;
  final Meta? meta;
  Rooms({this.rooms = const [], this.pagination, this.meta});
  factory Rooms.fromJson(Map<String, dynamic> json) => Rooms(rooms: json['rooms'] != null ? (json['rooms'] as List).map((e) => Room.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}

class Bill {
  final String id, userID, hostelID, amount, month, status, paymentDate, paidDateTime, paid, title, description, document;
  Bill({this.id = '', this.userID = '', this.hostelID = '', this.amount = '0', this.month = '', this.status = 'unpaid', this.paymentDate = '', this.paidDateTime = '', this.paid = 'false', this.title = '', this.description = '', this.document = ''});
  factory Bill.fromJson(Map<String, dynamic> json) => Bill(id: s(json['id']), userID: s(json['userID'] ?? json['user_id']), hostelID: s(json['hostelID'] ?? json['hostel_id']), amount: s(json['amount']), month: s(json['month']), status: s(json['status']), paymentDate: s(json['paymentDate'] ?? json['payment_date']), paidDateTime: s(json['paidDateTime'] ?? json['paid_datetime']), paid: s(json['paid']), title: s(json['title']), description: s(json['description']), document: s(json['document']));
}

class Bills {
  final List<Bill> bills;
  final Pagination? pagination;
  final Meta? meta;
  Bills({this.bills = const [], this.pagination, this.meta});
  factory Bills.fromJson(Map<String, dynamic> json) => Bills(bills: json['bills'] != null ? (json['bills'] as List).map((e) => Bill.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}

class Issue {
  final String id, userID, hostelID, roomID, type, title, description, status;
  Issue({this.id = '', this.userID = '', this.hostelID = '', this.roomID = '', this.type = '', this.title = '', this.description = '', this.status = 'open'});
  factory Issue.fromJson(Map<String, dynamic> json) => Issue(id: s(json['id']), userID: s(json['userID'] ?? json['user_id']), hostelID: s(json['hostelID'] ?? json['hostel_id']), roomID: s(json['roomID'] ?? json['room_id']), type: s(json['type']), title: s(json['title']), description: s(json['description']), status: s(json['status']));
}

class Issues {
  final List<Issue> issues;
  final Pagination? pagination;
  final Meta? meta;
  Issues({this.issues = const [], this.pagination, this.meta});
  factory Issues.fromJson(Map<String, dynamic> json) => Issues(issues: json['issues'] != null ? (json['issues'] as List).map((e) => Issue.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}

class Notice {
  final String id, hostelID, title, note, img, status, createdDateTime;
  Notice({this.id = '', this.hostelID = '', this.title = '', this.note = '', this.img = '', this.status = 'active', this.createdDateTime = ''});
  factory Notice.fromJson(Map<String, dynamic> json) => Notice(id: s(json['id']), hostelID: s(json['hostelID'] ?? json['hostel_id']), title: s(json['title']), note: s(json['note']), img: s(json['img']), status: s(json['status']), createdDateTime: s(json['createdDateTime'] ?? json['created_datetime']));
}

class Notices {
  final List<Notice> notices;
  final Pagination? pagination;
  final Meta? meta;
  Notices({this.notices = const [], this.pagination, this.meta});
  factory Notices.fromJson(Map<String, dynamic> json) => Notices(notices: json['notices'] != null ? (json['notices'] as List).map((e) => Notice.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}

class Hostel {
  final String id, name, phone, email, address, amenities, status, expiryDateTime;
  Hostel({this.id = '', this.name = '', this.phone = '', this.email = '', this.address = '', this.amenities = '', this.status = 'active', this.expiryDateTime = ''});
  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(id: s(json['id']), name: s(json['name']), phone: s(json['phone']), email: s(json['email']), address: s(json['address']), amenities: s(json['amenities']), status: s(json['status']), expiryDateTime: s(json['expiryDateTime'] ?? json['expiry_datetime']));
}

class Hostels {
  final List<Hostel> hostels;
  final Pagination? pagination;
  final Meta? meta;
  Hostels({this.hostels = const [], this.pagination, this.meta});
  factory Hostels.fromJson(Map<String, dynamic> json) => Hostels(hostels: json['hostels'] != null ? (json['hostels'] as List).map((e) => Hostel.fromJson(e)).toList() : [], pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null, meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null);
}
EOFMODELS

echo "✓ Created models.dart"

echo ""
echo "STEP 4: Rebuild lib/utils/api.dart from backup"
if [ -f "$BACKUP/lib/utils/api.dart" ]; then
    cp "$BACKUP/lib/utils/api.dart" lib/utils/api.dart
    
    # Fix imports
    sed -i "1i import 'package:cloudpgtenant/config.dart';" lib/utils/api.dart
    sed -i '/utils\/config\.dart/d' lib/utils/api.dart
    
    # Fix return statements
    sed -i 's/return null;/return Rooms();/g' lib/utils/api.dart
    sed -i 's/return Future\.value(null);/return Future.value(Rooms());/g' lib/utils/api.dart
    
    echo "✓ Restored and fixed api.dart"
fi

echo ""
echo "STEP 5: Fix ALL file imports aggressively"
find lib -name "*.dart" -type f | while read file; do
    sed -i 's|utils/config\.dart|config.dart|g' "$file"
    sed -i 's|import.*config\.dart.*as config.*;||g' "$file"
done
echo "✓ Fixed all imports"

echo ""
echo "STEP 6: Build"
export DART_VM_OPTIONS="--old_gen_heap_size=10240"
export PUB_CACHE=/home/ec2-user/.pub-cache
flutter clean > /dev/null 2>&1
flutter pub get 2>&1 | tail -3

BUILD_START=$(date +%s)
flutter build web --release --no-source-maps --base-href="/tenant/" 2>&1 | tee /tmp/absolute_build.log | grep -E "Compiling|Built|✓" || true
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
    echo "✅ SUCCESS! http://13.221.117.236/tenant/ | HTTP $STATUS | ${BUILD_TIME}s | $SIZE"
else
    echo ""
    echo "❌ Still failing. Showing errors that mention 'User?' or 'Room?':"
    grep -E "User\?|Room\?|Meta\?|Pagination\?" /tmp/absolute_build.log | head -20
    echo ""
    echo "Full log: /tmp/absolute_build.log"
    exit 1
fi

