import 'dart:async';

import 'package:dms_app/screens/employee/sales_dashboard.dart';
import 'package:dms_app/services/api_service.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dms_app/services/location_service.dart';
import 'package:dms_app/utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PunchInOutEmp extends ConsumerStatefulWidget {
  @override
  _PunchInOutState createState() => _PunchInOutState();
}

class _PunchInOutState extends ConsumerState<PunchInOutEmp> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _hasPunchedIn = false;
  bool _isPunchingIn = false;
  bool _isPunchingOut = false;
  String _currentTime = "";
  String _currentDate = "";

  @override
  void initState() {
    super.initState();
    _loadPunchStatus();
    _updateTime();
    Timer.periodic(Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      _currentDate = "${now.day}/${now.month}/${now.year}";
    });
  }

  /// Load the punch-in status from local storage
  Future<void> _loadPunchStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPunchedIn = prefs.getBool('hasPunchedIn') ?? false;
    });
  }

  /// Save the punch-in status to local storage
  Future<void> _savePunchStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasPunchedIn', status);
  }

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await LocationService(ref).getLocation();
    }
  }

  Future<void> _submitPunchIn() async {
    if (_image == null) {
      await _captureImage(); // Automatically open camera if no image
    }

    final location = ref.watch(coordinatesProvider);

    // Re-check if image is still null or location is empty after capture
    if (_image == null || location.isEmpty) {
      CustomPopup.showPopup(
        context,
        "Warning",
        "Please capture an image and fetch location.",
        type: MessageType.warning,
      );
      return;
    }

    List<String> coordinates = location.split(',');
    String latitude = coordinates[0].trim();
    String longitude = coordinates[1].trim();

    setState(() {
      _isPunchingIn = true;
    });

    try {
      final response = await ApiService.punchIn(latitude, longitude, _image!);

      if (response.containsKey('message')) {
        if (response['warning'] == true) {
          CustomPopup.showPopup(
            context,
            "Warning",
            response['message'] ?? "There is a warning.",
            type: MessageType.warning,
          );
        } else {
          setState(() {
            _hasPunchedIn = true;
            _image = null;
          });

          await _savePunchStatus(true);
          ref.read(coordinatesProvider.notifier).state = "";

          CustomPopup.showPopup(
            context,
            "Success",
            response['message'] ?? "You have successfully punched in.",
            isSuccess: true,
          );
        }
      } else {
        CustomPopup.showPopup(
          context,
          "Error",
          response['message'] ?? "Unexpected response",
          isSuccess: false,
        );
      }
    } catch (error) {
      CustomPopup.showPopup(
        context,
        "Error",
        "Something went wrong: ${error.toString()}",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isPunchingIn = false;
      });
    }
  }

  Future<void> _submitPunchOut() async {
    if (_image == null) {
      await _captureImage(); // Automatically open camera if no image
    }

    final location = ref.watch(coordinatesProvider);

    // Re-check if image is still null or location is empty after capture
    if (_image == null || location.isEmpty) {
      CustomPopup.showPopup(
        context,
        "Warning",
        "Please capture an image and fetch location.",
        type: MessageType.warning,
      );
      return;
    }

    List<String> coordinates = location.split(',');
    String latitude = coordinates[0].trim();
    String longitude = coordinates[1].trim();

    setState(() {
      _isPunchingOut = true;
    });

    try {
      final response = await ApiService.punchOut(latitude, longitude, _image!);

      if (response.containsKey('message')) {
        if (response['warning'] == true) {
          CustomPopup.showPopup(
            context,
            "Warning",
            response['message'] ?? "There is a warning.",
            type: MessageType.warning,
          );
        } else {
          setState(() {
            _hasPunchedIn = true;
            _image = null;
          });

          await _savePunchStatus(true);
          ref.read(coordinatesProvider.notifier).state = "";

          CustomPopup.showPopup(
            context,
            "Success",
            response['message'] ?? "You have successfully punched out.",
            isSuccess: true,
          );
        }
      } else {
        CustomPopup.showPopup(
          context,
          "Error",
          response['message'] ?? "Unexpected response",
          isSuccess: false,
        );
      }
    } catch (error) {
      CustomPopup.showPopup(
        context,
        "Error",
        "Something went wrong: ${error.toString()}",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isPunchingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(coordinatesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Punch In/Out"),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date & Time Row
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Spacer(), // Pushes the circle avatar to the center

            // Image Capture Section
            GestureDetector(
              onTap: _captureImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlue.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 90,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  backgroundColor: Colors.white,
                  child: _image == null
                      ? Icon(Icons.person, size: 80, color: Colors.grey[700])
                      : null,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Tap to Capture Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            Spacer(), // Pushes content below the circle down

            // Location or Loading
            isLoading
                ? CircularProgressIndicator()
                : Text(
                    location.isNotEmpty ? location : "Location not available",
                  ),

            SizedBox(height: 20),

            // Punch In/Out Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPunchingIn ? null : _submitPunchIn,
                  icon: Icon(Icons.login),
                  label: _isPunchingIn
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Punch In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(120, 50),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isPunchingOut ? null : _submitPunchOut,
                  icon: Icon(Icons.logout),
                  label: _isPunchingOut
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Punch Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(120, 50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
