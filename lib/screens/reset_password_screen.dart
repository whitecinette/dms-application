import 'package:dms_app/config.dart';
import 'package:dms_app/screens/login_screen.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _fieldError;

  Future<void> _checkAndResetPassword() async {
    final code = _codeController.text.trim();
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (code.isEmpty || oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      CustomPopup.showPopup(context, "Missing Fields", "Please fill all the fields.", isSuccess: false);
      return;
    }

    if (newPass != confirmPass) {
      CustomPopup.showPopup(context, "Password Mismatch", "New password and confirm password do not match.", isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("${Config.backendUrl}/reset-pass-for-app");

      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "code": code,
          "oldPassword": oldPass,
          "newPassword": newPass,
        }),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print("⚠️ JSON Decode Error: $e");
        data = null;
      }

      if (response.statusCode == 200) {
        CustomPopup.showPopup(context, "Success", "Password updated successfully", isSuccess: true);

        Future.delayed(Duration(milliseconds: 1000), () {
          Navigator.pop(context); // Close the popup
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
          );
        });
      }
      else if (response.statusCode == 401 && data?['askOtp'] == true) {
        _showOtpPromptDialog();
      } else {
        CustomPopup.showPopup(
          context,
          "Reset Failed",
          data?['message'] ?? "Something went wrong",
          isSuccess: false,
        );
      }
    }


    catch (e) {
      CustomPopup.showPopup(context, "Error", e.toString(), isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOtpPromptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Incorrect Password"),
        content: Text("Old password is incorrect. Do you want to continue with OTP verification?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              CustomPopup.showPopup(context, "OTP Verification", "OTP flow started", isSuccess: true);
              // TODO: Navigate to OTP screen
            },
            child: Text("Continue with OTP"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Reset Password", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/company-logo.png", width: 250, height: 100),
                SizedBox(height: 20),

                // User Code
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters, // 👈 Force uppercase
                  decoration: InputDecoration(
                    labelText: "Code",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                SizedBox(height: 15),

                // Old Password
                TextField(
                  controller: _oldPasswordController,
                  obscureText: !_isOldPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Old Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_isOldPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isOldPasswordVisible = !_isOldPasswordVisible);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // New Password
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Error message
                if (_fieldError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _fieldError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkAndResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(255, 61, 0, 0.8),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
