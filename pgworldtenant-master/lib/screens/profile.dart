import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';
import './editProfile.dart';
import './documents.dart';
import './photo.dart';

class ProfileActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ProfileActivityState();
  }
}

class ProfileActivityState extends State<ProfileActivity> {
  User? currentUser;
  bool loading = true;
  String profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  void loadUserProfile() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loading = false;
        });
      } else {
        Map<String, String> filter = {
          'id': userID,
          'hostel_id': hostelID,
          'status': '1'
        };
        Future<Users> data = getUsers(filter);
        data.then((response) {
          if (response.users.length > 0) {
            setState(() {
              currentUser = response.users[0];
              profileImageUrl = currentUser.document ?? "";
              loading = false;
            });
          } else {
            setState(() {
              loading = false;
            });
          }
          if (response.meta.messageType == "1") {
            oneButtonDialog(context, "", response.meta.message,
                !(response.meta.status == STATUS_403));
          }
        });
      }
    });
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        loading = true;
      });

      File imageFile = File(pickedFile.path);
      String uploadedUrl = await upload(imageFile);

      if (uploadedUrl.isNotEmpty) {
        // Update user profile with new photo
        Map<String, String> updateData = {
          'document': uploadedUrl,
        };
        Map<String, String> query = {
          'id': userID,
          'hostel_id': hostelID,
        };

        bool success = await update(API.USER, updateData, query);

        if (success) {
          setState(() {
            profileImageUrl = uploadedUrl;
            loading = false;
          });
          oneButtonDialog(
              context, "Success", "Profile photo updated successfully", true);
        } else {
          setState(() {
            loading = false;
          });
          oneButtonDialog(
              context, "Error", "Failed to update profile photo", true);
        }
      } else {
        setState(() {
          loading = false;
        });
        oneButtonDialog(context, "Error", "Failed to upload photo", true);
      }
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileActivity(user: currentUser),
      ),
    );

    if (result == true) {
      // Reload profile after edit
      loadUserProfile();
    }
  }

  void _navigateToDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentsActivity(user: currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("My Profile", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: currentUser != null ? _navigateToEditProfile : null,
          ),
        ],
      ),
      body: ModalProgressHUD(
        child: loading
            ? Container()
            : currentUser == null
                ? Center(
                    child: Text("No profile data available"),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundImage:
                                          profileImageUrl.isNotEmpty
                                              ? NetworkImage(
                                                  mediaURL + profileImageUrl)
                                              : null,
                                      child: profileImageUrl.isEmpty
                                          ? Icon(Icons.person,
                                              size: 60, color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickAndUploadProfilePhoto,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Text(
                                currentUser.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Room: ${currentUser.roomno ?? 'Not Assigned'}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Profile Information Cards
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoCard(
                                "Contact Information",
                                [
                                  _buildInfoRow(Icons.phone, "Phone",
                                      currentUser.phone ?? "Not provided"),
                                  _buildInfoRow(Icons.email, "Email",
                                      currentUser.email ?? "Not provided"),
                                  _buildInfoRow(Icons.home, "Address",
                                      currentUser.address ?? "Not provided"),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoCard(
                                "Emergency Contact",
                                [
                                  _buildInfoRow(
                                      Icons.person,
                                      "Contact Name",
                                      currentUser.emerContact ??
                                          "Not provided"),
                                  _buildInfoRow(
                                      Icons.phone_in_talk,
                                      "Contact Phone",
                                      currentUser.emerPhone ?? "Not provided"),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoCard(
                                "Room & Rent Details",
                                [
                                  _buildInfoRow(Icons.meeting_room, "Room No",
                                      currentUser.roomno ?? "Not assigned"),
                                  _buildInfoRow(Icons.currency_rupee,
                                      "Monthly Rent", "₹${currentUser.rent}"),
                                  _buildInfoRow(
                                      Icons.calendar_today,
                                      "Joining Date",
                                      dateFormat.format(DateTime.parse(
                                          currentUser.joiningDateTime))),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoCard(
                                "Payment Status",
                                [
                                  _buildInfoRow(
                                      Icons.payment,
                                      "Payment Status",
                                      currentUser.paymentStatus == "1"
                                          ? "Paid"
                                          : "Pending",
                                      statusColor:
                                          currentUser.paymentStatus == "1"
                                              ? Colors.green
                                              : Colors.orange),
                                  _buildInfoRow(
                                      Icons.date_range,
                                      "Last Payment",
                                      dateFormat.format(DateTime.parse(
                                          currentUser.lastPaidDateTime))),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Action Buttons
                              Card(
                                elevation: 2,
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.folder_open,
                                          color: Colors.blue),
                                      title: Text("My Documents"),
                                      subtitle: Text(
                                          "View and manage your documents"),
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                      onTap: _navigateToDocuments,
                                    ),
                                    Divider(height: 1),
                                    ListTile(
                                      leading:
                                          Icon(Icons.edit, color: Colors.green),
                                      title: Text("Edit Profile"),
                                      subtitle: Text(
                                          "Update your personal information"),
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                      onTap: _navigateToEditProfile,
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? statusColor}) {
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
                color: statusColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
