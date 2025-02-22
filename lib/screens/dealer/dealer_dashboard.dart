// lib/screens/dealer/dealer_dashboard.dart

import 'package:flutter/material.dart';

class DealerDashboard extends StatelessWidget {
  final dynamic user; // Accepts user data

  DealerDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dealer Dashboard")),
      body: Center(
        child: Text(
          "Welcome, ${user['name']}! This is the Dealer Dashboard.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
