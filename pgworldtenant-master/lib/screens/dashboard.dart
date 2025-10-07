import 'package:flutter/material.dart';
import '../utils/api.dart';
import '../utils/models.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import './settings.dart';
import '../utils/utils.dart';
import '../utils/config.dart';
import './issues.dart';
import './notices.dart';
import './rents.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DashBoardState();
  }
}

class DashBoardState extends State<DashBoard> {
  FocusNode textSecondFocusNode = FocusNode();

  Dashboard? dashboard;
  List<Graph>? graphs;

  String hostelId = "";

  List<Widget> widgets = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();

    hostelId = hostelID;

    fillData();
  }

  Future<void> fillData() async {
    widgets.clear();
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
      } else {
        Map<String, String> filter = new Map();
        filter["hostel_id"] = hostelID;
        filter["user_id"] = userID;
        filter["status"] = "1";
        Future<Bills> data = getBills(filter);
        data.then((response) {
          if (response.bills.length > 0) {
            //
          }
          if (response.meta.messageType == "1") {
            oneButtonDialog(context, "", response.meta.message,
                !(response.meta.status == STATUS_403));
          }
        });
      }
    });
    return null;
  }

  filterPage(BuildContext context, Widget page) async {
    final data = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ) as String;
    if (hostelId != hostelID) {
      hostelId = hostelID;
      fillData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: 3,
      child: new Scaffold(
          appBar: new AppBar(
            backgroundColor: Colors.white,
            title: new Text(
              "DashBoard",
              style: TextStyle(color: Colors.black),
            ),
            elevation: 4.0,
            bottom: TabBar(
              tabs: <Widget>[
                new Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: new Text(
                    "Notices",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                new Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: new Text(
                    "Rents",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                new Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: new Text(
                    "Issues",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              new IconButton(
                onPressed: () {
                  filterPage(context, new SettingsActivity());
                },
                icon: new Icon(Icons.settings),
                color: Colors.black,
              ),
            ],
          ),
          body: TabBarView(
            children: <Widget>[
              ModalProgressHUD(
                child: new Container(
                    child: loading ? new Container() : new NoticesActivity()),
                inAsyncCall: loading,
              ),
              ModalProgressHUD(
                child: new Container(
                    child: loading ? new Container() : new BillsActivity()),
                inAsyncCall: loading,
              ),
              ModalProgressHUD(
                child: new Container(
                    child: loading ? new Container() : new IssuesActivity()),
                inAsyncCall: loading,
              ),
            ],
          )),
    );
  }
}
