// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Products")),
      body: Center(
        child: Text(
          "Welcome to the Products!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
