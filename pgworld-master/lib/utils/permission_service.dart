import 'dart:convert';
import 'package:cloudpg/utils/utils.dart';
import 'package:cloudpg/utils/api.dart';
import 'package:cloudpg/utils/config.dart';

/// PermissionService - Manages RBAC permissions for admin users
/// 
/// This service handles:
/// - Fetching permissions from backend
/// - Caching permissions locally
/// - Checking if user has specific permissions
/// - Managing owner vs manager roles
class PermissionService {
  static Map<String, dynamic>? _permissions;
  static String? _role;
  static bool _isInitialized = false;

  /// Load permissions for the current user
  /// Call this after successful login
  static Future<bool> loadPermissions(String adminId, String hostelId) async {
    try {
      final response = await getPermissions({
        'admin_id': adminId,
        'hostel_id': hostelId,
      });

      if (response.meta.status == "200" && response.data != null) {
        _permissions = response.data;
        _role = _permissions?['role'];
        
        // Cache permissions in SharedPreferences
        await prefs.setString('permissions', jsonEncode(_permissions));
        await prefs.setString('user_role', _role ?? 'none');
        
        _isInitialized = true;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error loading permissions: $e');
      return false;
    }
  }

  /// Initialize permissions from cache
  /// Call this on app startup if user is already logged in
  static void initFromCache() {
    try {
      final cachedPermissions = prefs.getString('permissions');
      final cachedRole = prefs.getString('user_role');
      
      if (cachedPermissions != null && cachedPermissions.isNotEmpty) {
        _permissions = jsonDecode(cachedPermissions);
        _role = cachedRole ?? 'none';
        _isInitialized = true;
      }
    } catch (e) {
      print('Error initializing permissions from cache: $e');
      _isInitialized = false;
    }
  }

  /// Check if user has a specific permission
  /// Returns true if user is owner or has the specific permission
  static bool hasPermission(String permission) {
    // If not initialized, try to load from cache
    if (!_isInitialized) {
      initFromCache();
    }

    // Owners have all permissions
    if (_role == 'owner' || prefs.getString('admin') == '1') {
      return true;
    }

    // Managers need specific permission
    if (_permissions == null) {
      return false;
    }

    // Check if permission exists and is true
    final permissionValue = _permissions![permission];
    if (permissionValue is bool) {
      return permissionValue;
    } else if (permissionValue is int) {
      return permissionValue == 1;
    } else if (permissionValue is String) {
      return permissionValue == '1' || permissionValue.toLowerCase() == 'true';
    }

    return false;
  }

  /// Check if user is an owner
  static bool isOwner() {
    if (!_isInitialized) {
      initFromCache();
    }
    return _role == 'owner' || prefs.getString('admin') == '1';
  }

  /// Check if user is a manager
  static bool isManager() {
    if (!_isInitialized) {
      initFromCache();
    }
    return _role == 'manager' && prefs.getString('admin') != '1';
  }

  /// Get current user role
  static String getRole() {
    if (!_isInitialized) {
      initFromCache();
    }
    return _role ?? 'none';
  }

  /// Get all permissions as a map
  static Map<String, dynamic>? getAllPermissions() {
    if (!_isInitialized) {
      initFromCache();
    }
    return _permissions;
  }

  /// Clear permissions (on logout)
  static Future<void> clearPermissions() async {
    _permissions = null;
    _role = null;
    _isInitialized = false;
    await prefs.remove('permissions');
    await prefs.remove('user_role');
  }

  /// Refresh permissions from server
  static Future<bool> refreshPermissions() async {
    final adminId = prefs.getString('adminID');
    final hostelId = Config.hostelID;

    if (adminId != null && hostelId != null) {
      return await loadPermissions(adminId, hostelId);
    }

    return false;
  }

  // Permission constants for easy reference
  static const String PERMISSION_VIEW_DASHBOARD = 'can_view_dashboard';
  static const String PERMISSION_MANAGE_ROOMS = 'can_manage_rooms';
  static const String PERMISSION_MANAGE_TENANTS = 'can_manage_tenants';
  static const String PERMISSION_MANAGE_BILLS = 'can_manage_bills';
  static const String PERMISSION_VIEW_FINANCIALS = 'can_view_financials';
  static const String PERMISSION_MANAGE_EMPLOYEES = 'can_manage_employees';
  static const String PERMISSION_VIEW_REPORTS = 'can_view_reports';
  static const String PERMISSION_MANAGE_NOTICES = 'can_manage_notices';
  static const String PERMISSION_MANAGE_ISSUES = 'can_manage_issues';
  static const String PERMISSION_MANAGE_PAYMENTS = 'can_manage_payments';
}

