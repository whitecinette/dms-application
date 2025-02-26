// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class PayrollScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payroll")),
      body: Center(
        child: Text(
          "Welcome to the Payroll !",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
