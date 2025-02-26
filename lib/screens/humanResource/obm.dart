// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class ObmScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Outlet Beat Mapping")),
      body: Center(
        child: Text(
          "Welcome to the Outlet Beat Mapping!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
