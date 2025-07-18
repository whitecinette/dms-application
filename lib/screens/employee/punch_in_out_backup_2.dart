import 'dart:async';

import 'package:siddhaconnect/screens/employee/sales_dashboard.dart';
import 'package:siddhaconnect/services/api_service.dart';
import 'package:siddhaconnect/services/auth_service.dart';
import 'package:siddhaconnect/utils/custom_pop_up.dart';
import 'package:siddhaconnect/utils/dealer_selector_popup.dart';
import 'package:siddhaconnect/utils/leave_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:siddhaconnect/services/location_service.dart';
import 'package:siddhaconnect/utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

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
  String? _userRole;
  String? _selectedDealerCode;
  bool _isSelectingDealerAndPunching = false;

  @override
  void initState() {
    super.initState();
    _loadPunchStatus();
    _loadUserRole();
    _updateTime();
    Timer.periodic(Duration(seconds: 1), (timer) => _updateTime());
  }
  Future<void> _loadUserRole() async {
    final user = await AuthService.getUser();
    if (user != null && user.containsKey('position')) {
      setState(() {
        _userRole = user['position']?.toString().toLowerCase();
      });
    } else {
      print("No position found in user data"); // Debugging line
    }
  }

  void _updateTime() {
    final now = DateTime.now().toLocal(); // Ensure local time (IST if device is set to India)
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    setState(() {
      _currentTime = '$hour:$minute $period';
      _currentDate = '${now.day}/${now.month}/${now.year}';
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

  // Future<void> _submitPunchIn() async {
  //   if (_image == null) {
  //     await _captureImage(); // Automatically open camera if no image
  //   }
  //
  //   setState(() {
  //     _isPunchingIn = true;
  //   });
  //
  //   try {
  //     // ✅ Fetch fresh and accurate location (like in Market Coverage)
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.bestForNavigation,
  //     );
  //
  //     final latitude = position.latitude.toString();
  //     final longitude = position.longitude.toString();
  //
  //     // 🧭 Debug log (optional)
  //     print("📍 Punch In Location: ($latitude, $longitude)");
  //
  //     // ⛔ Double-check image again
  //     if (_image == null) {
  //       CustomPopup.showPopup(
  //         context,
  //         "Warning",
  //         "Image is required. Please try again.",
  //         type: MessageType.warning,
  //       );
  //       setState(() => _isPunchingIn = false); // ✅ FIX
  //       return;
  //     }
  //
  //
  //     final response = await ApiService.punchIn(latitude, longitude, _image!);
  //
  //     if (response.containsKey('message')) {
  //       if (response['warning'] == true || response['statusCode'] == 403) {
  //         CustomPopup.showPopup(
  //           context,
  //           "Warning",
  //           response['message'] ?? "There is a warning.",
  //           type: MessageType.warning,
  //         );
  //       } else {
  //         setState(() {
  //           _hasPunchedIn = true;
  //           _image = null;
  //         });
  //
  //         await _savePunchStatus(true);
  //
  //         CustomPopup.showPopup(
  //           context,
  //           "Success",
  //           response['message'] ?? "You have successfully punched in.",
  //           isSuccess: true,
  //         );
  //       }
  //     } else {
  //       CustomPopup.showPopup(
  //         context,
  //         "Error",
  //         response['message'] ?? "Unexpected response",
  //         isSuccess: false,
  //       );
  //     }
  //   } catch (error) {
  //     CustomPopup.showPopup(
  //       context,
  //       "Error",
  //       "Something went wrong: ${error.toString()}",
  //       isSuccess: false,
  //     );
  //   } finally {
  //     setState(() {
  //       _isPunchingIn = false;
  //     });
  //   }
  // }

  Future<void> _submitPunchIn() async {
    print("🔁 Punch In initiated...");

    if (_image == null) {
      print("📸 No image found. Opening camera...");
      await _captureImage(); // Automatically open camera if no image
    }

    setState(() {
      _isPunchingIn = true;
    });

    try {
      // ✅ Fetch fresh and accurate location
      print("📍 Getting current location...");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final latitude = position.latitude.toString();
      final longitude = position.longitude.toString();
      print("✅ Location fetched: Latitude = $latitude, Longitude = $longitude");

      // ⛔ Re-check image again
      if (_image == null) {
        print("❌ Image still null after capture. Aborting Punch In.");
        CustomPopup.showPopup(
          context,
          "Warning",
          "Image is required. Please try again.",
          type: MessageType.warning,
        );
        setState(() => _isPunchingIn = false);
        return;
      }

      print("📤 Sending Punch In request to API...");
      final response = await ApiService.punchIn(latitude, longitude, _image!);

      print("📥 API Response: $response");

      if (response.containsKey('message')) {
        if (response['warning'] == true || response['statusCode'] == 403) {
          print("⚠️ Warning received: ${response['message']}");
          CustomPopup.showPopup(
            context,
            "Warning",
            response['message'] ?? "There is a warning.",
            type: MessageType.warning,
          );
        } else {
          print("✅ Punch In successful: ${response['message']}");
          setState(() {
            _hasPunchedIn = true;
            _image = null;
          });

          await _savePunchStatus(true);

          CustomPopup.showPopup(
            context,
            "Success",
            response['message'] ?? "You have successfully punched in.",
            isSuccess: true,
          );
        }
      } else {
        print("❌ Unexpected response format: $response");
        CustomPopup.showPopup(
          context,
          "Error",
          response['message'] ?? "Unexpected response",
          isSuccess: false,
        );
      }
    } catch (error) {
      print("🚨 Punch In failed: ${error.toString()}");
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
      print("🧹 Punch In flow complete");
    }
  }


  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: onTap != null ? color : Colors.grey.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Icon(icon, color: Colors.white, size: 25),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }


  Future<void> _submitPunchOut() async {
    if (_image == null) {
      await _captureImage(); // Automatically open camera if no image
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    final latitude = position.latitude.toString();
    final longitude = position.longitude.toString();


    // Re-check if image is still null or location is empty after capture
    if (_image == null) {
      CustomPopup.showPopup(
        context,
        "Warning",
        "Image is required. Please try again.",
        type: MessageType.warning,
      );
      setState(() => _isPunchingIn = false); // ✅ FIX
      return;
    }


    setState(() {
      _isPunchingOut = true; // ✅ Show spinner
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
        }
        setState(() {
          _hasPunchedIn = true;
          _image = null;
          _selectedDealerCode = null;
        });

        await _savePunchStatus(true);
        ref.read(coordinatesProvider.notifier).state = "";

        CustomPopup.showPopup(
          context,
          "Success",
          response['message'] ?? "You have successfully punched out.",
          isSuccess: true,
        );

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

  Future<void> _showDealerSelectionDialog() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    final currentLat = position.latitude.toString();
    final currentLng = position.longitude.toString();


    if (_image == null) {
      CustomPopup.showPopup(
        context,
        "Warning",
        "Image is required. Please try again.",
        type: MessageType.warning,
      );
      setState(() => _isPunchingIn = false); // ✅ FIX
      return;
    }


    setState(() {
      _isSelectingDealerAndPunching = true;
    });

    try {
      final selectedDealerCode = await showDealerSelectionDialog(context);
      if (selectedDealerCode != null) {
        print("Selected Dealer: $selectedDealerCode");
        setState(() {
          _selectedDealerCode = selectedDealerCode;
        });

        await _submitPunchOut();
      }
    } catch (e) {
      CustomPopup.showPopup(
        context,
        "Error",
        "Something went wrong: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSelectingDealerAndPunching = false;
      });
    }
  }
  void _openLeaveFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Leave'),
          content: LeaveForm(
            onSubmit: (formData) {
              print('Leave requested: $formData');
            },
          ),
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
        title: Text("Punch In / Out"),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh Page",
            onPressed: () {
              setState(() {
                _image = null;
                _hasPunchedIn = false;
                _selectedDealerCode = null;
                ref.read(coordinatesProvider.notifier).state = "";
                _loadUserRole();
                _loadPunchStatus();
                _updateTime();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Date & Time
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _currentDate,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _currentTime,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

// Location Box (moved here, with same height & style as date/time box)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.redAccent),
                          SizedBox(width: 15),
                          Expanded(
                            child: isLoading
                                ? Center(child: CircularProgressIndicator())
                                : Text(
                              location.isNotEmpty ? location : "Location not available",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // font weight & size same as date/time text
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    if (_selectedDealerCode != null) ...[
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: Colors.deepOrange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Selected Dealer: $_selectedDealerCode",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 80),
                    // Centered Image Capture
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.lightBlueAccent],
                              begin: Alignment.center,
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
                            radius: 80,
                            backgroundColor: Colors.white,
                            backgroundImage: _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? Icon(Icons.camera_alt, size: 60, color: Colors.grey[700])
                                : null,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),
                    Text(
                      'Tap above to capture image',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            // Punch Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Punch In Button
                _buildCircleButton(
                  icon: Icons.fingerprint,
                  label: "Check In",
                  color: Colors.green,
                  onTap: _isPunchingIn ? null : _submitPunchIn,
                  isLoading: _isPunchingIn,
                ),

                // Punch Out Button
                _buildCircleButton(
                  icon: Icons.login_rounded,
                  label: "Check Out",
                  color: Colors.red,
                  onTap: _isPunchingOut
                      ? null
                      : () {
                    if (_selectedDealerCode != null) {
                      CustomPopup.showPopup(
                        context,
                        "Warning",
                        "Please deselect the dealer before punching out.",
                        type: MessageType.warning,
                      );
                    } else {
                      _submitPunchOut();
                    }
                  },
                  isLoading: _isPunchingOut,
                ),

                // Request Leave Button
                _buildCircleButton(
                  icon: Icons.work_off,
                  label: "Request Leave",
                  color: Colors.deepOrangeAccent,
                  onTap: () {
                    _openLeaveFormDialog(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }



}


