// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tracking")),
      body: Center(
        child: Text(
          "Welcome to the Tracking!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
