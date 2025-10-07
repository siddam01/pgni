import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/models.dart';
import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/utils.dart';

class IssuesActivity extends StatefulWidget {
  @override
  IssuesActivityState createState() {
    return new IssuesActivityState();
  }
}

class IssuesActivityState extends State<IssuesActivity> {
  bool checked = false;
  Map<String, String> filter = new Map();

  List<Issue> issues = <Issue>[];
  bool end = false;
  bool ongoing = false;

  String offset = defaultOffset;
  bool loading = true;

  ScrollController? _controller;

  @override
  void initState() {
    super.initState();
    filter["status"] = "1";
    filter["hostel_id"] = hostelID;
    filter["limit"] = defaultLimit;
    filter["offset"] = offset;
    filter["orderby"] = "created_date_time";
    filter["sortby"] = "desc";

    _controller = ScrollController();
    _controller!.addListener(_scrollListener);
    fillData();
  }

  _scrollListener() {
    if (_controller!.offset >= _controller!.position.maxScrollExtent &&
        !_controller!.position.outOfRange) {
      if (!end && !ongoing) {
        setState(() {
          loading = true;
        });
        fillData();
      }
    }
  }

  void fillData() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          ongoing = false;
          loading = false;
        });
      } else {
        ongoing = true;
        filter["offset"] = offset;
        Future<Issues> data = getIssues(filter);
        data.then((response) {
          if (response.issues.length > 0) {
            offset =
                (int.parse(response.pagination.offset) + response.issues.length)
                    .toString();
            response.issues.forEach((issue) {
              issues.add(issue);
            });
          } else {
            end = true;
          }
          if (response.meta.messageType == "1") {
            oneButtonDialog(context, "", response.meta.message,
                !(response.meta.status == STATUS_403));
          }
          setState(() {
            ongoing = false;
            loading = false;
          });
        });
      }
    });
  }

  addPage(BuildContext context, Widget page) async {
    final data = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ) as String;

    filter["status"] = "1";
    filter["hostel_id"] = hostelID;
    filter["limit"] = defaultLimit;
    filter["offset"] = offset;
    filter["orderby"] = "created_date_time";
    filter["sortby"] = "desc";
    offset = defaultOffset;

    issues.clear();
    fillData();
  }

  @override
  Widget build(BuildContext context) {
    return new ModalProgressHUD(
      child: issues.length == 0
          ? new Center(
              child: new Text(loading ? "" : "No issues"),
            )
          : new ListView.separated(
              controller: _controller,
              itemCount: issues.length,
              separatorBuilder: (context, index) {
                return Container();
              },
              itemBuilder: (context, i) {
                return new ListTile(
                  title: new Container(
                    margin: new EdgeInsets.all(0),
                    child: new Row(
                      children: <Widget>[
                        new Flexible(
                          child: new Text(
                            issues[i].title,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w100,
                                color: issues[i].status == "0"
                                    ? Colors.grey
                                    : Colors.black,
                                decoration: issues[i].status == "0"
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      inAsyncCall: loading,
    );
  }
}
