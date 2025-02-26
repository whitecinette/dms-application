// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class PunchInOut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Punch In/Out ")),
      body: Center(
        child: Text(
          "Welcome to the Punch In / Out!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
