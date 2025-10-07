import 'package:flutter/material.dart';

class BillsScreen extends StatefulWidget {
  @override
  _BillsScreenState createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.purple),
            SizedBox(height: 20),
            Text(
              'Bills Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Track expenses, manage bills, and view payment history',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add bill functionality
              },
              icon: Icon(Icons.add),
              label: Text('Add New Bill'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add bill
        },
        child: Icon(Icons.add),
        tooltip: 'Add Bill',
      ),
    );
  }
}

