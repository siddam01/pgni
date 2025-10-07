import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import './screens/login.dart';
import './utils/config.dart';
import './utils/utils.dart';
import './screens/dashboard.dart';

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  runApp(MaterialApp(
    title: "CloudPG",
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudPG',
      home: MyHomePage(title: 'CloudPG'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // Initialize OneSignal
    OneSignal.initialize(ONESIGNAL_APP_ID);
    OneSignal.Notifications.requestPermission(true);

    Future.delayed(const Duration(seconds: 3), () {
      loginCheck();
    });
  }

  void loginCheck() {
    if (Platform.isAndroid) {
      headers["appversion"] = APPVERSION.ANDROID;
      if (kReleaseMode) {
        headers["apikey"] = APIKEY.ANDROID_LIVE;
      } else {
        headers["apikey"] = APIKEY.ANDROID_TEST;
      }
    } else {
      headers["appversion"] = APPVERSION.IOS;
      if (kReleaseMode) {
        headers["apikey"] = APIKEY.IOS_LIVE;
      } else {
        headers["apikey"] = APIKEY.IOS_TEST;
      }
    }
    Future<bool> prefInit = initSharedPreference();
    prefInit.then((onValue) {
      if (onValue) {
        final storedName = prefs.getString("name");
        if (storedName != null && storedName.isNotEmpty) {
          name = storedName;
          emailID = prefs.getString("emailID") ?? "";
          hostelID = prefs.getString("hostelID") ?? "";
          userID = prefs.getString("userID") ?? "";
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const DashBoard()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const Login()));
        }
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const Login()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        color: HexColor("#5099CF"),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const SizedBox(
                width: 200,
                height: 200,
                child: Image(image: AssetImage('assets/appicon.png')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
