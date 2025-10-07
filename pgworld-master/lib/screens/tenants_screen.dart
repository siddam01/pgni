import 'package:flutter/material.dart';

class TenantsScreen extends StatefulWidget {
  @override
  _TenantsScreenState createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Tenants Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage tenants, track payments, and view details',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add tenant functionality
              },
              icon: Icon(Icons.person_add),
              label: Text('Add New Tenant'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add tenant
        },
        child: Icon(Icons.person_add),
        tooltip: 'Add Tenant',
      ),
    );
  }
}

