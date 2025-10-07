// post

import 'package:flutter/material.dart';

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

class Post {
  final String? id;
  final Meta? meta;

  Post({required this.id, required this.meta});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

// admin

class Admins {
  final List<Admin> admins;
  final Meta meta;
  final Pagination pagination;

  Admins({required this.admins, required this.meta, required this.pagination});

  factory Admins.fromJson(Map<String, dynamic> json) {
    return Admins(
      admins: json['data'] != null
          ? List<Admin>.from(json['data'].map((i) => Admin.fromJson(i)))
          : <Admin>[],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : Pagination(count: '0', offset: '0', totalCount: '0'),
    );
  }
}

class Admin {
  final String id;
  final String username;
  final String password;
  final String email;
  final String hostels;
  final String amenities;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Admin(
      {required this.id,
      required this.username,
      required this.password,
      required this.email,
      required this.hostels,
      required this.amenities,
      required this.status,
      required this.createdBy,
      required this.modifiedBy,
      required this.createdDateTime,
      required this.modifiedDateTime});

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      hostels: json['hostels'] ?? '',
      amenities: json['amenities'] ?? '',
      status: json['status'] ?? '',
      createdBy: json['created_by'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      createdDateTime: json['created_date_time'] ?? '',
      modifiedDateTime: json['modified_date_time'] ?? '',
    );
  }
}

// bill

class Bills {
  final List<Bill> bills;
  final Meta meta;
  final Pagination pagination;

  Bills({required this.bills, required this.meta, required this.pagination});

  factory Bills.fromJson(Map<String, dynamic> json) {
    return Bills(
      bills: json['data'] != null
          ? List<Bill>.from(json['data'].map((i) => Bill.fromJson(i)))
          : <Bill>[],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : Pagination(count: '0', offset: '0', totalCount: '0'),
    );
  }
}

abstract class ListItem {}

class HeadingItem implements ListItem {
  final String heading;

  HeadingItem(this.heading);
}

class Bill implements ListItem {
  final String id;
  final String hostelID;
  final String title;
  final String userID;
  final String employeeID;
  final String description;
  final String type;
  final String document;
  final String amount;
  final String paid;
  final String paidDateTime;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Bill(
      {required this.id,
      required this.hostelID,
      required this.title,
      required this.userID,
      required this.employeeID,
      required this.description,
      required this.type,
      required this.document,
      required this.amount,
      required this.paid,
      required this.paidDateTime,
      required this.status,
      required this.createdBy,
      required this.modifiedBy,
      required this.createdDateTime,
      required this.modifiedDateTime});

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] ?? '',
      hostelID: json['hostel_id'] ?? '',
      title: json['title'] ?? '',
      userID: json['user_id'] ?? '',
      employeeID: json['employee_id'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      document: json['document'] ?? '',
      amount: json['amount'] ?? '',
      paid: json['paid'] ?? '',
      paidDateTime: json['paid_date_time'] ?? '',
      status: json['status'] ?? '',
      createdBy: json['created_by'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      createdDateTime: json['created_date_time'] ?? '',
      modifiedDateTime: json['modified_date_time'] ?? '',
    );
  }
}

// dashboard

class Dashboards {
  final List<Graph> graphs;
  final List<Dashboard> dashboards;
  final Meta meta;

  Dashboards({required this.graphs, required this.dashboards, required this.meta});

