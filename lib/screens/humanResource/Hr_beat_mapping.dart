// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';

class BeatMappingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(" Beat Mapping")),
      body: Center(
        child: Text(
          "Welcome to the Beat Mapping!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
