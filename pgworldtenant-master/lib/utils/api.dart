import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:async/async.dart';

import 'package:http/http.dart' as http;

import './models.dart';
import './config.dart';

// otp

Future<Meta> sendOTP(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.SEND_OTP, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Meta.fromJson(json.decode(response.body));
}

Future<Meta> verifyOTP(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.VERIFY_OTP, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Meta.fromJson(json.decode(response.body));
}

// bill

Future<Bills> getBills(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.BILL, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Bills.fromJson(json.decode(response.body));
}

// user

Future<Users> getUsers(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.USER, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Users.fromJson(json.decode(response.body));
}

// hostels

Future<Hostels> getHostels(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.HOSTEL, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Hostels.fromJson(json.decode(response.body));
}

// issues

Future<Issues> getIssues(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.ISSUE, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Issues.fromJson(json.decode(response.body));
}

// notices

Future<Notices> getNotices(Map<String, String> query) async {
  final response = await http
      .get(Uri.http(API.URL, API.NOTICE, query), headers: headers)
      .timeout(Duration(seconds: timeout));

  return Notices.fromJson(json.decode(response.body));
}

// rooms

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
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  var response = await request.send();
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}

Future<bool> update(String endpoint, Map<String, String> body,
    Map<String, String> query) async {
  var request = new http.MultipartRequest(
    "PUT",
    Uri.http(API.URL, endpoint, query),
  );
  request.headers.addAll(headers);
  body.forEach((k, v) {
    request.fields[k] = v;
  });

  var response = await request.send();
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}

Future<bool> delete(String endpoint, Map<String, String> query) async {
  var request = new http.MultipartRequest(
    "DELETE",
    Uri.http(API.URL, endpoint, query),
  );

  request.headers.addAll(headers);

  var response = await request.send();
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}

Future<String> upload(File file) async {
  var request = new http.MultipartRequest(
    "POST",
    Uri.http(
      API.URL,
      "upload",
    ),
  );
  request.headers.addAll(headers);

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
      if (data["data"] != null && data["data"].length > 0) {
        return data["data"][0]["image"];
      }
    }
  } catch (e) {
    print("Upload error: $e");
  }
  return "";
}

// Update user profile
Future<bool> updateUserProfile(
    Map<String, String> body, Map<String, String> query) async {
  try {
    var request = new http.MultipartRequest(
      "PUT",
      Uri.http(API.URL, API.USER, query),
    );
    request.headers.addAll(headers);
    body.forEach((k, v) {
      request.fields[k] = v;
    });

    var response = await request.send();
    if (response.statusCode == 200) {
      return true;
    }
  } catch (e) {
    print("Update error: $e");
  }
  return false;
}
