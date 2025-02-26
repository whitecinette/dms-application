// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class ActorCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Actor Codes")),
      body: Center(
        child: Text(
          "Welcome to the Actor Codes!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
