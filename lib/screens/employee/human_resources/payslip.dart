// lib/screens/employee/human_resources/payslip.dart

import 'package:flutter/material.dart';

class PayslipScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payslip")),
      body: Center(
        child: Text(
          "Welcome to Payslip!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
