import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_gate.dart'; // ← Use this instead
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Siddha Connect',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(), // ← Here!
    );
  }
}
