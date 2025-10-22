import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Production screens
import './screens/login.dart';
import './screens/dashboard.dart';
import './utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSharedPreference();
  runApp(CloudPGProductionApp());
}

class CloudPGProductionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudPG - PG/Hostel Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginActivity(),
      debugShowCheckedModeBanner: false,
    );
  }
}

