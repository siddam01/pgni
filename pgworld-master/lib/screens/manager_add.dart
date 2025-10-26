import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'dart:math';

import '../utils/api.dart';
import '../utils/models.dart';
import '../utils/config.dart';
import '../utils/utils.dart';

/// Add Manager Screen - Invite new manager with permissions
class ManagerAddActivity extends StatefulWidget {
  @override
  ManagerAddActivityState createState() => ManagerAddActivityState();
}

class ManagerAddActivityState extends State<ManagerAddActivity> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Permission checkboxes
  Map<String, bool> permissions = {
    'can_view_dashboard': true, // Default to true
    'can_manage_rooms': false,
    'can_manage_tenants': false,
    'can_manage_bills': false,
    'can_view_financials': false,
    'can_manage_employees': false,
    'can_view_reports': false,
    'can_manage_notices': false,
    'can_manage_issues': false,
    'can_manage_payments': false,
  };

  List<Hostel> availableHostels = [];
  List<String> selectedHostelIds = [];

  @override
  void initState() {
    super.initState();
    loadHostels();
    generatePassword(); // Auto-generate password
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final password = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
    passwordController.text = password;
  }

  Future<void> loadHostels() async {
    try {
      final adminId = prefs.getString('adminID');
      final hostelIds = prefs.getString('hostelIDs');

      if (hostelIds != null && hostelIds.isNotEmpty) {
        final response = await getHostels({'id': hostelIds, 'status': '1'});

        if (response.meta.status == "200") {
          setState(() {
            availableHostels = response.hostels;
            // Auto-select current hostel
            if (Config.hostelID != null) {
              selectedHostelIds.add(Config.hostelID!);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading hostels: $e');
    }
  }

  Future<void> inviteManager() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedHostelIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one property'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final ownerId = prefs.getString('adminID');
      
      final data = {
        'owner_id': ownerId!,
        'name': nameController.text.trim(),
        'email': emailController.text.trim().toLowerCase(),
        'phone': phoneController.text.trim(),
        'password': passwordController.text,
        'hostel_ids': selectedHostelIds.join(','),
      };

      // Add permissions
      permissions.forEach((key, value) {
        data[key] = value ? '1' : '0';
      });

      final response = await inviteManager(data);

      setState(() => loading = false);

      if (response.meta.status == "200" || response.meta.status == "201") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manager invited successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2.0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Add Manager',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildPropertySelectionSection(),
              SizedBox(height: 24),
              _buildPermissionsSection(),
              SizedBox(height: 32),
              _buildActionButtons(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone is required';
                }
                if (value.length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: generatePassword,
                  tooltip: 'Generate new password',
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
            Text(
              'Send this password to the manager via email or SMS',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelectionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select which properties this manager can access',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            if (availableHostels.isEmpty)
              Text(
                'Loading properties...',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...availableHostels.map((hostel) {
                final isSelected = selectedHostelIds.contains(hostel.id);
                return CheckboxListTile(
                  title: Text(hostel.name),
                  subtitle: hostel.address != null ? Text(hostel.address!) : null,
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedHostelIds.add(hostel.id);
                      } else {
                        selectedHostelIds.remove(hostel.id);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select what actions this manager can perform',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildPermissionTile(
              'can_view_dashboard',
              'View Dashboard',
              'Access to analytics and statistics',
              Icons.dashboard,
            ),
            _buildPermissionTile(
              'can_manage_rooms',
              'Manage Rooms',
              'Add, edit, and delete rooms',
              Icons.meeting_room,
            ),
            _buildPermissionTile(
              'can_manage_tenants',
              'Manage Tenants',
              'Add, edit, and manage tenant information',
              Icons.people,
            ),
            _buildPermissionTile(
              'can_manage_bills',
              'Manage Bills',
              'Create and manage tenant bills',
              Icons.receipt,
            ),
            _buildPermissionTile(
              'can_view_financials',
              'View Financials',
              'Access financial reports and revenue data',
              Icons.attach_money,
            ),
            _buildPermissionTile(
              'can_manage_employees',
              'Manage Employees',
              'Add and manage staff members',
              Icons.badge,
            ),
            _buildPermissionTile(
              'can_view_reports',
              'View Reports',
              'Generate and view detailed reports',
              Icons.assessment,
            ),
            _buildPermissionTile(
              'can_manage_notices',
              'Manage Notices',
              'Post and manage notices for tenants',
              Icons.announcement,
            ),
            _buildPermissionTile(
              'can_manage_issues',
              'Manage Issues',
              'View and resolve tenant complaints',
              Icons.support_agent,
            ),
            _buildPermissionTile(
              'can_manage_payments',
              'Manage Payments',
              'Process and track payments',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    String key,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return CheckboxListTile(
      secondary: Icon(icon, color: permissions[key]! ? Colors.blue : Colors.grey),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12),
      ),
      value: permissions[key],
      onChanged: (value) {
        setState(() {
          permissions[key] = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
            onPressed: inviteManager,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Invite Manager'),
            ),
          ),
        ),
      ],
    );
  }
}

