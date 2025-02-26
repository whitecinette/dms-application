// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class AnnouncementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Announcement")),
      body: Center(
        child: Text(
          "Welcome to the Announcement!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
