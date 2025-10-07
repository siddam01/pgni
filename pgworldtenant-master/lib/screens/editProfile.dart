import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';

class EditProfileActivity extends StatefulWidget {
  final User user;

  EditProfileActivity({required this.user});

  @override
  State<StatefulWidget> createState() {
    return EditProfileActivityState();
  }
}

class EditProfileActivityState extends State<EditProfileActivity> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController emerContactController;
  late TextEditingController emerPhoneController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current user data
    nameController = TextEditingController(text: widget.user.name ?? '');
    phoneController = TextEditingController(text: widget.user.phone ?? '');
    emailController = TextEditingController(text: widget.user.email ?? '');
    addressController = TextEditingController(text: widget.user.address ?? '');
    emerContactController =
        TextEditingController(text: widget.user.emerContact ?? '');
    emerPhoneController =
        TextEditingController(text: widget.user.emerPhone ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    emerContactController.dispose();
    emerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });

      checkInternet().then((internet) async {
        if (!internet) {
          oneButtonDialog(context, "No Internet connection", "", true);
          setState(() {
            loading = false;
          });
        } else {
          Map<String, String> updateData = {
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'address': addressController.text.trim(),
            'emer_contact': emerContactController.text.trim(),
            'emer_phone': emerPhoneController.text.trim(),
          };

          Map<String, String> query = {
            'id': userID,
            'hostel_id': hostelID,
          };

          bool success = await update(API.USER, updateData, query);

          setState(() {
            loading = false;
          });

          if (success) {
            // Update global name variable
            name = nameController.text.trim();
            prefs.setString('name', name);

            oneButtonDialog(
                context, "Success", "Profile updated successfully", true);

            // Return to profile screen with success flag
            Navigator.pop(context, true);
          } else {
            oneButtonDialog(context, "Error", "Failed to update profile", true);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("Edit Profile", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
      ),
      body: ModalProgressHUD(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Address Field
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: "Permanent Address",
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  // Emergency Contact Section
                  Text(
                    "Emergency Contact",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Emergency Contact Name
                  TextFormField(
                    controller: emerContactController,
                    decoration: InputDecoration(
                      labelText: "Emergency Contact Name",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter emergency contact name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Emergency Contact Phone
                  TextFormField(
                    controller: emerPhoneController,
                    decoration: InputDecoration(
                      labelText: "Emergency Contact Phone",
                      prefixIcon: Icon(Icons.phone_in_talk),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter emergency contact phone';
                      }
                      if (value.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Cancel Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        inAsyncCall: loading,
      ),
    );
  }
}
