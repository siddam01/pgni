import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              'Reports & Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View detailed reports, analytics, and insights',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.calendar_month),
                  label: Text('Monthly Report'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.attach_money),
                  label: Text('Revenue Report'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.people),
                  label: Text('Occupancy Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

