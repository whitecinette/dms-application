import 'dart:io';
import 'package:dms_app/config.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class BillUploadScreen extends StatefulWidget {
  @override
  _BillUploadScreenState createState() => _BillUploadScreenState();
}

class _BillUploadScreenState extends State<BillUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? billType;
  String? remarks;
  List<XFile> selectedImages = [];
  bool isLoading = false;
  String? errorMessage;
  String? amount;
  int selectedTab = 0;
  bool isBillsLoading = false;
  String? billsError;
  List<dynamic> allBills = [];
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String? selectedStatus;

  final List<String> statusOptions = ['pending', 'approved', 'rejected', 'paid'];

  @override
  void initState() {
    super.initState();
    fetchBills(); // ✅ ensure this is called
  }

  final List<String> billTypes = [
    'Restaurant', 'Travel', 'Hotel', 'Transport', 'Fuel', 'Other',
  ];

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => selectedImages.add(picked));
    }
  }

  Future<void> _uploadBills() async {
    if (!_formKey.currentState!.validate() || billType == null || selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload at least one image'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      var uri = Uri.parse("${Config.backendUrl}/upload-bills");
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['billType'] = billType!;
      request.fields['remarks'] = (remarks == null || remarks!.trim().isEmpty) ? 'No remarks' : remarks!;
      request.fields['amount'] = amount ?? '0';
      request.fields['isGenerated'] = 'false';

      for (var img in selectedImages) {
        var file = await http.MultipartFile.fromPath("billsUpload", img.path);
        request.files.add(file);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        CustomPopup.showPopup(
          context,
          "Success",
          "Bills uploaded successfully!",
          isSuccess: true,
        );
        setState(() {
          billType = null;
          remarks = null;
          selectedImages.clear();
          isLoading = false;
        });
        _formKey.currentState?.reset();
      } else {
        throw data['message'] ?? 'Failed to upload';
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      CustomPopup.showPopup(
        context,
        "Upload Failed",
        e.toString(),
        isSuccess: false,
      );
    }
  }

  Future<void> fetchBills() async {
    print("fetching bill");
    setState(() {
      isBillsLoading = true;
      billsError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Build query parameters
      final queryParams = <String, String>{};
      if (selectedStatus != null) {
        queryParams['status'] = selectedStatus!;
      }
      if (selectedStartDate != null) {
        final formattedDate = selectedStartDate!.toIso8601String().split('T')[0];
        queryParams['startDate'] = formattedDate;
      }

      final uri = Uri.parse("${Config.backendUrl}/get-bills-for-emp")
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data); // or print(data); to inspect the full response
        print(data['bills'][0]['billsUpload']); // Check if image array exists
        setState(() {
          allBills = List<Map<String, dynamic>>.from(data['bills']);
          isBillsLoading = false;
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          billsError = data['message'] ?? 'Failed to load bills.';
          isBillsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        billsError = 'Something went wrong: $e';
        isBillsLoading = false;
      });
    }
  }

  void _showBillImagesPopup(List<dynamic> images) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Bills"),
        content: SizedBox(
          width: double.maxFinite,
          child: images.isEmpty
              ? Text("No images available.")
              : ListView.builder(
            shrinkWrap: true,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              final isImage = imageUrl.endsWith('.jpg') ||
                  imageUrl.endsWith('.jpeg') ||
                  imageUrl.endsWith('.png');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: isImage
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, height: 150),
                )
                    : InkWell(
                  onTap: () async {
                    // You can use url_launcher to open the PDF externally
                    if (await canLaunchUrl(Uri.parse(imageUrl))) {
                      launchUrl(Uri.parse(imageUrl));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Open PDF ${index + 1}",
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final file = XFile(path);
      setState(() => selectedImages.add(file));
    }
  }

  Widget _buildImageTile(XFile file) {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: isPdf
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                SizedBox(height: 4),
                Text(
                  "PDF",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(file.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => selectedImages.remove(file)),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFileSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Capture Image'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => selectedImages.add(picked));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Pick from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickMultiImage();
                if (picked != null && picked.isNotEmpty) {
                  setState(() => selectedImages.addAll(picked));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Pick PDF File'),
              onTap: () async {
                Navigator.pop(context);
                // Requires file_picker package for picking PDF
                await _pickPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBox() {
    return GestureDetector(
      onTap: _showFileSourceDialog,
      child: DottedBorder(
        color: Color(0xFF6FA3DB),
        strokeWidth: 1.5,
        dashPattern: [8, 4],
        borderType: BorderType.RRect,
        radius: Radius.circular(12),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file, size: 32, color: Colors.grey[700]),
                SizedBox(height: 6),
                Text(
                  "Upload Bills",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$title:",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        Flexible(
          child: Text(
            value ?? 'N/A',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Color(0xFF372A9B) : Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Container(
            height: 2,
            width: 80,
            color: isSelected ? Color(0xFF372A9B) : Colors.transparent,
          )
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1, 1), // x: 1, y: 1
                  blurRadius: 4,
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: billType,
              decoration: InputDecoration(
                labelText: "Select Bill Type",
                labelStyle: TextStyle(color: Colors.grey[500]), // lighter label
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: billTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => billType = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
          ),


          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextFormField(
              maxLines: 3,
              style: TextStyle(color: Colors.grey[700]), // lighter text color
              decoration: InputDecoration(
                labelText: "Put some description",
                labelStyle: TextStyle(color: Colors.grey[500]), // lighter label
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => remarks = val,
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextFormField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: Colors.grey[700]),
              decoration: InputDecoration(
                labelText: "Enter amount",
                labelStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => amount = val,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final numVal = num.tryParse(val);
                if (numVal == null || numVal <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
          ),

          SizedBox(height: 24),
          _buildCameraBox(),
          SizedBox(height: 20),
          if (selectedImages.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selectedImages.map(_buildImageTile).toList(),
            ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
            ),
          SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: isLoading ? null : _uploadBills,
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF9B29C),
                foregroundColor: Color(0xFFF5440E),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFF85D2E), width: 2),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: isLoading
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5440E)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text("Submitting..."),
                ],
              )
                  : Text("Submit"),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAllBillsPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child:Row(
              children: [
                // 📅 Date Box
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedStartDate = picked;
                          });
                          fetchBills();
                        }
                      },
                      icon: Icon(Icons.access_time, color: Colors.black54, size: 18),
                      label: Text(
                        selectedStartDate != null
                            ? "${selectedStartDate!.toLocal()}".split(' ')[0]
                            : "Date",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade400),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // ✅ Status Box
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (BuildContext context) {
                            return ListView(
                              shrinkWrap: true,
                              children: statusOptions.map((status) {
                                return ListTile(
                                  title: Text(status),
                                  onTap: () => Navigator.pop(context, status),
                                );
                              }).toList(),
                            );
                          },
                        );
                        if (result != null) {
                          setState(() => selectedStatus = result);
                          fetchBills();
                        }
                      },
                      icon: Icon(Icons.arrow_drop_down, color: Colors.black54, size: 18),
                      label: Text(
                        selectedStatus ?? "Status",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade400),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // 🔴 Reset Button
                SizedBox(
                  width: 90, // Keep fixed to avoid making it too small
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedStartDate = null;
                        selectedStatus = null;
                      });
                      fetchBills();
                    },
                    child: Text("Reset", style: TextStyle(fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          ),

          // 🔽 List Section
          if (isBillsLoading)
            Center(child: CircularProgressIndicator())
          else if (billsError != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Error: $billsError", style: TextStyle(color: Colors.red)),
            )
          else if (allBills.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("No bills found.", style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: allBills.length,
                itemBuilder: (context, index) {
                  final bill = allBills[index];

                  // Normalize and format status
                  final rawStatus = (bill['status'] ?? 'pending').toString().trim().toLowerCase();
                  final displayStatus = rawStatus[0].toUpperCase() + rawStatus.substring(1);

                  final statusColor = () {
                    switch (rawStatus) {
                      case 'rejected':
                        return Colors.red;
                      case 'approved':
                        return Colors.orange;
                      case 'paid':
                        return Colors.green;
                      case 'pending':
                        return Colors.amber;
                      default:
                        return Colors.grey;
                    }
                  }();

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📄 Left info section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                                  SizedBox(width: 8),
                                  Text(
                                    bill['createdAt']?.toString().split('T')[0] ?? 'N/A',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    bill['amount']?.toString() ?? '0',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, size: 16, color: Colors.deepOrange),
                                  SizedBox(width: 8),
                                  Text(
                                    bill['billType'] ?? '',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.comment, size: 16, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bill['remarks'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),



                        ),
                        Container(
                          height: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    displayStatus,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton(
                                  onPressed: () {
                                    final billImages = bill['billImages'] ?? [];
                                    _showBillImagesPopup(billImages);
                                  },
                                  child: Text(
                                    "View Bills",
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),

                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),


        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Bills"),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0), // shift it left by 12 pixels
              child: TextButton(
                onPressed: () {
                  setState(() {
                    billType = null;
                    remarks = null;
                    selectedImages.clear();
                  });
                  _formKey.currentState?.reset();
                  CustomPopup.showPopup(
                    context,
                    "Form Reset",
                    "Form cleared successfully!",
                    isSuccess: true,
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFB6CAED),
                  side: BorderSide(color: Color(0xFF1A4AA4), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Reset",
                  style: TextStyle(
                    color: Color(0xFF1A4AA4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Upload Bills", 0),
                  SizedBox(width: 100), // Adjust the width to increase/decrease gap
                  _buildTabButton("All Bills", 1),
                ],
              ),
            ),

            SizedBox(height: 20),
            Expanded(
              child: selectedTab == 0 ? _buildUploadForm() : _buildAllBillsPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}
