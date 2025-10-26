import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/models.dart';
import '../utils/config.dart';
import '../utils/utils.dart';

/// Edit Manager Permissions Screen
class ManagerPermissionsActivity extends StatefulWidget {
  final Manager manager;

  ManagerPermissionsActivity({required this.manager});

  @override
  ManagerPermissionsActivityState createState() => ManagerPermissionsActivityState();
}

class ManagerPermissionsActivityState extends State<ManagerPermissionsActivity> {
  bool loading = false;
  bool hasChanges = false;

  // Permission checkboxes
  Map<String, bool> permissions = {};

  @override
  void initState() {
    super.initState();
    loadPermissions();
  }

  Future<void> loadPermissions() async {
    setState(() => loading = true);

    try {
      final adminId = widget.manager.id;
      final hostelId = Config.hostelID;

      if (hostelId == null) {
        setState(() => loading = false);
        return;
      }

      final response = await getPermissions({
        'admin_id': adminId,
        'hostel_id': hostelId,
      });

      if (response.meta.status == "200" && response.data != null) {
        setState(() {
          // Parse permissions from API response
          permissions = {
            'can_view_dashboard': _parseBool(response.data!['can_view_dashboard']),
            'can_manage_rooms': _parseBool(response.data!['can_manage_rooms']),
            'can_manage_tenants': _parseBool(response.data!['can_manage_tenants']),
            'can_manage_bills': _parseBool(response.data!['can_manage_bills']),
            'can_view_financials': _parseBool(response.data!['can_view_financials']),
            'can_manage_employees': _parseBool(response.data!['can_manage_employees']),
            'can_view_reports': _parseBool(response.data!['can_view_reports']),
            'can_manage_notices': _parseBool(response.data!['can_manage_notices']),
            'can_manage_issues': _parseBool(response.data!['can_manage_issues']),
            'can_manage_payments': _parseBool(response.data!['can_manage_payments']),
          };
          loading = false;
        });
      } else {
        setState(() => loading = false);
        if (mounted) {
          oneButtonDialog(context, "Error", response.meta.message, true);
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        oneButtonDialog(context, "Error", "Failed to load permissions: $e", true);
      }
    }
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Future<void> savePermissions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Permissions'),
        content: Text(
          'Are you sure you want to update permissions for ${widget.manager.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    try {
      final ownerId = prefs.getString('adminID');
      final hostelId = Config.hostelID;

      if (ownerId == null || hostelId == null) {
        setState(() => loading = false);
        return;
      }

      final data = {
        'owner_id': ownerId,
        'manager_id': widget.manager.id,
        'hostel_id': hostelId,
      };

      // Add permissions
      permissions.forEach((key, value) {
        data[key] = value ? '1' : '0';
      });

      final response = await updateManagerPermissions(data);

      setState(() => loading = false);

      if (response.meta.status == "200") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.meta.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void togglePermission(String key, bool? value) {
    setState(() {
      permissions[key] = value ?? false;
      hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (hasChanges) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Discard Changes'),
              content: Text('You have unsaved changes. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Discard'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2.0,
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(
            'Edit Permissions',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (hasChanges)
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: savePermissions,
                tooltip: 'Save',
              ),
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: loading,
          child: Column(
            children: [
              // Manager info header
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        widget.manager.name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.manager.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.manager.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Permissions list
              Expanded(
                child: permissions.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          _buildSectionHeader('Dashboard & Analytics'),
                          _buildPermissionCard(
                            'can_view_dashboard',
                            'View Dashboard',
                            'Access to analytics, statistics, and overview',
                            Icons.dashboard,
                            Colors.blue,
                          ),
                          SizedBox(height: 16),
                          _buildSectionHeader('Property Management'),
                          _buildPermissionCard(
                            'can_manage_rooms',
                            'Manage Rooms',
                            'Add, edit, and delete rooms',
                            Icons.meeting_room,
                            Colors.green,
                          ),
                          SizedBox(height: 8),
                          _buildPermissionCard(
                            'can_manage_tenants',
                            'Manage Tenants',
                            'Add, edit, and manage tenant information',
                            Icons.people,
                            Colors.purple,
                          ),
                          SizedBox(height: 16),
                          _buildSectionHeader('Financial Management'),
                          _buildPermissionCard(
                            'can_manage_bills',
                            'Manage Bills',
                            'Create and manage tenant bills',
                            Icons.receipt,
                            Colors.orange,
                          ),
                          SizedBox(height: 8),
                          _buildPermissionCard(
                            'can_view_financials',
                            'View Financials',
                            'Access financial reports and revenue data',
                            Icons.attach_money,
                            Colors.teal,
                          ),
                          SizedBox(height: 8),
                          _buildPermissionCard(
                            'can_manage_payments',
                            'Manage Payments',
                            'Process and track payments',
                            Icons.payment,
                            Colors.indigo,
                          ),
                          SizedBox(height: 16),
                          _buildSectionHeader('Staff & Operations'),
                          _buildPermissionCard(
                            'can_manage_employees',
                            'Manage Employees',
                            'Add and manage staff members',
                            Icons.badge,
                            Colors.cyan,
                          ),
                          SizedBox(height: 8),
                          _buildPermissionCard(
                            'can_manage_notices',
                            'Manage Notices',
                            'Post and manage notices for tenants',
                            Icons.announcement,
                            Colors.amber,
                          ),
                          SizedBox(height: 8),
                          _buildPermissionCard(
                            'can_manage_issues',
                            'Manage Issues',
                            'View and resolve tenant complaints',
                            Icons.support_agent,
                            Colors.red,
                          ),
                          SizedBox(height: 16),
                          _buildSectionHeader('Reports & Analytics'),
                          _buildPermissionCard(
                            'can_view_reports',
                            'View Reports',
                            'Generate and view detailed reports',
                            Icons.assessment,
                            Colors.deepPurple,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: hasChanges
            ? SafeArea(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Cancel'),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: savePermissions,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Save Changes'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    String key,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isEnabled = permissions[key] ?? false;

    return Card(
      elevation: 2,
      child: SwitchListTile(
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isEnabled ? color : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        value: isEnabled,
        onChanged: (value) => togglePermission(key, value),
        activeColor: color,
      ),
    );
  }
}

