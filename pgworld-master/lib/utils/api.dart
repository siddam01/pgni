import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:async/async.dart';

import 'package:http/http.dart' as http;

import './models.dart';
import './config.dart';

// admin

Future<Admins> getAdmins(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.ADMIN, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Admins.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// bill

Future<Bills> getBills(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.BILL, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Bills.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// dashboard

Future<Dashboards> getDashboards(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.DASHBOARD, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Dashboards.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// employee

Future<Employees> getEmployees(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.EMPLOYEE, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Employees.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// food

Future<Foods> getFoods(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.FOOD, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Foods.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// invoice

Future<Invoices> getInvoices(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.INVOICE, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Invoices.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// issue

Future<Issues> getIssues(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.ISSUE, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Issues.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// log

Future<Logs> getLogs(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.LOG, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Logs.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// note

Future<Notes> getNotes(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.NOTE, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Notes.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// notice

Future<Notices> getNotices(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.NOTICE, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Notices.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// report

Future<Charts> getReports(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.REPORT, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Charts.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// room

Future<Rooms> getRooms(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.ROOM, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Rooms.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// user

Future<Users> getUsers(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.USER, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Users.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// hostels

Future<Hostels> getHostels(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.HOSTEL, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Hostels.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// status

Future<Admins> getStatus(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.STATUS, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return Admins.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}

// add and update
Future<bool> add(String endpoint, Map<String, String> body) async {
  if (body["status"] != null) {
    body["status"] = "1";
  }
  var request = new http.MultipartRequest(
    "POST",
    Uri.http(
      API.URL,
      endpoint,
    ),
  );
  request.headers.addAll(headers);
  request.fields["admin_name"] = adminName;
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  } catch (e) {
    return null;
  }
}

Future<bool> update(String endpoint, Map<String, String> body,
    Map<String, String> query) async {
  var request = new http.MultipartRequest(
    "PUT",
    Uri.http(API.URL, endpoint, query),
  );
  request.headers.addAll(headers);
  request.fields["admin_name"] = adminName;
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  } catch (e) {
    return null;
  }
}

Future<bool> delete(String endpoint, Map<String, String> query) async {
  var request = new http.MultipartRequest(
    "DELETE",
    Uri.http(API.URL, endpoint, query),
  );
  request.fields["admin_name"] = adminName;

  request.headers.addAll(headers);

  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  } catch (e) {
    return null;
  }
}

Future<String> upload(File file) async {
  var request = new http.MultipartRequest(
    "POST",
    Uri.http(
      API.URL,
      API.UPLOAD,
    ),
  );
  request.headers.addAll(headers);
  request.fields["admin_name"] = adminName;

  var stream = new http.ByteStream(DelegatingStream.typed(file.openRead()));
  // get file length
  var length = await file.length();
  // multipart that takes file
  var multipartFile = new http.MultipartFile('photo', stream, length,
      filename: basename(file.path));

  // add file to multipart
  request.files.add(multipartFile);

  try {
    var response = await request.send();

    if (response.statusCode == 200) {
      String responseData =
          await response.stream.transform(utf8.decoder).join();
      Map data = json.decode(responseData);
      if (data["data"] != null) {
        return data["data"][0]["image"];
      }
    }
    return "";
  } catch (e) {
    return null;
  }
}

// RBAC - Permissions

/// Get all permissions for an admin on a specific hostel
Future<PermissionsResponse> getPermissions(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.PERMISSIONS_GET, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return PermissionsResponse.fromJson(json.decode(response.body));
  } catch (e) {
    print('Error getting permissions: $e');
    return PermissionsResponse(
      data: null,
      meta: Meta(status: '500', message: 'Failed to load permissions', messageType: '1'),
    );
  }
}

/// Check if admin has a specific permission
Future<PermissionsResponse> checkPermission(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.PERMISSIONS_CHECK, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return PermissionsResponse.fromJson(json.decode(response.body));
  } catch (e) {
    print('Error checking permission: $e');
    return PermissionsResponse(
      data: null,
      meta: Meta(status: '500', message: 'Failed to check permission', messageType: '1'),
    );
  }
}

// RBAC - Manager Management

/// Get list of managers for an owner
Future<ManagersResponse> getManagers(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.MANAGER_LIST, query), headers: headers)
        .timeout(Duration(seconds: timeout));

    return ManagersResponse.fromJson(json.decode(response.body));
  } catch (e) {
    print('Error getting managers: $e');
    return ManagersResponse(
      managers: [],
      meta: Meta(status: '500', message: 'Failed to load managers', messageType: '1'),
    );
  }
}

/// Invite a new manager
Future<Post> inviteManager(Map<String, String> body) async {
  var request = new http.MultipartRequest(
    "POST",
    Uri.http(API.URL, API.MANAGER_INVITE),
  );
  request.headers.addAll(headers);
  request.fields["admin_name"] = adminName;
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  try {
    var response = await request.send();
    String responseData = await response.stream.transform(utf8.decoder).join();
    return Post.fromJson(json.decode(responseData));
  } catch (e) {
    print('Error inviting manager: $e');
    return Post(
      id: '',
      meta: Meta(status: '500', message: 'Failed to invite manager', messageType: '1'),
    );
  }
}

/// Update manager permissions
Future<Post> updateManagerPermissions(Map<String, String> body) async {
  var request = new http.MultipartRequest(
    "PUT",
    Uri.http(API.URL, API.MANAGER_PERMISSIONS),
  );
  request.headers.addAll(headers);
  request.fields["admin_name"] = adminName;
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  try {
    var response = await request.send();
    String responseData = await response.stream.transform(utf8.decoder).join();
    return Post.fromJson(json.decode(responseData));
  } catch (e) {
    print('Error updating permissions: $e');
    return Post(
      id: '',
      meta: Meta(status: '500', message: 'Failed to update permissions', messageType: '1'),
    );
  }
}

/// Remove a manager
Future<Post> removeManager(Map<String, String> query) async {
  try {
    var request = new http.MultipartRequest(
      "DELETE",
      Uri.http(API.URL, API.MANAGER_REMOVE, query),
    );
    request.headers.addAll(headers);
    request.fields["admin_name"] = adminName;

    var response = await request.send();
    String responseData = await response.stream.transform(utf8.decoder).join();
    return Post.fromJson(json.decode(responseData));
  } catch (e) {
    print('Error removing manager: $e');
    return Post(
      id: '',
      meta: Meta(status: '500', message: 'Failed to remove manager', messageType: '1'),
    );
  }
}