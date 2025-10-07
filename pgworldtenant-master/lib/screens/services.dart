import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';

class ServicesActivity extends StatefulWidget {
  final String roomID;
  final String roomNo;

  ServicesActivity({required this.roomID, required this.roomNo});

  @override
  State<StatefulWidget> createState() {
    return ServicesActivityState();
  }
}

class ServicesActivityState extends State<ServicesActivity> {
  bool loading = false;
  String selectedService = "";
  TextEditingController descriptionController = TextEditingController();

  // Service types
  final List<ServiceType> serviceTypes = [
    ServiceType(
      name: "Room Cleaning",
      icon: Icons.cleaning_services,
      color: Colors.blue,
      description: "Request room cleaning service",
    ),
    ServiceType(
      name: "AC Repair",
      icon: Icons.ac_unit,
      color: Colors.cyan,
      description: "Air conditioning maintenance or repair",
    ),
    ServiceType(
      name: "Plumbing",
      icon: Icons.plumbing,
      color: Colors.orange,
      description: "Water, drainage, or bathroom issues",
    ),
    ServiceType(
      name: "Electrical",
      icon: Icons.electrical_services,
      color: Colors.amber,
      description: "Electrical fittings or power issues",
    ),
    ServiceType(
      name: "Furniture",
      icon: Icons.weekend,
      color: Colors.brown,
      description: "Bed, table, or furniture repair",
    ),
    ServiceType(
      name: "Laundry",
      icon: Icons.local_laundry_service,
      color: Colors.purple,
      description: "Laundry or washing service",
    ),
    ServiceType(
      name: "Housekeeping",
      icon: Icons.room_service,
      color: Colors.green,
      description: "General housekeeping services",
    ),
    ServiceType(
      name: "Other",
      icon: Icons.miscellaneous_services,
      color: Colors.grey,
      description: "Any other service request",
    ),
  ];

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _submitServiceRequest() {
    if (selectedService.isEmpty) {
      oneButtonDialog(context, "Error", "Please select a service type", true);
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      oneButtonDialog(
          context, "Error", "Please provide service description", true);
      return;
    }

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
        // Create issue/service request
        Map<String, String> requestData = {
          'hostel_id': hostelID,
          'user_id': userID,
          'room_id': widget.roomID ?? '',
          'type': _getIssueType(selectedService),
          'title': selectedService,
          'description': descriptionController.text.trim(),
          'status': '1',
        };

        bool success = await add(API.ISSUE, requestData);

        setState(() {
          loading = false;
        });

        if (success) {
          oneButtonDialog(
            context,
            "Success",
            "Service request submitted successfully! Our team will attend to it shortly.",
            true,
          ).then((_) {
            Navigator.pop(context);
          });
        } else {
          oneButtonDialog(
              context, "Error", "Failed to submit service request", true);
        }
      }
    });
  }

  String _getIssueType(String serviceName) {
    // Map service names to issue types
    Map<String, String> serviceTypeMap = {
      "Room Cleaning": "6", // Cleaning
      "AC Repair": "13", // Appliances
      "Plumbing": "4", // Plumbing
      "Electrical": "3", // Electrical
      "Furniture": "7", // Bed
      "Laundry": "6", // Cleaning
      "Housekeeping": "6", // Cleaning
      "Other": "14", // Others
    };
    return serviceTypeMap[serviceName] ?? "14";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("Room Services", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
      ),
      body: ModalProgressHUD(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.room_service, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Request Room Service",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Room ${widget.roomNo ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions
              Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Select the type of service you need and provide details. Our team will respond within 24 hours.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Service Selection
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Service Type",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: serviceTypes.length,
                      itemBuilder: (context, index) {
                        ServiceType service = serviceTypes[index];
                        bool isSelected = selectedService == service.name;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedService = service.name;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? service.color.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? service.color
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: service.color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  service.icon,
                                  size: 40,
                                  color: isSelected
                                      ? service.color
                                      : Colors.grey[600],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  service.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? service.color
                                        : Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: service.color,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Service Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            "Please provide details about the service you need...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Submit Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitServiceRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          "Submit Request",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Service Info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Service Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, "Response Time",
                            "Within 24 hours"),
                        _buildInfoRow(
                            Icons.people, "Service Team", "Professional staff"),
                        _buildInfoRow(
                            Icons.schedule, "Working Hours", "8 AM - 8 PM"),
                        _buildInfoRow(
                            Icons.phone, "Urgent Issues", "Contact admin"),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
        inAsyncCall: loading,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

// Service Type Model
class ServiceType {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  ServiceType({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
