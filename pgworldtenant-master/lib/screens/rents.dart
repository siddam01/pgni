import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/models.dart';
import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/utils.dart';
import './photo.dart';

class BillsActivity extends StatefulWidget {
  @override
  BillsActivityState createState() {
    return new BillsActivityState();
  }
}

class BillsActivityState extends State<BillsActivity> {
  bool checked = false;
  Map<String, String> filter = new Map();

  List<Bill> bills = <Bill>[];
  bool end = false;
  bool ongoing = false;

  String offset = defaultOffset;
  bool loading = true;

  ScrollController? _controller;

  double width = 0;

  @override
  void initState() {
    super.initState();
    filter["status"] = "1";
    filter["user_id"] = userID;
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
        Future<Bills> data = getBills(filter);
        data.then((response) {
          if (response.bills.length > 0) {
            offset =
                (int.parse(response.pagination.offset) + response.bills.length)
                    .toString();
            response.bills.forEach((bill) {
              bills.add(bill);
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

    bills.clear();
    fillData();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    return new ModalProgressHUD(
      child: bills.length == 0
          ? new Center(
              child: new Text(loading ? "" : "No Rents"),
            )
          : new ListView.separated(
              controller: _controller,
              itemCount: bills.length,
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemBuilder: (context, i) {
                return new ListTile(
                  dense: true,
                  onTap: () {
                    if (bills[i].document.length > 0) {
                      var docs = "";
                      bills[i].document.split(",").forEach((doc) {
                        if (doc.length > 0) {
                          docs = doc;
                        }
                      });
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) =>
                                new PhotoActivity(mediaURL + docs)),
                      );
                    }
                  },
                  title: new Container(
                    padding: new EdgeInsets.only(top: i == 0 ? 10 : 0),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new Expanded(
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(
                                    bills[i].title,
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                  new Text(
                                    (bills[i].paid == "0" ? "" : "- ") +
                                        "₹" +
                                        bills[i].amount,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                      color: bills[i].paid == "0"
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              bills[i].description.length > 0
                                  ? new Container(
                                      width: width * 0.7,
                                      child: new Text(
                                        // bills[i].description +
                                        //     " on " +
                                        headingDateFormat.format(DateTime.parse(
                                            bills[i].paidDateTime)),
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w100,
                                            color: Colors.grey),
                                      ),
                                    )
                                  : new Container(),
                            ],
                          ),
                        ),
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
