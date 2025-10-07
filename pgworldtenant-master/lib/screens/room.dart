import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';
import './photo.dart';
import './services.dart';

class RoomActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RoomActivityState();
  }
}

class RoomActivityState extends State<RoomActivity> {
  User? currentUser;
  Room? currentRoom;
  bool loading = true;
  List<String> amenitiesList = [];
  List<String> roomPhotos = [];

  // Amenity icons mapping
  final Map<String, IconData> amenityIcons = {
    'Wifi': Icons.wifi,
    'Bathroom': Icons.bathroom,
    'TV': Icons.tv,
    'AC': Icons.ac_unit,
    'Power Backup': Icons.power,
    'Washing Machine': Icons.local_laundry_service,
    'Geyser': Icons.hot_tub,
    'Laundry': Icons.dry_cleaning,
  };

  @override
  void initState() {
    super.initState();
    loadRoomData();
  }

  void loadRoomData() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loading = false;
        });
      } else {
        // Load user data to get room information
        Map<String, String> userFilter = {
          'id': userID,
          'hostel_id': hostelID,
          'status': '1'
        };

        Future<Users> userData = getUsers(userFilter);
        userData.then((userResponse) {
          if (userResponse.users.length > 0) {
            currentUser = userResponse.users[0];

            // Load room details if room is assigned
            if (currentUser.roomID.isNotEmpty) {
              Map<String, String> roomFilter = {
                'id': currentUser.roomID,
                'hostel_id': hostelID,
                'status': '1'
              };

              Future<Rooms> roomData = getRooms(roomFilter);
              roomData.then((roomResponse) {
                if (roomResponse.rooms.length > 0) {
                  setState(() {
                    currentRoom = roomResponse.rooms[0];
                    _parseAmenities();
                    _parseRoomPhotos();
                    loading = false;
                  });
                } else {
                  setState(() {
                    loading = false;
                  });
                }
              });
            } else {
              setState(() {
                loading = false;
              });
            }
          } else {
            setState(() {
              loading = false;
            });
          }
        });
      }
    });
  }

  void _parseAmenities() {
    if (currentRoom != null) {
      amenitiesList =
          currentRoom.amenities.split(',').map((a) => a.trim()).toList();
    }
  }

  void _parseRoomPhotos() {
    if (currentRoom != null &&
        currentRoom.document != null &&
        currentRoom.document.isNotEmpty) {
      roomPhotos =
          currentRoom.document.split(',').map((p) => p.trim()).toList();
    }
  }

  void _navigateToServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesActivity(
          roomID: currentRoom?.id,
          roomNo: currentRoom?.roomno ?? currentUser?.roomno,
        ),
      ),
    );
  }

  void _viewPhoto(String photoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoActivity(mediaURL + photoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("My Room", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
        actions: [
          if (currentRoom != null)
            IconButton(
              icon: Icon(Icons.room_service),
              onPressed: _navigateToServices,
              tooltip: "Room Services",
            ),
        ],
      ),
      body: ModalProgressHUD(
        child: loading
            ? Container()
            : currentUser == null
                ? _buildNoRoomAssigned()
                : currentRoom == null
                    ? _buildRoomNotFound()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Room Header
                            _buildRoomHeader(),

                            // Room Photos Gallery
                            if (roomPhotos.isNotEmpty) _buildPhotoGallery(),

                            // Room Specifications
                            _buildRoomSpecs(),

                            // Amenities Section
                            _buildAmenities(),

                            // Rent Details
                            _buildRentDetails(),

                            // Quick Actions
                            _buildQuickActions(),

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
        inAsyncCall: loading,
      ),
    );
  }

  Widget _buildNoRoomAssigned() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined,
                size: 100, color: Colors.grey[300]),
            SizedBox(height: 20),
            Text(
              "No Room Assigned",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You don't have a room assigned yet. Please contact the admin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomNotFound() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: Colors.orange[300]),
            SizedBox(height: 20),
            Text(
              "Room Details Not Available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Room No: ${currentUser.roomno ?? 'N/A'}",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loadRoomData,
              icon: Icon(Icons.refresh),
              label: Text("Retry"),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.meeting_room, size: 60, color: Colors.white),
          ),
          SizedBox(height: 15),
          Text(
            "Room ${currentRoom.roomno ?? 'N/A'}",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: currentRoom.status == "1"
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              currentRoom.status == "1" ? "OCCUPIED" : "AVAILABLE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Room Photos",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: roomPhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _viewPhoto(roomPhotos[index]),
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        mediaURL + roomPhotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image,
                                size: 40, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSpecs() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Room Specifications",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Divider(),
              SizedBox(height: 8),
              _buildSpecRow(Icons.meeting_room, "Room Number",
                  currentRoom.roomno ?? "N/A"),
              _buildSpecRow(
                  Icons.king_bed, "Type", currentRoom.type ?? "Standard Room"),
              _buildSpecRow(Icons.square_foot, "Size",
                  currentRoom.size ?? "Not specified"),
              _buildSpecRow(
                  Icons.person, "Capacity", "${currentRoom.capacity} persons"),
              _buildSpecRow(
                Icons.info_outline,
                "Status",
                currentRoom.status == "1" ? "Occupied" : "Available",
                valueColor:
                    currentRoom.status == "1" ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Room Amenities",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 8),
              amenitiesList.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "No amenities listed",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: amenitiesList.map((amenity) {
                        return _buildAmenityChip(amenity);
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    IconData icon = amenityIcons[amenity] ?? Icons.check_circle;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          SizedBox(width: 8),
          Text(
            amenity,
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rent Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Divider(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monthly Rent",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    "₹${currentRoom.rent}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Occupied Since",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      dateFormat
                          .format(DateTime.parse(currentUser.joiningDateTime)),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.room_service, color: Colors.blue[700]),
              ),
              title: Text("Request Room Service",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("Cleaning, maintenance, or other services"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _navigateToServices,
            ),
            Divider(height: 1),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.report_problem, color: Colors.orange[700]),
              ),
              title: Text("Report Issue",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("Report any problem with your room"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate back to dashboard issues tab
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Add getRooms function to api.dart if not exists
Future<Rooms> getRooms(Map<String, String> query) async {
  try {
    final response = await http
        .get(Uri.http(API.URL, API.ROOM, query), headers: headers)
        .timeout(Duration(seconds: timeout));
    return Rooms.fromJson(json.decode(response.body));
  } catch (e) {
    return null;
  }
}
