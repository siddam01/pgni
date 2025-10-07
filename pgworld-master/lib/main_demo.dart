import 'package:flutter/material.dart';

void main() {
  runApp(CloudPGApp());
}

class CloudPGApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudPG - PG/Hostel Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardHome(),
    RoomsScreen(),
    TenantsScreen(),
    BillsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CloudPG Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Tenants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Rooms',
                  '45',
                  Icons.hotel,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Occupied',
                  '38',
                  Icons.person,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available',
                  '7',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  '₹1,25,000',
                  Icons.currency_rupee,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Recent Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        _buildActivityItem('New tenant registered - Room 205', '2 hours ago'),
        _buildActivityItem('Rent payment received - Room 101', '4 hours ago'),
        _buildActivityItem('Maintenance request - Room 308', '6 hours ago'),
        _buildActivityItem('Bill generated for electricity', '1 day ago'),
      ],
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.notifications, color: Colors.blue[700]),
        ),
        title: Text(activity),
        subtitle: Text(time),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class RoomsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search rooms...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.filter_list),
                  label: Text('Filter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return _buildRoomCard(index + 1);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
        tooltip: 'Add Room',
      ),
    );
  }

  Widget _buildRoomCard(int roomNumber) {
    bool isOccupied = roomNumber % 3 != 0; // Mock data
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOccupied ? Colors.red[100] : Colors.green[100],
          child: Text(
            roomNumber.toString().padLeft(3, '0'),
            style: TextStyle(
              color: isOccupied ? Colors.red[700] : Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('Room $roomNumber'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isOccupied ? 'Occupied by John Doe' : 'Available'),
            Text('Rent: ₹8,000/month • AC, WiFi, TV'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOccupied ? Icons.person : Icons.check_circle,
              color: isOccupied ? Colors.red : Colors.green,
            ),
            Text(
              isOccupied ? 'Occupied' : 'Available',
              style: TextStyle(
                fontSize: 12,
                color: isOccupied ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class TenantsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tenants...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 15,
              itemBuilder: (context, index) {
                return _buildTenantCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(int index) {
    final names = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Wilson', 'David Brown'];
    final rooms = [101, 102, 205, 308, 412];
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            names[index % names.length][0],
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(names[index % names.length]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room ${rooms[index % rooms.length]}'),
            Text('Phone: +91 98765 43210'),
            Text('Move-in: 15 Jan 2024'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(height: 4),
            Icon(Icons.email, color: Colors.blue),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class BillsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Bill Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['All', 'Electricity', 'Water', 'Rent', 'Maintenance']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add),
                  label: Text('New Bill'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildBillCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(int index) {
    final billTypes = ['Electricity', 'Water', 'Rent', 'Maintenance'];
    final amounts = [2500, 800, 8000, 1200];
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Icon(
            Icons.receipt,
            color: Colors.orange[700],
          ),
        ),
        title: Text('${billTypes[index % billTypes.length]} Bill'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${amounts[index % amounts.length]}'),
            Text('Due Date: ${15 + index} Mar 2024'),
            Text('Status: ${index % 2 == 0 ? 'Paid' : 'Pending'}'),
          ],
        ),
        trailing: Icon(
          index % 2 == 0 ? Icons.check_circle : Icons.pending,
          color: index % 2 == 0 ? Colors.green : Colors.orange,
        ),
        onTap: () {},
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Monthly Revenue',
                  '₹3,45,000',
                  '+12%',
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  'Monthly Expenses',
                  '₹85,000',
                  '+5%',
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Net Profit',
                  '₹2,60,000',
                  '+15%',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildReportCard(
                  'Occupancy Rate',
                  '84.4%',
                  '+2%',
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard('Generate Report', Icons.assessment, Colors.blue),
              _buildActionCard('Export Data', Icons.download, Colors.green),
              _buildActionCard('Send Notices', Icons.notifications, Colors.orange),
              _buildActionCard('Backup Data', Icons.backup, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, String change, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
