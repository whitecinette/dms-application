// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class VoucherScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vouchers")),
      body: Center(
        child: Text(
          "Welcome to the Vouchers!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
