import 'package:flutter/material.dart';

class RoomsScreen extends StatefulWidget {
  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Rooms Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage all rooms, add new rooms, and track occupancy',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add room functionality
              },
              icon: Icon(Icons.add),
              label: Text('Add New Room'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add room
        },
        child: Icon(Icons.add),
        tooltip: 'Add Room',
      ),
    );
  }
}

