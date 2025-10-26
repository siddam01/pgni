import 'dart:io' show Platform;
import 'package:cloudpg/screens/hostels.dart';
import 'package:cloudpg/screens/invoices.dart';
import 'package:flutter/material.dart';
import '../utils/api.dart';

import 'package:modal_progress_hud/modal_progress_hud.dart';

import '../utils/utils.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/permission_service.dart';
import './login.dart';
import './support.dart';
import './managers.dart';

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

  String selectedHostelID;
  String hostelIDs;
  Hostels hostels;

  List<Widget> hostelWidgets = new List();

  String expiry;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    selectedHostelID = prefs.getString('hostelID');

    getUserData();
  }

  void getUserData() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        return;
      } else {
        setState(() {
          loading = true;
        });
        Future<Admins> adminResponse = getAdmins(Map.from({
          'username': adminName,
          'email': adminEmailID,
        }));
        adminResponse.then((response) {
          if (response.meta.status != "200") {
            setState(() {
              loading = false;
            });
          } else {
            if (response.admins.length == 0) {
              setState(() {
                loading = false;
              });
            } else {
              prefs.setString('username', response.admins[0].username);
              prefs.setString('email', response.admins[0].email);
              prefs.setString('hostelIDs', response.admins[0].hostels);
              hostelIDs = prefs.getString('hostelIDs');
              adminName = response.admins[0].username;
              adminEmailID = response.admins[0].email;
              Future<Hostels> hostelResponse =
                  getHostels(Map.from({'id': hostelID, 'status': '1'}));
              hostelResponse.then((response) {
                setState(() {
                  if (response.hostels.length > 0) {
                    prefs.setString('hostelID', response.hostels[0].id);
                    prefs.setString('hostelName', response.hostels[0].name);
                    prefs.setString('amenities', response.hostels[0].amenities);
                    hostelID = response.hostels[0].id;
                    hostelName = response.hostels[0].name;
                    amenities = response.hostels[0].amenities.split(",");
                    getHostelsData();
                  } else {
                    loading = false;
                  }
                });
              });
            }
          }
        });
      }
    });
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
            getHostels(Map.from({'id': hostelIDs, 'status': '1'}));
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

  hostelsPage(BuildContext context, Widget page) async {
    final data = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ) as String;

    getUserData();
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
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: new Text(
                        "ACCOUNT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ),
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
                                prefs.getString('username') != null
                                    ? prefs.getString('username').toUpperCase()
                                    : "",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    new Row(
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
                                    constraints: BoxConstraints(maxWidth: 200),
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
                                    prefs.setString('hostelName', hostel.name);
                                    hostelName = hostel.name;
                                    amenities = hostel.amenities.split(",");
                                    expiry = headingDateFormat.format(
                                        DateTime.parse(hostel.expiryDateTime));
                                  }
                                });
                              });
                            },
                            value: selectedHostelID,
                          ),
                        )
                      ],
                    ),
                    // new Container(
                    //   margin: new EdgeInsets.fromLTRB(0, 15, 0, 0),
                    //   child: new Row(
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     children: <Widget>[
                    //       new Container(
                    //         width: MediaQuery.of(context).size.width * 0.3,
                    //         child: new Text(
                    //           "Subscription Expiry",
                    //         ),
                    //       ),
                    //       new Expanded(
                    //         child: new Container(
                    //           margin: new EdgeInsets.fromLTRB(15, 0, 0, 0),
                    //           child: new Text(expiry != null ? expiry : ""),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    new Container(
                      height: 20,
                    ),
                    prefs.getString("admin") == "1"
                        ? new GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          new InvoicesActivity()));
                            },
                            child: new Container(
                              color: Colors.transparent,
                              height: 30,
                              child: new Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Icon(Icons.receipt),
                                  new Container(
                                    width: 20,
                                  ),
                                  new Expanded(
                                    child: new Text("Subscription Invoices"),
                                  ),
                                  new Icon(
                                    Icons.arrow_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : new Container(),
                    new Container(
                      height: prefs.getString("admin") == "1" ? 20 : 0,
                    ),
                    new GestureDetector(
                      onTap: () {
                        hostelsPage(context, new HostelsActivity());
                      },
                      child: new Container(
                        color: Colors.transparent,
                        height: 30,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Icon(Icons.receipt),
                            new Container(
                              width: 20,
                            ),
                            new Expanded(
                              child: new Text("Hostels"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Container(
                      height: 30,
                    ),
                    // Team Management Section (Owners only)
                    if (PermissionService.isOwner()) ...[
                      new Container(
                        margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                        child: new Text(
                          "TEAM MANAGEMENT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                      new GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManagersActivity(),
                            ),
                          );
                        },
                        child: new Container(
                          color: Colors.transparent,
                          height: 50,
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Icon(Icons.people, color: Colors.blue),
                              new Container(width: 20),
                              new Expanded(
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    new Text(
                                      "Managers",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    new Text(
                                      "Manage your team members",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
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
                      new Container(height: 20),
                    ],
                    new Container(
                      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                      child: new Text(
                        "GET IN TOUCH",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    new GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    new SupportActivity(true)));
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
                          launchURL(
                              "https://play.google.com/store/apps/details?id=com.saikrishna.cloudpg");
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
                    new Container(
                      margin: EdgeInsets.fromLTRB(0, 40, 0, 20),
                      child: new Text(
                        "ABOUT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    new GestureDetector(
                      onTap: () {
                        launchURL(CONTACT.TERMS_URL);
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
                        launchURL(CONTACT.PRIVACY_URL);
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
                        launchURL(CONTACT.ABOUT_URL);
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
                              child: new Text("About Us"),
                            ),
                            new Icon(
                              Icons.arrow_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    new Container(
                      height: 30,
                    ),
                    new FlatButton(
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
                    ),
                    new Container(
                      height: 30,
                    ),
                  ],
                ),
              ),
        inAsyncCall: loading,
      ),
    );
  }
}
