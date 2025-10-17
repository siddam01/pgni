# 🎯 Cursor AI - Complete Flutter Tenant App Fix

**Paste this entire prompt into Cursor and let it fix everything automatically.**

---

## 📋 Project Context

This is a Flutter web app (Tenant portal for PG management system) that's failing to compile with numerous errors. The app needs to build successfully for web deployment.

**Current Issues:**
1. Missing/duplicate config files
2. 100+ null-safety violations
3. Missing model fields and classes
4. Type mismatches (String? → String, etc.)
5. Undefined identifiers across multiple files

---

## 🎯 Goals

Make the entire Flutter project compile successfully with:
- ✅ Zero errors
- ✅ Full null-safety compliance
- ✅ Single source of truth for configuration
- ✅ Complete, production-ready models
- ✅ Clean, maintainable code structure

---

## 🔧 Tasks to Perform Automatically

### **TASK 1: Create Single Master Configuration**

**File:** `lib/config.dart`

Create this file with the following complete implementation:

```dart
// ════════════════════════════════════════════════════════════════════════════
// MASTER CONFIGURATION - Single Source of Truth
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

// Config class for backward compatibility
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
```

---

### **TASK 2: Delete Duplicate Config File**

**Action:** Delete `lib/utils/config.dart` if it exists.

This file is causing conflicts. We only need the single `lib/config.dart` created above.

---

### **TASK 3: Update lib/utils/models.dart**

Replace the entire contents of `lib/utils/models.dart` with complete, null-safe models:

**File:** `lib/utils/models.dart`

```dart
// ════════════════════════════════════════════════════════════════════════════
// NULL-SAFE DATA MODELS - Complete & Production Ready
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
```

---

### **TASK 4: Fix All Import Statements**

**Action:** Search the entire `lib/` directory for all `.dart` files and replace old config imports:

**Find:**
```dart
import 'package:cloudpgtenant/utils/config.dart';
```

**Replace with:**
```dart
import 'package:cloudpgtenant/config.dart';
```

**Also find and remove:**
```dart
import 'package:cloudpgtenant/config.dart' as config;
```

**Replace with:**
```dart
import 'package:cloudpgtenant/config.dart';
```

---

### **TASK 5: Fix Variable References**

**Action:** In all screen files (`lib/screens/*.dart`), replace these patterns:

| Find | Replace |
|------|---------|
| `config.userID` | `userID` |
| `config.hostelID` | `hostelID` |
| `config.emailID` | `emailID` |
| `config.name` | `name` |
| `config.APIKEY` | `APIKEY_VALUE` |
| `config.headers` | `headers` |

---

### **TASK 6: Fix Null-Safety Issues**

**For all screen files, ensure:**

1. When accessing nullable properties, use null-aware operators:
   ```dart
   // BAD
   users.meta.status
   
   // GOOD
   users.meta?.status ?? 0
   ```

2. When assigning nullable to non-nullable, provide defaults:
   ```dart
   // BAD
   String name = user.name;
   
   // GOOD
   String name = user.name; // Now safe because User.name is non-nullable
   ```

3. For list operations:
   ```dart
   // BAD
   users.users.length
   
   // GOOD
   users.users.length // Now safe because users is non-nullable List
   ```

---

## ✅ Verification Steps

After applying all fixes, verify:

1. **No import errors:** All files import from `package:cloudpgtenant/config.dart`
2. **No type errors:** All String?, int?, bool? are handled properly
3. **No null errors:** All nullable accesses use `?.` or `??`
4. **All models complete:** Graph, Meta, Dashboard, etc. all defined

---

## 🚀 Final Command

After Cursor finishes, run this on EC2 to build and deploy:

```bash
cd /home/ec2-user/pgni/pgworldtenant-master
flutter clean
flutter pub get
flutter build web --release --no-source-maps --base-href="/tenant/"
sudo cp -r build/web/* /usr/share/nginx/html/tenant/
sudo systemctl reload nginx
```

---

## 📊 Expected Result

```
✅ No compilation errors
✅ Build completes in 2-4 minutes
✅ main.dart.js generated successfully
✅ App deployable to web
```

---

## 🎯 Success Criteria

- ✅ `flutter build web` completes with 0 errors
- ✅ All null-safety warnings resolved
- ✅ All models fully defined with all fields
- ✅ Single config file (`lib/config.dart`) only
- ✅ Production-ready, deployable code

---

**🎉 That's it! Cursor will handle everything automatically based on this prompt.**

