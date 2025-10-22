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
}

// API endpoints class (for backward compatibility)
class API {
  static const String BILL = '/bills';
  static const String USER = '/users';
  static const String EMPLOYEE = '/employees';
  static const String NOTICE = '/notices';
  static const String HOSTEL = '/hostels';
  static const String ROOM = '/rooms';
  static const String FOOD = '/food';
  static const String STATUS = '/status';
}
