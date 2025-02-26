// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class LogoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Logout")),
      body: Center(
        child: Text(
          "Welcome to the Logout!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
