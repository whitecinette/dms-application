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
  bool _isSubmitting = false; // To manage button state
  bool _hasPunchedIn = false; // Track if user has punched in

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Automatically fetch location after capturing image
      await LocationService(ref).getLocation();
    }
  }

  Future<void> _submitPunch() async {
    final location = ref.watch(coordinatesProvider);
    print("Fetched Location: $location");

    if (_image == null || location.isEmpty) {
      print("Image or Location missing!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture an image and fetch location")),
      );
      return;
    }

    List<String> coordinates = location.split(',');
    String latitude = coordinates[0].trim();
    String longitude = coordinates[1].trim();
    print("Parsed Latitude: $latitude, Longitude: $longitude");

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Call API to punch in or punch out
      final response = await ApiService.punchIn(latitude, longitude);
      print("Punch Response: $response");

      if (response.containsKey('status') && response['status'] == 'success') {
        setState(() {
          _hasPunchedIn = !_hasPunchedIn; // Toggle state
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response from server")),
        );
      }
    } catch (error) {
      print("Error during Punch-in: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${error.toString()}")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display Captured Image in a Large Circle
            _image != null
                ? ClipOval(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 3),
                ),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : ClipOval(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.blueAccent, width: 3),
                ),
                child: const Center(
                  child: Text("No Image", style: TextStyle(color: Colors.black54)),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Capture Button
            ElevatedButton(
              onPressed: _captureImage,
              child: Text(
                _image == null ? "Capture" : "Re-Capture",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // Location Display
            isLoading
                ? const CircularProgressIndicator()
                : Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                location.isNotEmpty ? location : "Location not available",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // Punch In / Punch Out Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPunch,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_hasPunchedIn ? "Punch Out" : "Punch In"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasPunchedIn ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
