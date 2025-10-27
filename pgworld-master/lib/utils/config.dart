class Config {
  // API Base URL
  static const String URL = "54.227.101.30:8080";
  static const String BASE_URL = "http://54.227.101.30:8080";
  static const String apiBaseUrl = BASE_URL;
  
  // Media URL
  static const String mediaURL = '$BASE_URL/media/';
  
  // Status codes
  static const String STATUS_403 = "403";
  static const String STATUS_200 = "200";
  static const String STATUS_400 = "400";
  static const String STATUS_500 = "500";
  
  // Pagination defaults
  static const String defaultLimit = "20";
  static const String defaultOffset = "0";
  
  // Session variables (set after login)
  static String? hostelID;
  static String? userID;
  static String? emailID;
  static String? name;
  
  // Bill types
  static const List<String> billTypes = [
    'Rent',
    'Electricity',
    'Water',
    'Maintenance',
    'Other'
  ];
  
  // Payment types
  static const List<String> paymentTypes = [
    'Cash',
    'Online',
    'UPI',
    'Card',
    'Cheque'
  ];
  
  // Amenity types
  static const List<String> amenityTypes = [
    'WiFi',
    'AC',
    'Parking',
    'Gym',
    'Laundry',
    'Security',
    'Power Backup',
    'Water Supply'
  ];
  
  // Amenities (for backward compatibility)
  static const List<String> amenities = amenityTypes;
  
  // API endpoints
  static const String API_BILL = '/bills';
  static const String API_USER = '/users';
  static const String API_EMPLOYEE = '/employees';
  static const String API_NOTICE = '/notices';
  static const String API_HOSTEL = '/hostels';
  static const String API_ROOM = '/rooms';
  static const String API_FOOD = '/food';
  static const String API_STATUS = '/status';
  
  // RBAC endpoints
  static const String API_PERMISSIONS_GET = '/permissions/get';
  static const String API_PERMISSIONS_CHECK = '/permissions/check';
  static const String API_MANAGER_LIST = '/manager/list';
  static const String API_MANAGER_INVITE = '/manager/invite';
  static const String API_MANAGER_PERMISSIONS = '/manager/permissions';
  static const String API_MANAGER_REMOVE = '/manager/remove';
}

// Colors constants
class COLORS {
  static const String RED = "#F44336";
  static const String GREEN = "#4CAF50";
  static const String BLUE = "#2196F3";
  static const String ORANGE = "#FF9800";
  static const String PURPLE = "#9C27B0";
  static const String GREY = "#9E9E9E";
}

// App version constants
class APPVERSION {
  static const String ANDROID = "1.0.0";
  static const String IOS = "1.0.0";
  static const String WEB = "1.0.0";
}

// Contact/Links constants
class CONTACT {
  static const String TERMS_URL = "https://cloudpg.com/terms";
  static const String PRIVACY_URL = "https://cloudpg.com/privacy";
  static const String ABOUT_URL = "https://cloudpg.com/about";
  static const String SUPPORT_EMAIL = "support@cloudpg.com";
  static const String WEBSITE = "https://cloudpg.com";
}

// API Keys (for backward compatibility)
class APIKEY {
  static const String ANDROID_LIVE = "your_android_live_key";
  static const String ANDROID_TEST = "your_android_test_key";
  static const String IOS_LIVE = "your_ios_live_key";
  static const String IOS_TEST = "your_ios_test_key";
}

// API endpoints class (for backward compatibility)
class API {
  static const String URL = Config.URL;
  static const String BILL = '/bill';
  static const String USER = '/user';
  static const String EMPLOYEE = '/employee';
  static const String NOTICE = '/notice';
  static const String HOSTEL = '/hostel';
  static const String ROOM = '/room';
  static const String FOOD = '/food';
  static const String STATUS = '/status';
  static const String ADMIN = '/admin';
  static const String DASHBOARD = '/dashboard';
  static const String INVOICE = '/invoice';
  static const String ISSUE = '/issue';
  static const String LOG = '/log';
  static const String NOTE = '/note';
  static const String REPORT = '/report';
  static const String SIGNUP = '/signup';
  static const String SUPPORT = '/support';
  static const String UPLOAD = '/upload';
  static const String RENT = '/rent';  // Added for bill.dart
  
  // RBAC endpoints
  static const String PERMISSIONS_GET = '/permissions/get';
  static const String PERMISSIONS_CHECK = '/permissions/check';
  static const String MANAGER_LIST = '/manager/list';
  static const String MANAGER_INVITE = '/manager/invite';
  static const String MANAGER_PERMISSIONS = '/manager/permissions';
  static const String MANAGER_REMOVE = '/manager/remove';
}
