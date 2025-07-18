import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:siddhaconnect/services/location_service.dart';

class PunchInOut extends ConsumerStatefulWidget {
  @override
  _PunchInOutState createState() => _PunchInOutState();
}

class _PunchInOutState extends ConsumerState<PunchInOut> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

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
                width: 180, // Bigger circle
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

            // Capture Button (Without Camera Icon)
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

            // Location Display (Latitude & Longitude in a Box)
            isLoading
                ? const CircularProgressIndicator()
                : Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2), // ✅ Only Border
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                location.isNotEmpty ? location : "Location not available",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                if (_image != null && location.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Punch In Successful!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please capture an image and fetch location")),
                  );
                }
              },
              child: const Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
