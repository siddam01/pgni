import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Admin User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'admin@pgworld.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          _buildSettingItem(Icons.person, 'Profile', () {}),
          _buildSettingItem(Icons.home, 'My Hostels', () {}),
          _buildSettingItem(Icons.notifications, 'Notifications', () {}),
          _buildSettingItem(Icons.payment, 'Payment Settings', () {}),
          _buildSettingItem(Icons.security, 'Privacy & Security', () {}),
          _buildSettingItem(Icons.help, 'Help & Support', () {}),
          _buildSettingItem(Icons.info, 'About', () {}),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement logout
            },
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

