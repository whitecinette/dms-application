import 'package:dms_app/screens/employee/sales_dashboard.dart';
import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dms_app/services/location_service.dart';

class PunchInOutEmp extends ConsumerStatefulWidget {
  @override
  _PunchInOutState createState() => _PunchInOutState();
}

class _PunchInOutState extends ConsumerState<PunchInOutEmp> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _hasPunchedIn = false;

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
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.punchIn(latitude, longitude, _image!);
      if (response.containsKey('message')) {
        setState(() {
          _hasPunchedIn = true;
          _image = null;
        });

        ref.read(coordinatesProvider.notifier).state = "";

        _showPopup("Success", "You have successfully punched in.", true);

        // Navigate to SalesDashboard after success
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SalesDashboard()),
          );
        });
      } else {
        _showPopup("Error", response['message'] ?? "Unexpected response", false);
      }
    } catch (error) {
      _showPopup("Error", "Something went wrong: ${error.toString()}", false);
    } finally {
      setState(() {
        _isSubmitting = false;
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
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.punchOut(latitude, longitude, _image!);
      if (response.containsKey('message') &&
          response['message'] == "Punch-out recorded successfully") {
        setState(() {
          _hasPunchedIn = false;
          _image = null;
        });

        ref.read(coordinatesProvider.notifier).state = "";

        _showPopup("Success", "You have successfully punched out.", true);

        // Navigate to SalesDashboard after success
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SalesDashboard()),
          );
        });
      } else {
        _showPopup("Error", response['message'] ?? "Unexpected response", false);
      }
    } catch (error) {
      _showPopup("Error", "Something went wrong: ${error.toString()}", false);
    } finally {
      setState(() {
        _isSubmitting = false;
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
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: Colors.blueAccent)),
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
        title: const Text("Punch In/Out"),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? CircleAvatar(radius: 90, backgroundImage: FileImage(_image!))
                : CircleAvatar(
              radius: 90,
              backgroundColor: Colors.grey[300],
              child: Text("No Image"),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _captureImage,
              child: Text(_image == null ? "Capture" : "Re-Capture"),
            ),
            SizedBox(height: 30),
            isLoading
                ? CircularProgressIndicator()
                : Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent)),
              child: Text(location.isNotEmpty
                  ? location
                  : "Location not available"),
            ),
            SizedBox(height: 20),

            // Punch In Button (Enabled initially, disabled after punch in)
            ElevatedButton(
              onPressed: (!_hasPunchedIn && !_isSubmitting) ? _submitPunchIn : null,
              child: _isSubmitting && !_hasPunchedIn
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Punch In"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasPunchedIn ? Colors.grey : Colors.green,
              ),
            ),

            SizedBox(height: 10),

            // Punch Out Button (Disabled initially, enabled after punch in)
            ElevatedButton(
              onPressed: (_hasPunchedIn && !_isSubmitting) ? _submitPunchOut : null,
              child: _isSubmitting && _hasPunchedIn
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Punch Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasPunchedIn ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