  factory Dashboards.fromJson(Map<String, dynamic> json) {
    return Dashboards(
      graphs: json['graphs'] != null
          ? List<Graph>.from(json['graphs'].map((i) => Graph.fromJson(i)))
          : <Graph>[],
      dashboards: json['data'] != null
          ? List<Dashboard>.from(json['data'].map((i) => Dashboard.fromJson(i)))
          : <Dashboard>[],
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Dashboard {
  final String user;
  final String room;
  final String bill;
  final String note;
  final String employee;

  Dashboard({
    this.user,
    this.room,
    this.bill,
    this.note,
    this.employee,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      user: json['user'],
      room: json['room'],
      bill: json['bill'],
      note: json['note'],
      employee: json['employee'],
    );
  }
}

// employee

class Employees {
  final List<Employee> employees;
  final Meta meta;
  final Pagination pagination;

  Employees({required this.employees, required this.meta, required this.pagination});

  factory Employees.fromJson(Map<String, dynamic> json) {
    return Employees(
      employees: json['data'] != null
          ? List<Employee>.from(json['data'].map((i) => Employee.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String designation;
  final String phone;
  final String email;
  final String address;
  final String document;
  final String salary;
  final String joiningDateTime;
  final String lastPaidDateTime;
  final String expiryDateTime;
  final String leaveDateTime;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Employee(
      {this.id,
      this.name,
      this.designation,
      this.phone,
      this.email,
      this.address,
      this.document,
      this.salary,
      this.joiningDateTime,
      this.lastPaidDateTime,
      this.expiryDateTime,
      this.leaveDateTime,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      designation: json['designation'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      document: json['document'],
      salary: json['salary'],
      joiningDateTime: json['joining_date_time'],
      lastPaidDateTime: json['last_paid_date_time'],
      expiryDateTime: json['expiry_date_time'],
      leaveDateTime: json['leave_date_time'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// hostel

class Hostels {
  final List<Hostel> hostels;
  final Meta meta;
  final Pagination pagination;

  Hostels({required this.hostels, required this.meta, required this.pagination});

  factory Hostels.fromJson(Map<String, dynamic> json) {
    return Hostels(
      hostels: json['data'] != null
          ? List<Hostel>.from(json['data'].map((i) => Hostel.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Hostel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String amenities;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String expiryDateTime;
  final String createdDateTime;
  final String modifiedDateTime;

  Hostel(
      {this.id,
      this.name,
      this.phone,
      this.email,
      this.address,
      this.amenities,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.expiryDateTime,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      amenities: json['amenities'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      expiryDateTime: json['expiry_date_time'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// issue

class Issues {
  final List<Issue> issues;
  final Meta meta;
  final Pagination pagination;

  Issues({required this.issues, required this.meta, required this.pagination});

  factory Issues.fromJson(Map<String, dynamic> json) {
    return Issues(
      issues: json['data'] != null
          ? List<Issue>.from(json['data'].map((i) => Issue.fromJson(i)))
          : <Issue>[],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : Pagination(count: '0', offset: '0', totalCount: '0'),
    );
  }
}

class Issue {
  final String id;
  final String title;
  final String userID;
  final String hostelID;
  final String type;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Issue(
      {required this.id,
      required this.title,
      required this.userID,
      required this.hostelID,
      required this.type,
      required this.status,
      required this.createdBy,
      required this.modifiedBy,
      required this.createdDateTime,
      required this.modifiedDateTime});

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      userID: json['user_id'] ?? '',
      hostelID: json['hostel_id'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      createdBy: json['created_by'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      createdDateTime: json['created_date_time'] ?? '',
      modifiedDateTime: json['modified_date_time'] ?? '',
    );
  }
}

// log

class Logs {
  final List<Log> logs;
  final Meta meta;
  final Pagination pagination;

  Logs({required this.logs, required this.meta, required this.pagination});

  factory Logs.fromJson(Map<String, dynamic> json) {
    return Logs(
      logs: json['data'] != null
          ? List<Log>.from(json['data'].map((i) => Log.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Log implements ListItem {
  final String id;
  final String log;
  final String by;
  final String type;
  String color;
  IconData icon;
  String title;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Log(
      {this.id,
      this.log,
      this.by,
      this.type,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      id: json['id'],
      log: json['log'],
      by: json['by'],
      type: json['type'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// note

class Notes {
  final List<Note> notes;
  final Meta meta;
  final Pagination pagination;

  Notes({required this.notes, required this.meta, required this.pagination});

  factory Notes.fromJson(Map<String, dynamic> json) {
    return Notes(
      notes: json['data'] != null
          ? List<Note>.from(json['data'].map((i) => Note.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Note implements ListItem {
  final String id;
  final String note;
  String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Note(
      {this.id,
      this.note,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      note: json['note'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// notice

class Notices implements ListItem {
  final List<Notice> notices;
  final Meta meta;
  final Pagination pagination;

  Notices({required this.notices, required this.meta, required this.pagination});

  factory Notices.fromJson(Map<String, dynamic> json) {
    return Notices(
      notices: json['data'] != null
          ? List<Notice>.from(json['data'].map((i) => Notice.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Notice {
  final String id;
  final String title;
  final String img;
  final String hostelID;
  final String type;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Notice(
      {this.id,
      this.title,
      this.img,
      this.hostelID,
      this.type,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      img: json['img'],
      hostelID: json['hostel_id'],
      type: json['type'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// room

class Rooms {
  final List<Room> rooms;
  final Meta meta;
  final Pagination pagination;

  Rooms({required this.rooms, required this.meta, required this.pagination});

  factory Rooms.fromJson(Map<String, dynamic> json) {
    return Rooms(
      rooms: json['data'] != null
          ? List<Room>.from(json['data'].map((i) => Room.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Room {
  final String id;
  final String hostelID;
  final String roomno;
  final String rent;
  final String floor;
  final String filled;
  final String capacity;
  final String amenities;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  Room(
      {this.id,
      this.hostelID,
      this.roomno,
      this.rent,
      this.floor,
      this.filled,
      this.capacity,
      this.amenities,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      hostelID: json['hostel_id'],
      roomno: json['roomno'],
      rent: json['rent'],
      floor: json['floor'],
      filled: json['filled'],
      capacity: json['capacity'],
      amenities: json['amenities'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

// user

class Users {
  final List<User> users;
  final Meta meta;
  final Pagination pagination;

  Users({required this.users, required this.meta, required this.pagination});

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      users: json['data'] != null
          ? List<User>.from(json['data'].map((i) => User.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class User {
  final String id;
  final String hostelID;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String roomID;
  final String roomno;
  final String rent;
  final String emerContact;
  final String emerPhone;
  final String food;
  final String document;
  final String paymentStatus;
  final String joiningDateTime;
  final String lastPaidDateTime;
  final String expiryDateTime;
  final String leaveDateTime;
  final String status;
  final String createdBy;
  final String modifiedBy;
  final String createdDateTime;
  final String modifiedDateTime;

  User(
      {this.id,
      this.hostelID,
      this.name,
      this.phone,
      this.email,
      this.address,
      this.roomID,
      this.roomno,
      this.rent,
      this.emerContact,
      this.emerPhone,
      this.food,
      this.document,
      this.paymentStatus,
      this.joiningDateTime,
      this.lastPaidDateTime,
      this.expiryDateTime,
      this.leaveDateTime,
      this.status,
      this.createdBy,
      this.modifiedBy,
      this.createdDateTime,
      this.modifiedDateTime});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      hostelID: json['hostel_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      roomID: json['room_id'],
      roomno: json['roomno'],
      rent: json['rent'],
      emerContact: json['emer_contact'],
      emerPhone: json['emer_phone'],
      food: json['food'],
      document: json['document'],
      paymentStatus: json['payment_status'],
      joiningDateTime: json['joining_date_time'],
      lastPaidDateTime: json['last_paid_date_time'],
      expiryDateTime: json['expiry_date_time'],
      leaveDateTime: json['leave_date_time'],
      status: json['status'],
      createdBy: json['created_by'],
      modifiedBy: json['modified_by'],
      createdDateTime: json['created_date_time'],
      modifiedDateTime: json['modified_date_time'],
    );
  }
}

class Meta {
  final String status;
  final String message;
  final String messageType;

  Meta({required this.status, required this.message, required this.messageType});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      status: json['status'],
      message: json['message'],
      messageType: json['message_type'],
    );
  }
}

class Pagination {
  final String count;
  final String offset;
  final String totalCount;

  Pagination({required this.count, required this.offset, required this.totalCount});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      count: json['count']?.toString() ?? '0',
      offset: json['offset']?.toString() ?? '0',
      totalCount: json['total_count']?.toString() ?? '0',
    );
  }
}

// reports
class Charts {
  final List<Graph> graphs;
  final Meta meta;

  Charts({required this.graphs, required this.meta});

  factory Charts.fromJson(Map<String, dynamic> json) {
    return Charts(
      graphs: json['graphs'] != null
          ? List<Graph>.from(json['graphs'].map((i) => Graph.fromJson(i)))
          : [],
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Graph {
  final String title;
  final String color;
  final String dataTitle;
  final String type;
  final String steps;
  final List<ChartType2> data;

  Graph(
      {this.title,
      this.color,
      this.dataTitle,
      this.type,
      this.steps,
      this.data});

  factory Graph.fromJson(Map<String, dynamic> json) {
    return Graph(
      title: json['title'],
      color: json['color'],
      dataTitle: json['data_title'],
      type: json['type'],
      steps: json['steps'],
      data: json['data'] != null
          ? List<ChartType2>.from(
              json['data'].map((i) => ChartType2.fromJson(i)))
          : [],
    );
  }
}

class ChartType2 {
  final String title;
  final String color;
  final List<ChartData> data;

  ChartType2({required this.title, required this.color, required this.data});

  factory ChartType2.fromJson(Map<String, dynamic> json) {
    return ChartType2(
      title: json['title'],
      color: json['color'],
      data: json['data'] != null
          ? List<ChartData>.from(json['data'].map((i) => ChartData.fromJson(i)))
          : [],
    );
  }
}

class ChartData {
  String title;
  String value;
  String color;
  String shown;

  ChartData({
    this.title,
    this.value,
    this.color,
    this.shown,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) => new ChartData(
        title: json["title"],
        value: json["value"],
        color: json["color"],
        shown: json["shown"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "value": value,
        "color": color,
        "shown": shown,
      };
}
