// lib/screens/employee/pulse.dart

import 'package:flutter/material.dart';

class PulseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pulse")),
      body: Center(
        child: Text(
          "Welcome to Pulse!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
