import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/models.dart';
import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/utils.dart';

class NoticesActivity extends StatefulWidget {
  @override
  NoticesActivityState createState() {
    return new NoticesActivityState();
  }
}

class NoticesActivityState extends State<NoticesActivity> {
  bool checked = false;
  Map<String, String> filter = new Map();

  List<Notice> notices = <Notice>[];
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
        Future<Notices> data = getNotices(filter);
        data.then((response) {
          if (response.notices.length > 0) {
            offset = (int.parse(response.pagination.offset) +
                    response.notices.length)
                .toString();
            response.notices.forEach((notice) {
              notices.add(notice);
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

    notices.clear();
    fillData();
  }

  @override
  Widget build(BuildContext context) {
    return new ModalProgressHUD(
      child: notices.length == 0
          ? new Center(
              child: new Text(loading ? "" : "No notices"),
            )
          : new ListView.separated(
              controller: _controller,
              itemCount: notices.length,
              separatorBuilder: (context, index) {
                return Divider(
                  height: 40,
                );
              },
              itemBuilder: (context, i) {
                return new Container(
                  padding: new EdgeInsets.fromLTRB(10, i == 0 ? 10 : 0, 10, 0),
                  child: new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Text(
                              notices[i].title,
                            ),
                          ),
                          new Container(
                            width: 10,
                          ),
                          new Text(
                            headingDateFormat.format(
                                DateTime.parse(notices[i].createdDateTime)),
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          )
                        ],
                      ),
                      new Container(
                        height: 10,
                      ),
                      new Image.network(notices[i].img)
                    ],
                  ),
                );
              },
            ),
      inAsyncCall: loading,
    );
  }
}
