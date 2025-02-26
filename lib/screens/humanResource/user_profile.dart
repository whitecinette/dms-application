// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: Center(
        child: Text(
          "Welcome to the User Profile!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
