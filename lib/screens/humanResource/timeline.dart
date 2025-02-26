// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timeline")),
      body: Center(
        child: Text(
          "Welcome to the Timeline!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
