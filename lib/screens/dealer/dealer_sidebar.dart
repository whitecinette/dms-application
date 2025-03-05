// lib/screens/employee/employee_sidebar.dart

import 'package:dms_app/screens/dealer/finance_dashboard.dart';
import 'package:dms_app/screens/employee/punch_in_out_emp.dart';
import 'package:flutter/material.dart';
import 'sales_dashboard.dart';
import 'profile.dart';
import '../login_screen.dart'; // For logout

class DealerSidebar extends StatelessWidget {
  final dynamic user;

  DealerSidebar({required this.user});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], style: TextStyle(color: Colors.white, fontSize: 20)),
                Text(user['role'], style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, "Sales Dashboard", context, SalesDashboardForDealer()),
          _buildDrawerItem(Icons.attach_money, "Finance Dashboard", context, FinanceDashboardScreen()),
          _buildDrawerItem(Icons.person, "Profile", context, ProfileDealerScreen()),
          Divider(),
          _buildDrawerItem(Icons.exit_to_app, "Logout", context, LoginScreen(), isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Widget screen, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to login
          );
        } else {
          _navigateTo(context, screen);
        }
      },
    );
  }
}
