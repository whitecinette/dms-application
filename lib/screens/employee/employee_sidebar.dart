// lib/screens/employee/employee_sidebar.dart

import 'package:flutter/material.dart';
import 'sales_dashboard.dart';
import 'extraction.dart';
import 'pulse.dart';
import 'beat_mapping.dart';
import 'human_resources/attendance.dart';
import 'human_resources/payslip.dart';
import 'human_resources/vouchers.dart';
import 'targets.dart';
import 'announcements.dart';
import 'profile.dart';
import '../login_screen.dart'; // For logout

class EmployeeSidebar extends StatelessWidget {
  final dynamic user;

  EmployeeSidebar({required this.user});

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
          _buildDrawerItem(Icons.dashboard, "Sales Dashboard", context, SalesDashboard()),
          _buildDrawerItem(Icons.pie_chart, "Extraction", context, ExtractionScreen()),
          _buildDrawerItem(Icons.monitor_heart, "Pulse", context, PulseScreen()),
          _buildDrawerItem(Icons.map, "Beat Mapping", context, BeatMappingScreen()),
          ExpansionTile(
            leading: Icon(Icons.people),
            title: Text("Human Resources"),
            children: [
              _buildDrawerItem(Icons.event, "Attendance", context, AttendanceScreen()),
              _buildDrawerItem(Icons.receipt, "Payslip", context, PayslipScreen()),
              _buildDrawerItem(Icons.card_giftcard, "Vouchers", context, VouchersScreen()),
            ],
          ),
          _buildDrawerItem(Icons.flag, "Targets", context, TargetsScreen()),
          _buildDrawerItem(Icons.campaign, "Announcements", context, AnnouncementsScreen()),
          _buildDrawerItem(Icons.person, "Profile", context, ProfileScreen()),
          Divider(),
          _buildDrawerItem(Icons.logout, "Logout", context, LoginScreen(), isLogout: true),
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
