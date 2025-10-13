class API {
  static const URL = "34.227.111.143:8080";
  static const ADMIN = "admin";
  static const BILL = "bill";
  static const DASHBOARD = "dashboard";
  static const EMPLOYEE = "employee";
  static const ISSUE = "issue";
  static const LOG = "log";
  static const NOTE = "note";
  static const NOTICE = "notice";
  static const REPORT = "report";
  static const ROOM = "room";
  static const USER = "user";
  static const SIGNUP = "signup";
  static const SUPPORT = "support";
  static const HOSTEL = "hostel";

  static const SEND_OTP = "sendotp";
  static const VERIFY_OTP = "verifyotp";

  static const RENT = "rent";
  static const SALARY = "salary";
}

const ONESIGNAL_APP_ID = "47916c74-a7c2-4819-bb65-911776d5b814";
String supportMail = "support@cloudpg.com";

class COLORS {
  static const RED = "#E1A1AD";
  static const GREEN = "#9AD7CB";
}

String mediaURL = "https://test-pgworld.s3.ap-south-1.amazonaws.com/";

class APPVERSION {
  static const ANDROID = "1.7";
  static const IOS = "1.1";
}

class APIKEY {
  static const ANDROID_LIVE = "T9h9P6j2N6y9M3Q8";
  static const ANDROID_TEST = "K7b3V4h3C7t6g6M7";
  static const IOS_LIVE = "b4E6U9K8j6b5E9W3";
  static const IOS_TEST = "R4n7N8G4m9B4S5n2";
}

String name = "";
String emailID = "";
String hostelID = "";
String userID = "";
List<String> amenities = <String>[];

Map<String, String> headers = {
  "pkgname": "com.saikrishna.cloudpgtenant",
  "Accept-Encoding": "gzip"
};

const timeout = 10;

const defaultLimit = "25";
const defaultOffset = "0";

// status
const STATUS_400 = "400";
const STATUS_403 = "403"; // forbidden
const STATUS_500 = "500";

List<List<String>> billTypes = [
  ["Cable Bill", "1"],
  ["Water Bill", "2"],
  ["Electricity Bill", "3"],
  ["Food Expense", "4"],
  ["Internet Bill", "5"],
  ["Maintainance", "6"],
  ["Property Rent/Tax", "7"],
  ["Others", "8"],
];
