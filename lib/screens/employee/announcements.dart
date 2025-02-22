// lib/screens/employee/announcements.dart

import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Announcements")),
      body: Center(
        child: Text(
          "Welcome to Announcements!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
