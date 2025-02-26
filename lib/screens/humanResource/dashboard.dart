// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(" Dashboard")),
      body: Center(
        child: Text(
          "Welcome to the Dashboard!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
