import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_gate.dart'; // ← Use this instead
import 'screens/employee/extraction.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Add this line
      debugShowCheckedModeBanner: false,
      title: 'Siddha Connect',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
      routes: {
        '/employee/extraction': (context) => ExtractionScreen(), // ✅ Register here
        // Add other routes if needed
      },// ← Here!
    );
  }
}
