import 'package:flutter/material.dart';
import 'dart:async';

import 'package:modal_progress_hud/modal_progress_hud.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';
import '../screens/dashboard.dart';

class HostelActivity extends StatefulWidget {
  final Hostel hostel;
  final bool startup;
  final bool only;

  HostelActivity(this.hostel, this.startup, this.only);
  @override
  State<StatefulWidget> createState() {
    return new HostelActivityState(hostel, startup, only);
  }
}

class HostelActivityState extends State<HostelActivity> {
  TextEditingController name = new TextEditingController();
  TextEditingController address = new TextEditingController();
  TextEditingController phone = new TextEditingController();

  Hostel hostel;
  bool startup;
  bool only;

  Map<String, bool> avaiableAmenities = new Map<String, bool>();

  bool loading = false;

  HostelActivityState(this.hostel, this.startup, this.only);

  bool nameCheck = false;
  bool phoneCheck = false;

  @override
  void initState() {
    super.initState();
    amenityTypes.forEach((amenity) => avaiableAmenities[amenity[1]] = false);
    name.text = hostel.name;
    address.text = hostel.address;
    phone.text = hostel.phone;
    hostel.amenities.split(",").forEach((amenity) =>
        amenity.length > 0 ? avaiableAmenities[amenity] = true : null);
  }

  List<Widget> amenitiesWidget() {
    List<Widget> widgets = new List();
    avaiableAmenities.forEach((k, v) => widgets.add(new GestureDetector(
          onTap: () {
            setState(() {
              avaiableAmenities[k] = !avaiableAmenities[k];
            });
          },
          child: new Container(
            width: MediaQuery.of(context).size.width,
            child: new Row(
              children: <Widget>[
                new Checkbox(
                  value: v,
                  onChanged: (bool value) {
                    setState(() {
                      avaiableAmenities[k] = value;
                    });
                  },
                ),
                new Text(
                  getAmenityName(k),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        )));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: new Text(
          "Hostel",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 4.0,
        actions: <Widget>[
          new MaterialButton(
            textColor: Colors.white,
            child: new Text(
              "SAVE",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              setState(() {
                loading = true;
              });
              checkInternet().then((internet) {
                if (!internet) {
                  oneButtonDialog(context, "No Internet connection", "", true);
                  setState(() {
                    loading = false;
                  });
                } else {
                  if (name.text.length == 0) {
                    setState(() {
                      nameCheck = true;
                      loading = false;
                    });
                    return;
                  } else {
                    setState(() {
                      nameCheck = false;
                    });
                  }

                  if (phone.text.length == 0) {
                    setState(() {
                      phoneCheck = true;
                      loading = false;
                    });
                    return;
                  } else {
                    setState(() {
                      phoneCheck = false;
                    });
                  }

                  List<String> savedAmenities = new List();
                  avaiableAmenities.forEach((k, v) {
                    if (v) {
                      savedAmenities.add(k);
                    }
                  });
                  Future<bool> load;
                  load = update(
                    API.HOSTEL,
                    Map.from({
                      "name": name.text,
                      "address": address.text,
                      "phone": phone.text,
                      "amenities": savedAmenities.length > 0
                          ? "," + savedAmenities.join(",") + ","
                          : ""
                    }),
                    Map.from({'id': hostel.id}),
                  );
                  load.then((onValue) {
                    setState(() {
                      loading = false;
                    });
                    Navigator.pop(context, "");
                  });
                }
              });
            },
          ),
        ],
      ),
      body: ModalProgressHUD(
        child: new Container(
          margin: new EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.1,
              25,
              MediaQuery.of(context).size.width * 0.1,
              0),
          child: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Expanded(
                    child: new Container(
                      height: nameCheck ? null : 50,
                      child: new TextField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          suffixIcon: nameCheck
                              ? IconButton(
                                  icon: Icon(Icons.error, color: Colors.red),
                                  onPressed: () {},
                                )
                              : null,
                          errorText: nameCheck ? "Hostel Name required" : null,
                          isDense: true,
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                          labelText: 'Hostel Name',
                        ),
                        onSubmitted: (String value) {},
                      ),
                    ),
                  ),
                ],
              ),
              new Container(
                height: phoneCheck ? null : 50,
                margin: new EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Flexible(
                      child: new Container(
                        child: new TextField(
                          controller: phone,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            suffixIcon: phoneCheck
                                ? IconButton(
                                    icon: Icon(Icons.error, color: Colors.red),
                                    onPressed: () {},
                                  )
                                : null,
                            errorText:
                                phoneCheck ? "Phone Number required" : null,
                            isDense: true,
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            labelText: 'Phone Number',
                          ),
                          onSubmitted: (String value) {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              new Container(
                margin: new EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Flexible(
                      child: new Container(
                        child: new TextField(
                          controller: address,
                          maxLines: 5,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                            labelText: 'Address',
                          ),
                          onSubmitted: (String value) {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              new Container(
                margin: new EdgeInsets.fromLTRB(0, 10, 0, 0),
              ),
              new Expanded(
                child: new GridView.count(
                    childAspectRatio: 3,
                    primary: false,
                    crossAxisCount: 2,
                    children: amenitiesWidget()),
              ),
              only
                  ? new Container()
                  : new Container(
                      margin: new EdgeInsets.fromLTRB(0, 25, 0, 0),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new FlatButton(
                            child: new Text(
                              (hostel == null) ? "" : "DELETE",
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Future<bool> dialog = twoButtonDialog(context,
                                  "Do you want to delete the hostel?", "");
                              dialog.then((onValue) {
                                if (onValue) {
                                  setState(() {
                                    loading = true;
                                  });
                                  Future<bool> delete = update(
                                      API.HOSTEL,
                                      Map.from({'status': '0'}),
                                      Map.from({
                                        'id': hostel.id,
                                      }));
                                  delete.then((response) {
                                    setState(() {
                                      loading = false;
                                    });
                                    Navigator.pop(context, "");
                                  });
                                }
                              });
                            },
                          )
                        ],
                      ),
                    ),
            ],
          ),
        ),
        inAsyncCall: loading,
      ),
    );
  }
}
