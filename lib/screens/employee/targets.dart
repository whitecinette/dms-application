// lib/screens/employee/targets.dart

import 'package:flutter/material.dart';

class TargetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Targets")),
      body: Center(
        child: Text(
          "Welcome to Targets!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
