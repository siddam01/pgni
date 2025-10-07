import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';
import './photo.dart';

class DocumentsActivity extends StatefulWidget {
  final User user;

  DocumentsActivity({required this.user});

  @override
  State<StatefulWidget> createState() {
    return DocumentsActivityState();
  }
}

class DocumentsActivityState extends State<DocumentsActivity> {
  bool loading = false;
  List<DocumentItem> documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    // Parse existing documents from user.document field
    // Format: "doc1.jpg,doc2.pdf,doc3.png"
    if (widget.user.document.isNotEmpty) {
      List<String> docUrls = widget.user.document.split(',');
      setState(() {
        documents = docUrls.asMap().entries.map((entry) {
          int index = entry.key;
          String url = entry.value.trim();
          return DocumentItem(
            id: index.toString(),
            name: _getDocumentName(url, index),
            url: url,
            uploadDate: DateTime.now(),
            type: _getDocumentType(url),
          );
        }).toList();
      });
    }
  }

  String _getDocumentName(String url, int index) {
    // Extract filename from URL or generate default name
    if (url.contains('/')) {
      return url.split('/').last;
    }
    return 'Document ${index + 1}';
  }

  String _getDocumentType(String url) {
    if (url.toLowerCase().endsWith('.pdf')) return 'PDF';
    if (url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg')) return 'JPG';
    if (url.toLowerCase().endsWith('.png')) return 'PNG';
    return 'File';
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'JPG':
      case 'PNG':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'JPG':
      case 'PNG':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUploadDocument() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Document Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        loading = true;
      });

      File imageFile = File(pickedFile.path);
      String uploadedUrl = await upload(imageFile);

      if (uploadedUrl.isNotEmpty) {
        // Add new document to existing documents
        List<String> allDocs = documents.map((doc) => doc.url).toList();
        allDocs.add(uploadedUrl);

        Map<String, String> updateData = {
          'document': allDocs.join(','),
        };
        Map<String, String> query = {
          'id': userID,
          'hostel_id': hostelID,
        };

        bool success = await update(API.USER, updateData, query);

        if (success) {
          setState(() {
            documents.add(DocumentItem(
              id: documents.length.toString(),
              name: _getDocumentName(uploadedUrl, documents.length),
              url: uploadedUrl,
              uploadDate: DateTime.now(),
              type: _getDocumentType(uploadedUrl),
            ));
            loading = false;
          });
          oneButtonDialog(
              context, "Success", "Document uploaded successfully", true);
        } else {
          setState(() {
            loading = false;
          });
          oneButtonDialog(context, "Error", "Failed to upload document", true);
        }
      } else {
        setState(() {
          loading = false;
        });
        oneButtonDialog(context, "Error", "Failed to upload file", true);
      }
    }
  }

  Future<void> _deleteDocument(DocumentItem document) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Document'),
          content: Text('Are you sure you want to delete this document?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        loading = true;
      });

      // Remove document from list
      List<String> remainingDocs = documents
          .where((doc) => doc.id != document.id)
          .map((doc) => doc.url)
          .toList();

      Map<String, String> updateData = {
        'document': remainingDocs.join(','),
      };
      Map<String, String> query = {
        'id': userID,
        'hostel_id': hostelID,
      };

      bool success = await update(API.USER, updateData, query);

      if (success) {
        setState(() {
          documents.removeWhere((doc) => doc.id == document.id);
          loading = false;
        });
        oneButtonDialog(
            context, "Success", "Document deleted successfully", true);
      } else {
        setState(() {
          loading = false;
        });
        oneButtonDialog(context, "Error", "Failed to delete document", true);
      }
    }
  }

  void _viewDocument(DocumentItem document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoActivity(document.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("My Documents", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
      ),
      body: ModalProgressHUD(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_open, color: Colors.white, size: 40),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Document Manager",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "${documents.length} documents stored",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Documents List
            Expanded(
              child: documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 80, color: Colors.grey[300]),
                          SizedBox(height: 20),
                          Text(
                            "No documents uploaded yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Tap the + button to add documents",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        DocumentItem doc = documents[index];
                        return Slidable(
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                label: 'Delete',
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                onPressed: (context) => _deleteDocument(doc),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getDocumentColor(doc.type)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getDocumentIcon(doc.type),
                                  color: _getDocumentColor(doc.type),
                                  size: 30,
                                ),
                              ),
                              title: Text(
                                doc.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Text(
                                    doc.type,
                                    style: TextStyle(
                                      color: _getDocumentColor(doc.type),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Uploaded: ${dateFormat.format(doc.uploadDate)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _viewDocument(doc),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Upload Info Banner
            if (documents.length < 10)
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You can upload up to 10 documents. Swipe left to delete.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        inAsyncCall: loading,
      ),
      floatingActionButton: documents.length < 10
          ? FloatingActionButton(
              onPressed: _pickAndUploadDocument,
              backgroundColor: Colors.blue[700],
              child: Icon(Icons.add, size: 30),
              tooltip: 'Upload Document',
            )
          : null,
    );
  }
}

// Document Model Class
class DocumentItem {
  final String id;
  final String name;
  final String url;
  final DateTime uploadDate;
  final String type;

  DocumentItem({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadDate,
    required this.type,
  });
}
