import 'dart:async';
import 'dart:convert';
import 'package:dms_app/main.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';  // import your existing auth_service
import '../screens/login_screen.dart';  // adjust path as needed

class AuthManager {
  static Timer? _logoutTimer;

  static void startTokenExpiryTimer(BuildContext context, String token) {
    _logoutTimer?.cancel();
    print('Starting logout timer...');

    final expiryDate = _getExpiryDateFromToken(token);
    print('Token expiry date: $expiryDate');

    if (expiryDate == null) {
      print('Expiry date null, logging out now');
      logout();
      return;
    }

    final timeToExpiry = expiryDate.difference(DateTime.now());
    print('Time to expiry: $timeToExpiry');

    if (timeToExpiry.isNegative) {
      print('Token expired, logging out now');
      logout();
      return;
    }

    _logoutTimer = Timer(timeToExpiry, () {
      print('Token expired timer fired, logging out');
      logout();
    });
  }


  static DateTime? _getExpiryDateFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = _decodeBase64(parts[1]);
      final Map<String, dynamic> payloadMap = json.decode(payload);

      if (!payloadMap.containsKey('exp')) return null;

      final exp = payloadMap['exp'];
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }
    return utf8.decode(base64Url.decode(output));
  }

  static void logout() async {
    await AuthService.clear();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), // ✅ No context passed
          (route) => false,
    );
  }


  static void cancelTimer() {
    _logoutTimer?.cancel();
  }
}
