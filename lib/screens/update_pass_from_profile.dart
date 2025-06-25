import 'package:dms_app/config.dart';
import 'package:dms_app/screens/employee/profile.dart';
import 'package:dms_app/screens/employee/sales_dash_backup.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePasswordFromProfileScreen extends StatefulWidget {
  const UpdatePasswordFromProfileScreen({super.key});

  @override
  State<UpdatePasswordFromProfileScreen> createState() => _UpdatePasswordFromProfileScreenState();
}

class _UpdatePasswordFromProfileScreenState extends State<UpdatePasswordFromProfileScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      CustomPopup.showPopup(context, "Missing Fields", "Please fill all fields.", isSuccess: false);
      return;
    }

    if (newPass.length < 6) {
      CustomPopup.showPopup(context, "Weak Password", "Password should be at least 6 characters.", isSuccess: false);
      return;
    }

    if (newPass != confirmPass) {
      CustomPopup.showPopup(context, "Mismatch", "Passwords do not match.", isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/change-password"), // ← Update endpoint here
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "oldPassword": oldPass,
          "newPassword": newPass,
        }),
      );

      final data = json.decode(response.body);
      print("Password change response: $data");

      if (response.statusCode == 200) {
        CustomPopup.showPopup(context, "Success", "Password updated successfully", isSuccess: true);

        Future.delayed(Duration(milliseconds: 1000), () {
          Navigator.pop(context); // Close the popup
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
                (route) => false,
          );
        });
      } else {
        CustomPopup.showPopup(context, "Failed", data['message'] ?? "Something went wrong", isSuccess: false);
      }
    } catch (e) {
      CustomPopup.showPopup(context, "Error", e.toString(), isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Password"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Old Password
            TextField(
              controller: _oldPasswordController,
              obscureText: !_isOldPasswordVisible,
              decoration: InputDecoration(
                labelText: "Old Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isOldPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
                ),
              ),
            ),
            SizedBox(height: 16),

            // New Password
            TextField(
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Continue", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
