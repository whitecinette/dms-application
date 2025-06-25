import 'package:dms_app/config.dart';
import 'package:dms_app/screens/update_pass_from_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    print("enterrring fetch profile");
    try {
      final url = Uri.parse("${Config.backendUrl}/user/get-profile");
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        setState(() {
          userData = jsonBody['user'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Failed to load profile: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // default is true anyway
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Edit profile coming soon...")),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(child: Text("No profile data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.indigo.shade100,
              child: Icon(Icons.person, size: 50, color: Colors.indigo.shade400),
            ),
            SizedBox(height: 20),

            // Dynamically display user data
            ..._buildProfileFields(userData!),

            SizedBox(height: 30),

            // Reset Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UpdatePasswordFromProfileScreen()),
                    );

                    if (result == true) {
                      fetchProfile(); // reload profile
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password updated successfully")));
                    }
                  },
                  icon: Icon(Icons.lock_reset),
                label: Text("Reset Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProfileFields(Map<String, dynamic> data) {
    final fieldIcons = {
      'code': Icons.badge,
      'name': Icons.person,
      'email': Icons.email,
      'role': Icons.work,
      'phone': Icons.phone,
      'department': Icons.account_tree,
    };

    return fieldIcons.entries.map((entry) {
      final value = data[entry.key] ?? '—';
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(entry.value, color: Colors.orange),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
