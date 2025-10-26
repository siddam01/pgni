class Config {
  // API Base URL
  static const String URL = "54.227.101.30:8080";
  static const String BASE_URL = "http://54.227.101.30:8080";
  static const String apiBaseUrl = BASE_URL;
  
  // Media URL
  static const String mediaURL = '$BASE_URL/media/';
  
  // Status codes
  static const int STATUS_403 = 403;
  
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
  
  // RBAC endpoints
  static const String PERMISSIONS_GET = '/permissions/get';
  static const String PERMISSIONS_CHECK = '/permissions/check';
  static const String MANAGER_LIST = '/manager/list';
  static const String MANAGER_INVITE = '/manager/invite';
  static const String MANAGER_PERMISSIONS = '/manager/permissions';
  static const String MANAGER_REMOVE = '/manager/remove';
}
