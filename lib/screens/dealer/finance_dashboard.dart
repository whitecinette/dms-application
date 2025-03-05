// lib/screens/employee/profile.dart

import 'package:flutter/material.dart';

class FinanceDashboardScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Finance DashBoard")),
      body: Center(
        child: Text(
          "Welcome to Finance Dashboard!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
