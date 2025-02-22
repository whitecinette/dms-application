// lib/screens/employee/human_resources/vouchers.dart

import 'package:flutter/material.dart';

class VouchersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vouchers")),
      body: Center(
        child: Text(
          "Welcome to Vouchers!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
