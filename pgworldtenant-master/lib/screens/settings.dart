import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../utils/api.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'dart:io' show Platform;

import '../utils/utils.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import './login.dart';
import './support.dart';
import './profile.dart';
import './room.dart';
import './food.dart';

class SettingsActivity extends StatefulWidget {
  SettingsActivity();
  @override
  State<StatefulWidget> createState() {
    return new SettingsActivityState();
  }
}

class SettingsActivityState extends State<SettingsActivity> {
  bool wifi = false;
  bool bathroom = false;
  bool tv = false;
  bool ac = false;

  String? selectedHostelID;
  String? hostelIDs;
  Hostels? hostels;

  List<Widget> hostelWidgets = <Widget>[];

  String? expiry;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    hostelIDs = prefs.getString('hostelIDs');
    selectedHostelID = prefs.getString('hostelID');

    getHostelsData();
  }

  void getHostelsData() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loading = false;
        });
      } else {
        Future<Hostels> request =
            getHostels(Map.from({'id': selectedHostelID, 'status': '1'}));
        request.then((response) {
          setState(() {
            hostels = response;
            hostels.hostels.forEach((hostel) {
              if (hostel.id == selectedHostelID) {
                expiry = headingDateFormat
                    .format(DateTime.parse(hostel.expiryDateTime));
              }
            });
            loading = false;
          });
        });
      }
    });
  }

  void logout() {
    prefs.clear();
    Navigator.pop(context);
    Navigator.of(context).pushReplacement(
        new MaterialPageRoute(builder: (BuildContext context) => new Login()));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, "");
            }),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: new Text(
          "Settings",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 4.0,
      ),
      body: ModalProgressHUD(
        child: loading
            ? new Container()
            : new Container(
                margin: new EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width * 0.1,
                    25,
                    MediaQuery.of(context).size.width * 0.1,
                    0),
                child: new ListView(
                  children: <Widget>[
                    new Container(
                      margin: new EdgeInsets.fromLTRB(0, 0, 0, 15),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          new Container(
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: new Text("Name"),
                          ),
                          new Expanded(
                            child: new Container(
                              margin: new EdgeInsets.fromLTRB(15, 0, 0, 0),
                              child: new Text(
                                name.toUpperCase(),
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    hostels != null
                        ? new Row(
                            children: <Widget>[
                              new Container(
                                padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
                                child: new Text("HOSTEL"),
                              ),
                              new Expanded(
                                child: new DropdownButton(
                                  isExpanded: true,
                                  items: hostels.hostels.map((hostel) {
                                    return new DropdownMenuItem(
                                        child: new Container(
                                          constraints:
                                              BoxConstraints(maxWidth: 200),
                                          child: new Text(
                                            hostel.name + " " + hostel.address,
                                            overflow: TextOverflow.clip,
                                          ),
                                        ),
                                        value: hostel.id);
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedHostelID = value;
                                      prefs.setString('hostelID', value);
                                      hostelID = value;
                                      hostels.hostels.forEach((hostel) {
                                        if (hostel.id == value) {
                                          amenities =
                                              hostel.amenities.split(",");
                                          expiry = headingDateFormat.format(
                                              DateTime.parse(
                                                  hostel.expiryDateTime));
                                        }
                                      });
                                    });
                                  },
                                  value: selectedHostelID,
                                ),
                              )
                            ],
                          )
                        : new Text(""),
                    new Container(
                      height: 30,
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => new ProfileActivity()));
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Icon(Icons.person),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("My Profile"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => new RoomActivity()));
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Icon(Icons.meeting_room),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("My Room"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => new FoodActivity()));
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Icon(Icons.restaurant),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Food Management"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    new SupportActivity(true)));
                        // launchURL(
                        //     "upi://pay?pa=dravid.rahul1526@okicici&pn=Rahul&tn=test&am=100&cu=INR");
                        // sendMail(
                        //     supportMail,
                        //     "Feedback%20and%20Support",
                        //     "User - " +
                        //         adminName +
                        //         "\nHostel ID - " +
                        //         hostelID +
                        //         "\nOS - " +
                        //         (Platform.isAndroid ? "Android" : "iOS") +
                        //         "\nApp Version - " +
                        //         (Platform.isAndroid
                        //             ? APPVERSION.ANDROID
                        //             : APPVERSION.IOS));
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Icon(Icons.chat),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Feedback & Support"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        if (Platform.isAndroid) {
                          // launchURL(
                          //     "https://play.google.com/store/apps/details?id=com.saikrishna.cloudpg");
                        } else {}
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            new Icon(Icons.star),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Rate Us"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        // launchURL("http://cloudpg.in/terms");
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            new Icon(Icons.featured_play_list),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Terms of Use"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        // launchURL("http://cloudpg.in/privacy");
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            new Icon(Icons.vpn_key),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Privacy Policy"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    new GestureDetector(
                      onTap: () {
                        // launchURL("http://cloudpg.in/about");
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            new Icon(Icons.info),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("About"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Divider(),
                    TextButton(
                      child: new Text(
                        "Log Out",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        logout();
                      },
                    ),
                    new Center(
                      child: new Text(
                        "\n\nMade with :) in Hyderabad, India\nCopyright © 2019 Cloud PG\n\n" +
                            (Platform.isAndroid
                                ? APPVERSION.ANDROID
                                : APPVERSION.IOS),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
        inAsyncCall: loading,
      ),
    );
  }
}
