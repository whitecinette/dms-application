// lib/screens/employee/human_resources/attendance.dart

import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance")),
      body: Center(
        child: Text(
          "Welcome to Attendance!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
