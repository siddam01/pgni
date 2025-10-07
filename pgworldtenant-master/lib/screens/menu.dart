import 'package:flutter/material.dart';

class MenuActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MenuActivityState();
  }
}

class MenuActivityState extends State<MenuActivity> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("Meal Menu", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange[700],
          tabs: [
            Tab(icon: Icon(Icons.wb_sunny), text: "Today"),
            Tab(icon: Icon(Icons.calendar_today), text: "Weekly"),
            Tab(icon: Icon(Icons.access_time), text: "Timings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayMenu(),
          _buildWeeklyMenu(),
          _buildMealTimings(),
        ],
      ),
    );
  }

  Widget _buildTodayMenu() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealCard("Breakfast", "7:00 AM - 9:00 AM", [
            "Idli - Sambar - Chutney",
            "Poha",
            "Bread - Butter - Jam",
            "Tea - Coffee - Milk",
          ], Icons.free_breakfast, Colors.orange),
          
          _buildMealCard("Lunch", "12:00 PM - 2:00 PM", [
            "Rice - Dal - Roti",
            "Seasonal Vegetable",
            "Curd",
            "Salad - Pickle",
          ], Icons.lunch_dining, Colors.green),
          
          _buildMealCard("Dinner", "7:00 PM - 9:00 PM", [
            "Roti - Dal",
            "Paneer Curry",
            "Rice",
            "Salad",
          ], Icons.dinner_dining, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildWeeklyMenu() {
    return Center(
      child: Text("Weekly menu view - Coming soon"),
    );
  }

  Widget _buildMealTimings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimingCard("Breakfast", "7:00 AM - 9:00 AM", Icons.free_breakfast, Colors.orange),
          _buildTimingCard("Lunch", "12:00 PM - 2:00 PM", Icons.lunch_dining, Colors.green),
          _buildTimingCard("Snacks", "4:00 PM - 5:00 PM", Icons.coffee, Colors.brown),
          _buildTimingCard("Dinner", "7:00 PM - 9:00 PM", Icons.dinner_dining, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, String time, List<String> items, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
            Divider(height: 24),
            ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  SizedBox(width: 8),
                  Text(item),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard(String meal, String time, IconData icon, Color color) {
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
        title: Text(meal, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
      ),
    );
  }
}

