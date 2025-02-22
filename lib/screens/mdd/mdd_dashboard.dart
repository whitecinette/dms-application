// lib/screens/mdd/mdd_dashboard.dart

import 'package:flutter/material.dart';

class MddDashboard extends StatelessWidget {
  final dynamic user;

  MddDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MDD Dashboard")),
      body: Center(
        child: Text(
          "Welcome, ${user['name']}! This is the MDD Dashboard.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
