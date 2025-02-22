// lib/screens/employee/profile.dart

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(
        child: Text(
          "Welcome to Profile!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
