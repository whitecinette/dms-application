// lib/screens/employee/employee_sidebar.dart

import 'package:dms_app/screens/employee/punch_in_out_emp.dart';
import 'package:flutter/material.dart';
import '../employee/sales_dashboard.dart';
import '../employee/extraction.dart';
import '../employee/pulse.dart';
import '../employee/beat_mapping.dart';
import '../employee/human_resources/attendance.dart';
import '../employee/human_resources/payslip.dart';
import '../employee/human_resources/vouchers.dart';
import '../employee/targets.dart';
import '../employee/announcements.dart';
import '../employee/profile.dart';
import '../login_screen.dart'; // For logout
import '../../services/auth_service.dart';

class AdminSidebar extends StatelessWidget {
  final dynamic user;

  AdminSidebar({required this.user});

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
          _buildDrawerItem(Icons.campaign, "Punch In/Out", context, PunchInOutEmp()),

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
      onTap: () async {
        if (isLogout) {
          await AuthService.clear(); // ✅ Only clear on logout
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          _navigateTo(context, screen);
        }
      },
    );
  }

}
