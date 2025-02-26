// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance")),
      body: Center(
        child: Text(
          "Welcome to the Attendance!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
