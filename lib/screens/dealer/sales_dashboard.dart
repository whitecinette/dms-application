// lib/screens/employee/profile.dart

import 'package:flutter/material.dart';

class SalesDashboardForDealer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales DashBoard")),
      body: Center(
        child: Text(
          "Welcome to Sales Dashboard!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
