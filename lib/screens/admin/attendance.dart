// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class AllAttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Attendance")),
      body: Center(
        child: Text(
          "Welcome to the All Attendance!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
