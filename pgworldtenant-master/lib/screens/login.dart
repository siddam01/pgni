import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import './dashboard.dart';
import '../utils/models.dart';
import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/utils.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  FocusNode textSecondFocusNode = FocusNode();

  TextEditingController phone = TextEditingController();
  TextEditingController otp = TextEditingController();

  bool loggedIn = true;
  bool wrongCreds = false;

  bool otpsent = false;

  String onesignalUserId = "";
  String verificationId = "";

  @override
  void initState() {
    super.initState();

    // Updated OneSignal initialization
    onesignalUserId = OneSignal.User.pushSubscription.id ?? "";

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
          setState(() {
            loggedIn = false;
          });
        }
      } else {
        setState(() {
          loggedIn = false;
        });
      }
    });
  }

  void sendOTPFunc() {
    if (phone.text.length != 10) {
      oneButtonDialog(context, "", "Enter 10 digit mobile number", true);
      return;
    }
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loggedIn = false;
        });
      } else {
        setState(() {
          loggedIn = true;
        });
        Future<Meta> employeeResponse = sendOTP(Map.from({
          'phone': phone.text,
        }));
        employeeResponse.then((meta) {
          if (meta.status == "200") {
            setState(() {
              otpsent = true;
            });
          }
          setState(() {
            loggedIn = false;
          });
          if (meta.messageType == "1") {
            oneButtonDialog(
                context, "", meta.message, !(meta.status == STATUS_403));
          }
        });
      }
    });
  }

  void verifyOTPFunc() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loggedIn = false;
        });
      } else {
        setState(() {
          loggedIn = true;
        });
        Future<Meta> employeeResponse = verifyOTP(Map.from({
          'phone': phone.text,
          'otp': otp.text,
          'oneSignalID': onesignalUserId,
        }));
        employeeResponse.then((meta) {
          if (meta.status == "200") {
            setState(() {
              otpsent = true;
            });
            login();
          }
          setState(() {
            loggedIn = false;
          });
          if (meta.messageType == "1") {
            oneButtonDialog(
                context, "", meta.message, !(meta.status == STATUS_403));
          }
        });
      }
    });
  }

  void login() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loggedIn = false;
        });
      } else {
        setState(() {
          loggedIn = true;
        });
        Future<Users> employeeResponse = getUsers(Map.from({
          'phone': phone.text,
          'oneSignalID': onesignalUserId,
        }));
        employeeResponse.then((response) {
          if (response.meta.status != "200") {
            setState(() {
              loggedIn = false;
            });
          } else {
            if (response.users.length == 0) {
              setState(() {
                loggedIn = false;
                wrongCreds = true;
              });
            } else {
              prefs.setString('name', response.users[0].name);
              prefs.setString('emailID', response.users[0].email);
              prefs.setString('hostelID', response.users[0].hostelID);
              prefs.setString('userID', response.users[0].id);
              name = response.users[0].name;
              emailID = response.users[0].email;
              hostelID = response.users[0].hostelID;
              userID = response.users[0].id;

              Navigator.of(context).pushReplacement(new MaterialPageRoute(
                  builder: (BuildContext context) => new DashBoard()));
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // appBar: new AppBar(
      //   iconTheme: IconThemeData(
      //     color: Colors.black,
      //   ),
      //   backgroundColor: Colors.white,
      //   title: new Text(
      //     "Log in",
      //     style: TextStyle(color: Colors.black),
      //   ),
      //   elevation: 4.0,
      // ),
      body: ModalProgressHUD(
        child: new Container(
          margin: new EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.1,
              100,
              MediaQuery.of(context).size.width * 0.1,
              0),
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              new SizedBox(
                width: 100,
                height: 100,
                child: new Image.asset('assets/appicon.png'),
              ),
              new Center(
                child: new Container(
                  margin: EdgeInsets.only(top: 10),
                  child: new Text("Cloud PG"),
                ),
              ),
              new Container(
                height: 50,
              ),
              new TextField(
                enabled: !otpsent,
                controller: phone,
                autocorrect: false,
                autofocus: true,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                onSubmitted: (String value) {
                  sendOTPFunc();
                },
              ),
              otpsent
                  ? new Container(
                      margin: new EdgeInsets.fromLTRB(0, 15, 0, 0),
                      child: new TextField(
                        controller: otp,
                        focusNode: textSecondFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'OTP',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        onSubmitted: (s) {
                          verifyOTPFunc();
                        },
                      ),
                    )
                  : new Container(),
              otpsent
                  ? new Container()
                  : new Container(
                      margin: new EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: new MaterialButton(
                        color: Colors.blue,
                        height: 40,
                        child: new Text(
                          "Send OTP",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          sendOTPFunc();
                        },
                      ),
                    ),
              otpsent
                  ? new Container(
                      margin: new EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: new MaterialButton(
                        color: Colors.blue,
                        height: 40,
                        child: new Text(
                          "Verify OTP",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          verifyOTPFunc();
                        },
                      ),
                    )
                  : new Container(),
              otpsent
                  ? new Container(
                      margin: new EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          new MaterialButton(
                            height: 40,
                            child: new Text(
                              "Resend OTP",
                            ),
                            onPressed: () {
                              sendOTPFunc();
                            },
                          ),
                          new MaterialButton(
                            height: 40,
                            child: new Text(
                              "Use different Phone",
                            ),
                            onPressed: () {
                              setState(() {
                                otpsent = false;
                              });
                            },
                          )
                        ],
                      ),
                    )
                  : new Container(),
              new Container(
                  margin: new EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: new Center(
                    child: new Text(
                      wrongCreds ? "You are not tagged to any PG" : "",
                      style: new TextStyle(color: Colors.red),
                    ),
                  )),
            ],
          ),
        ),
        inAsyncCall: loggedIn,
      ),
    );
  }
}
