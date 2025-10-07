import 'package:flutter/material.dart';

class MealHistoryActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MealHistoryActivityState();
  }
}

class MealHistoryActivityState extends State<MealHistoryActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("Meal History", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.history, size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "This Month",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Breakfast", "25", Colors.orange),
                      _buildStatCard("Lunch", "22", Colors.green),
                      _buildStatCard("Dinner", "28", Colors.blue),
                    ],
                  ),
                ],
              ),
            ),

            // History List
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recent Meals",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildHistoryItem("Today", "Breakfast, Lunch, Dinner", "3 meals", Icons.today, Colors.green),
                  _buildHistoryItem("Yesterday", "Breakfast, Dinner", "2 meals", Icons.history, Colors.orange),
                  _buildHistoryItem("Dec 17, 2024", "Breakfast, Lunch, Dinner", "3 meals", Icons.calendar_today, Colors.green),
                  _buildHistoryItem("Dec 16, 2024", "Breakfast, Lunch", "2 meals", Icons.calendar_today, Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String meals, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(meals),
        trailing: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

