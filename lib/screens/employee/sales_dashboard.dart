// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class SalesDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales Dashboard")),
      body: Center(
        child: Text(
          "Welcome to the Sales Dashboard!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
