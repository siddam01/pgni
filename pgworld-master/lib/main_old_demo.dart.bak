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
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both username and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Demo login - accept any non-empty credentials
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 60),
                
                // Logo and Title
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.business,
                        size: 60,
                        color: Colors.blue[700],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'CloudPG',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'PG/Hostel Management System',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Login Form
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in to continue to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // Username Field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username or Email',
                          prefixIcon: Icon(Icons.person, color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.blue[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Signing In...', style: TextStyle(fontSize: 16)),
                                ],
                              )
                            : Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),

                      SizedBox(height: 16),

                      // Demo Credentials
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🎯 Demo Credentials',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Username: admin\nPassword: admin123',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '(Any credentials will work for demo)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Additional Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Forgot Password?'),
                                  content: Text('Contact your administrator to reset your password.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text('Forgot Password?'),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Create Account'),
                                  content: Text('Contact your administrator to create a new account.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Footer
                Text(
                  '© 2024 CloudPG. All rights reserved.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    SettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Rooms',
    'Tenants',
    'Bills',
    'Reports',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CloudPG - ${_titles[_selectedIndex]}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _showNotifications(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _showNavigationGuide(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Guide Bar
          Container(
            color: Colors.blue[50],
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use bottom navigation to explore: Dashboard → Rooms → Tenants → Bills → Reports → Settings',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _showNavigationGuide(context),
                  child: Text('Guide', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _showPageInfo(context, index);
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showPageInfo(BuildContext context, int index) {
    final pageDescriptions = [
      'Dashboard: Overview of your PG business with key metrics',
      'Rooms: Manage all rooms, check availability, and track occupancy',
      'Tenants: View and manage tenant information and profiles',
      'Bills: Track all bills, payments, and financial records',
      'Reports: Business analytics and financial reports',
      'Settings: App configuration and account settings',
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pageDescriptions[index]),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _showNavigationGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🧭 Navigation Guide'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📱 How to Navigate:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildGuideItem(
                    '1️⃣', 'Dashboard', 'Business overview & key metrics'),
                _buildGuideItem(
                    '2️⃣', 'Rooms', 'Room management & availability'),
                _buildGuideItem(
                    '3️⃣', 'Tenants', 'Tenant profiles & information'),
                _buildGuideItem(
                    '4️⃣', 'Bills', 'Financial tracking & payments'),
                _buildGuideItem(
                    '5️⃣', 'Reports', 'Analytics & business insights'),
                _buildGuideItem(
                    '6️⃣', 'Settings', 'App configuration & preferences'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Tips:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700])),
                      Text('• Tap bottom navigation icons to switch pages'),
                      Text('• Each page shows different management features'),
                      Text('• All data is demo data for visualization'),
                      Text('• UI is fully responsive and interactive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideItem(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🔔 Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem(
                  'New tenant registered - Room 205', '2 hours ago'),
              _buildNotificationItem(
                  'Rent payment received - Room 101', '4 hours ago'),
              _buildNotificationItem(
                  'Maintenance request - Room 308', '6 hours ago'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(String message, String time) {
    return ListTile(
      leading: Icon(Icons.notifications, color: Colors.blue),
      title: Text(message, style: TextStyle(fontSize: 14)),
      subtitle: Text(time, style: TextStyle(fontSize: 12)),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
    final names = [
      'John Doe',
      'Jane Smith',
      'Mike Johnson',
      'Sarah Wilson',
      'David Brown'
    ];
    final rooms = [101, 102, 205, 308, 412];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            names[index % names.length][0],
            style:
                TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
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
                    items:
                        ['All', 'Electricity', 'Water', 'Rent', 'Maintenance']
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
              _buildActionCard(
                  'Generate Report', Icons.assessment, Colors.blue),
              _buildActionCard('Export Data', Icons.download, Colors.green),
              _buildActionCard(
                  'Send Notices', Icons.notifications, Colors.orange),
              _buildActionCard('Backup Data', Icons.backup, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      String title, String value, String change, Color color) {
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

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildSectionHeader('👤 Account Settings'),
            _buildSettingTile(
              icon: Icons.person,
              title: 'Profile Management',
              subtitle: 'Update your profile information',
              onTap: () => _showFeatureDialog(context, 'Profile Management'),
            ),
            _buildSettingTile(
              icon: Icons.security,
              title: 'Security & Privacy',
              subtitle: 'Password, 2FA, and privacy settings',
              onTap: () => _showFeatureDialog(context, 'Security & Privacy'),
            ),
            _buildSectionHeader('🏢 Business Settings'),
            _buildSettingTile(
              icon: Icons.business,
              title: 'PG Information',
              subtitle: 'Update hostel details and policies',
              onTap: () => _showFeatureDialog(context, 'PG Information'),
            ),
            _buildSettingTile(
              icon: Icons.payment,
              title: 'Payment Configuration',
              subtitle: 'Setup payment methods and billing',
              onTap: () => _showFeatureDialog(context, 'Payment Configuration'),
            ),
            _buildSettingTile(
              icon: Icons.email,
              title: 'Notification Settings',
              subtitle: 'Configure alerts and reminders',
              onTap: () => _showFeatureDialog(context, 'Notification Settings'),
            ),
            _buildSectionHeader('📱 App Settings'),
            _buildSettingTile(
              icon: Icons.language,
              title: 'Language & Region',
              subtitle: 'English (India)',
              onTap: () => _showFeatureDialog(context, 'Language & Region'),
            ),
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: 'Theme Settings',
              subtitle: 'Light mode, Dark mode, Auto',
              onTap: () => _showFeatureDialog(context, 'Theme Settings'),
            ),
            _buildSettingTile(
              icon: Icons.backup,
              title: 'Data Backup',
              subtitle: 'Automatic backup to cloud',
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            _buildSectionHeader('📊 Advanced'),
            _buildSettingTile(
              icon: Icons.analytics,
              title: 'Analytics & Reports',
              subtitle: 'Configure reporting preferences',
              onTap: () => _showFeatureDialog(context, 'Analytics & Reports'),
            ),
            _buildSettingTile(
              icon: Icons.api,
              title: 'API Integration',
              subtitle: 'Third-party service connections',
              onTap: () => _showFeatureDialog(context, 'API Integration'),
            ),
            _buildSettingTile(
              icon: Icons.storage,
              title: 'Data Management',
              subtitle: 'Import/Export data, cleanup tools',
              onTap: () => _showFeatureDialog(context, 'Data Management'),
            ),
            _buildSectionHeader('ℹ️ Information'),
            _buildSettingTile(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'FAQs, tutorials, and contact support',
              onTap: () => _showHelpDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.info,
              title: 'About CloudPG',
              subtitle: 'Version 1.0.0 - Build 2024.12',
              onTap: () => _showAboutDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Logout from your account',
              textColor: Colors.red,
              onTap: () => _showLogoutDialog(context),
            ),
            SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud, size: 32, color: Colors.blue[700]),
                        SizedBox(height: 8),
                        Text(
                          'CloudPG Management System',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'Complete PG/Hostel Management Solution',
                          style:
                              TextStyle(fontSize: 12, color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700]),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('⚙️ $feature'),
          content: Text(
              'This feature allows you to configure $feature settings. In a production app, this would open detailed configuration options.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🆘 Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📧 Email: support@cloudpg.com'),
              SizedBox(height: 8),
              Text('📞 Phone: +91-9876543210'),
              SizedBox(height: 8),
              Text('🌐 Website: www.cloudpg.com'),
              SizedBox(height: 16),
              Text('💬 Live Chat: Available 24/7'),
              Text('📖 Documentation: Complete user guides'),
              Text('🎥 Video Tutorials: Step-by-step walkthroughs'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ℹ️ About CloudPG'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CloudPG Management System',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              Text('Build: 2024.12.19'),
              Text('Platform: Flutter Web/Mobile'),
              SizedBox(height: 16),
              Text('Complete solution for:'),
              Text('• Room & Tenant Management'),
              Text('• Billing & Payment Tracking'),
              Text('• Business Analytics'),
              Text('• Communication Tools'),
              SizedBox(height: 16),
              Text('Developed with ❤️ for PG owners'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🚪 Sign Out'),
          content: Text('Are you sure you want to sign out of your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Signed out successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
