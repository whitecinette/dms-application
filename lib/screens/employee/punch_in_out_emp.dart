import 'package:dms_app/screens/employee/sales_dashboard.dart';
import 'package:dms_app/services/api_service.dart';
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


  @override
  void initState() {
    super.initState();
    _loadPunchStatus();
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
    final location = ref.watch(coordinatesProvider);
    if (_image == null || location.isEmpty) {
      _showPopup("Error", "Please capture an image and fetch location.", false);
      return;
    }

    List<String> coordinates = location.split(',');
    String latitude = coordinates[0].trim();
    String longitude = coordinates[1].trim();

    setState(() {
      _isPunchingIn = true; // Only update this
    });

    try {
      final response = await ApiService.punchIn(latitude, longitude, _image!);
      if (response.containsKey('message')) {
        setState(() {
          _hasPunchedIn = true;
          _image = null;
        });

        await _savePunchStatus(true);
        ref.read(coordinatesProvider.notifier).state = "";
        _showPopup("Success", "You have successfully punched in.", true);
      } else {
        _showPopup("Error", response['message'] ?? "Unexpected response", false);
      }
    } catch (error) {
      _showPopup("Error", "Something went wrong: ${error.toString()}", false);
    } finally {
      setState(() {
        _isPunchingIn = false; // Reset only this
      });
    }
  }

  Future<void> _submitPunchOut() async {
    final location = ref.watch(coordinatesProvider);
    if (_image == null || location.isEmpty) {
      _showPopup("Error", "Please capture an image and fetch location.", false);
      return;
    }

    List<String> coordinates = location.split(',');
    String latitude = coordinates[0].trim();
    String longitude = coordinates[1].trim();

    setState(() {
      _isPunchingOut = true; // Only update this
    });

    try {
      final response = await ApiService.punchOut(latitude, longitude, _image!);
      if (response.containsKey('message')) {
        setState(() {
          _hasPunchedIn = false;
          _image = null;
        });

        await _savePunchStatus(false);
        ref.read(coordinatesProvider.notifier).state = "";
        _showPopup("Success", "You have successfully punched out.", true);
      } else {
        _showPopup("Error", response['message'] ?? "Unexpected response", false);
      }
    } catch (error) {
      _showPopup("Error", "Something went wrong: ${error.toString()}", false);
    } finally {
      setState(() {
        _isPunchingOut = false; // Reset only this
      });
    }
  }


  void _showPopup(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red),
              SizedBox(width: 10),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
            ),
          ],
        );
      },
    );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 90,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  backgroundColor: Colors.grey[300],
                  child: _image == null
                      ? Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey[700])
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon:
                        Icon(Icons.camera, size: 30, color: Colors.blueAccent),
                    onPressed: _captureImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            isLoading
                ? CircularProgressIndicator()
                : Text(
                    location.isNotEmpty ? location : "Location not available"),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ElevatedButton(
                //   onPressed: (!_hasPunchedIn && !_isSubmitting)
                //       ? _submitPunchIn
                //       : null,
                //   child: _isSubmitting && !_hasPunchedIn
                //       ? CircularProgressIndicator(color: Colors.white)
                //       : Text("Punch In"),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: _hasPunchedIn ? Colors.grey : Colors.green,
                //   ),
                // ),
                ElevatedButton(
                  onPressed: _isPunchingIn ? null : _submitPunchIn, // Disable when loading
                  child: _isPunchingIn
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Punch In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),

                SizedBox(width: 10),

                ElevatedButton(
                  onPressed: _isPunchingOut ? null : _submitPunchOut, // Disable when loading
                  child: _isPunchingOut
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Punch Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
