import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';
import "dart:math";

DateFormat dateFormat = DateFormat('yyyy-MM-dd');
DateFormat headingDateFormat = DateFormat("EEE, MMM d, ''yy");
DateFormat timeFormat = DateFormat("h:mm a");

List<String> colors = [
  "#D7BDE2",
  "#F5CBA7",
  "#F9E79F",
  "#A2D9CE",
  "#AED6F1",
  "#F5B7B1",
  "#ABB2B9"
];

final random = Random();

late SharedPreferences prefs;
Future<bool> initSharedPreference() async {
  prefs = await SharedPreferences.getInstance();
  return true;
}

// void launchURL(String url) async {
//   if (await canLaunch(url)) {
//     await launch(url);
//   }
// }

// void makePhone(String phone) async {
//   var url = 'tel:' + phone;
//   if (await canLaunch(url)) {
//     await launch(url);
//   }
// }

// void sendMail(String mail, String subject, String body) async {
//   var url = 'mailto:' +
//       mail +
//       "?subject=" +
//       subject +
//       "&body=" +
//       Uri.encodeComponent(body);
//   print(url);
//   if (await canLaunch(url)) {
//     await launch(url);
//   }
// }

Future<bool> checkInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}

Widget showProgress(String title) {
  return AlertDialog(
    title: new Container(
      padding: EdgeInsets.all(10),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Text(
              title,
            ),
          ),
          new Container(
            padding: new EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: new CircularProgressIndicator(),
          )
        ],
      ),
    ),
  );
}

Widget popDialog(BuildContext context, String title, bool pop) {
  return AlertDialog(
    title: Text(title),
    actions: <Widget>[
      TextButton(
        child: const Text("ok"),
        onPressed: () {
          if (pop) {
            Navigator.of(context).pop();
          }
        },
      ),
    ],
  );
}

IconData getAmenityIcon(String id) {
  switch (id) {
    case "1": // wifi
      return Icons.wifi;
    case "2": // bathroom
      return Icons.smoking_rooms;
    case "3": // tv
      return Icons.tv;
    case "4": // ac
      return Icons.ac_unit;
    case "5": // power backup
      return Icons.power;
    default:
      return Icons.plus_one;
  }
}

String getAmenityName(String id) {
  switch (id) {
    case "1": // wifi
      return "Wifi";
    case "2": // bathroom
      return "Bathroom";
    case "3": // tv
      return "TV";
    case "4": // ac
      return "AC";
    case "5": // power backup
      return "Power Backup";
    default:
      return "";
  }
}

List<Widget> getAmenitiesWidgets(String amenities) {
  List<Widget> widgets = <Widget>[];
  amenities.split(",").forEach((amenity) {
    String name = getAmenityName(amenity);
    if (name.isNotEmpty) {
      widgets.add(Column(
        children: <Widget>[
          Icon(
            getAmenityIcon(amenity),
            size: 15,
          ),
          Text(
            name,
            style: TextStyle(fontSize: 10),
          )
        ],
      ));
      widgets.add(new Container(
        width: 15,
      ));
    }
  });

  return widgets;
}

Future<bool> twoButtonDialog(
    BuildContext context, String title, String content) async {
  bool returned = false;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text("No"),
            onPressed: () {
              Navigator.of(context).pop();
              returned = false;
            },
          ),
          TextButton(
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              returned = true;
            },
          ),
        ],
      );
    },
  );
  return returned;
}

void oneButtonDialog(
    BuildContext context, String title, String content, bool dismiss) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content != "" ? Text(content) : null,
        actions: <Widget>[
          TextButton(
            child: const Text("ok"),
            onPressed: () {
              if (dismiss) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

String getBillType(String id) {
  switch (id) {
    case "1":
      return "Cable Bill";
      break;
    case "2":
      return "Water Bill";
      break;
    case "3":
      return "Electricity Bill";
      break;
    case "4":
      return "Food Expense";
      break;
    case "5":
      return "Internet Bill";
      break;
    case "6":
      return "Maintainance";
      break;
    case "7":
      return "Property Rent/Tax";
      break;
    case "8":
      return "Others";
      break;
    default:
      return "";
  }
}

IconData getBillIcon(String id) {
  switch (id) {
    case "1":
      return Icons.tv;
      break;
    case "2":
      return Icons.hot_tub;
      break;
    case "3":
      return Icons.flash_on;
      break;
    case "4":
      return Icons.local_dining;
      break;
    case "5":
      return Icons.wifi;
      break;
    case "6":
      return Icons.adjust;
      break;
    case "7":
      return Icons.local_parking;
      break;
    case "8":
      return Icons.receipt;
    default:
      return Icons.help_outline;
  }
}
