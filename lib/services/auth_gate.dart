import 'package:siddhaconnect/services/auth_manager.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/dealer/dealer_dashboard.dart';
import '../screens/mdd/mdd_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/humanResource/hr_dashboard.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getToken(),
      builder: (context, tokenSnapshot) {
        if (tokenSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final token = tokenSnapshot.data;
        print('Token in AuthGate: $token');


        if (token == null) {
          return LoginScreen(); // 🔐 No token, go to login
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuthManager.startTokenExpiryTimer(context, token);
          });
        }

        // ✅ Try loading user from shared preferences first
        return FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getUser(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data;

            if (user != null) {
              return _navigateToDashboard(user);
            } else {
              // ✅ If user not found in local storage, call getUserProfile()
              return FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getUserProfile(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!profileSnapshot.hasData ||
                      profileSnapshot.data == null) {
                    return LoginScreen(); // ❌ Token invalid or API failed
                  }

                  final fetchedUser = profileSnapshot.data!['user'];

                  // ✅ Save user to shared preferences for future
                  AuthService.saveUser(fetchedUser);

                  return _navigateToDashboard(fetchedUser);
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _navigateToDashboard(Map<String, dynamic> user) {
    final role = user['role'];

    switch (role) {
      case 'employee':
        return EmployeeDashboard(user: user);
      case 'dealer':
        return DealerDashboard(user: user);
      case 'mdd':
        return MddDashboard(user: user);
      case 'admin':
        return AdminDashboard(user: user);
      case 'hr':
        return HrDashboard(user: user);
      default:
        return LoginScreen();
    }
  }
}
