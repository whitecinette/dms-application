import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrader/upgrader.dart';
import 'services/auth_gate.dart';
import 'screens/employee/extraction.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      navigatorKey: navigatorKey,
      dialogStyle: UpgradeDialogStyle.material, // choose Material or Cupertino
      barrierDismissible: false,                 // must tap a button to close
      shouldPopScope: () => false,              // disable Android back button
      upgrader: Upgrader(
        debugLogging: true,            // helpful while testing
        debugDisplayAlways: false,      // show dialog even if no update
        minAppVersion: '1.0.7',        // enforce update if installed version < this
      ),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Siddha Connect',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthGate(),
        routes: {
          '/employee/extraction': (_) => ExtractionScreen(),
        },
      ),
    );
  }
}
