import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/models.dart';
import '../utils/config.dart';
import '../utils/utils.dart';
import '../utils/permission_service.dart';
import './manager_add.dart';
import './manager_permissions.dart';

/// Manager List Screen - Display and manage all managers
/// Only accessible to owners
class ManagersActivity extends StatefulWidget {
  @override
  ManagersActivityState createState() => ManagersActivityState();
}

class ManagersActivityState extends State<ManagersActivity> {
  List<Manager> managers = [];
  bool loading = true;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    
    // Check if user is owner
    if (!PermissionService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Access Denied'),
            content: Text('Only property owners can access Manager Management.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      });
      return;
    }

    ownerId = prefs.getString('adminID');
    loadManagers();
  }

  Future<void> loadManagers() async {
    if (ownerId == null) return;

    setState(() => loading = true);

    try {
      final response = await getManagers({'owner_id': ownerId!});

      if (response.meta.status == "200") {
        setState(() {
          managers = response.managers;
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
        oneButtonDialog(context, "Error", "Failed to load managers: $e", true);
      }
    }
  }

  Future<void> confirmRemoveManager(Manager manager) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Manager'),
        content: Text(
          'Are you sure you want to remove ${manager.name}? This will revoke all their access permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      removeManager(manager);
    }
  }

  Future<void> removeManager(Manager manager) async {
    setState(() => loading = true);

    try {
      final response = await removeManager({
        'owner_id': ownerId!,
        'manager_id': manager.id,
      });

      if (response.meta.status == "200") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manager removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        loadManagers(); // Refresh list
      } else {
        setState(() => loading = false);
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

  void navigateToAddManager() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManagerAddActivity()),
    );

    if (result == true) {
      loadManagers(); // Refresh list after adding
    }
  }

  void navigateToEditPermissions(Manager manager) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerPermissionsActivity(manager: manager),
      ),
    );

    if (result == true) {
      loadManagers(); // Refresh list after editing
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
          'Managers',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: navigateToAddManager,
            tooltip: 'Add Manager',
          ),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: managers.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: loadManagers,
                child: ListView.builder(
                  itemCount: managers.length,
                  padding: EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    return _buildManagerCard(managers[index]);
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: navigateToAddManager,
        icon: Icon(Icons.person_add),
        label: Text('Add Manager'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Managers Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add managers to help you manage your properties',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: navigateToAddManager,
            icon: Icon(Icons.person_add),
            label: Text('Add First Manager'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(Manager manager) {
    final isActive = manager.status == '1';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive ? Colors.blue : Colors.grey,
                  child: Text(
                    manager.name.isNotEmpty ? manager.name[0].toUpperCase() : 'M',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              manager.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.green[900] : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        manager.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (manager.phone != null && manager.phone!.isNotEmpty)
                        Text(
                          manager.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      navigateToEditPermissions(manager);
                    } else if (value == 'remove') {
                      confirmRemoveManager(manager);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Permissions'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (manager.properties.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Assigned Properties:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: manager.properties.map((property) {
                  return Chip(
                    label: Text(
                      property.name,
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue[50],
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (manager.createdAt != null) ...[
              SizedBox(height: 8),
              Text(
                'Added: ${manager.createdAt}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

