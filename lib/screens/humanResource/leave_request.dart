// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class LeaverequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leave Request")),
      body: Center(
        child: Text(
          "Welcome to the Leave Request!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
