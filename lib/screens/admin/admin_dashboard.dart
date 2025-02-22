// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final dynamic user;

  AdminDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Center(
        child: Text(
          "Welcome, ${user['name']}! This is the Admin Dashboard.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
