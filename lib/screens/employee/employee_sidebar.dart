// lib/screens/employee/employee_sidebar.dart

import 'package:dms_app/screens/employee/geo_tag.dart';
import 'package:dms_app/screens/employee/market_coverage.dart';
import 'package:dms_app/screens/employee/punch_in_out_emp.dart';
import 'package:dms_app/screens/employee/route_plan.dart';
import 'package:dms_app/screens/employee/human_resources/travel_schedule.dart';
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
import '../../services/auth_service.dart';

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
            decoration: BoxDecoration(color: Colors.blue.shade900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? '',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  "${user['code'] ?? ''} | ${user['role'] ?? ''}",
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              ],

            ),
          ),
          _buildDrawerItem(Icons.dashboard, "Sales Dashboard", context, SalesDashboard()),
          _buildDrawerItem(Icons.pie_chart, "Extraction", context, ExtractionScreen()),
          _buildDrawerItem(Icons.monitor_heart, "Pulse", context, PulseScreen()),
          _buildDrawerItem(Icons.map, "Beat Mapping", context, BeatMappingScreen()),
          _buildDrawerItem(Icons.route, "Route Plan", context, RoutePlanScreen()),
          _buildDrawerItem(Icons.travel_explore, "Market Coverage", context, MarketCoverageScreen()),
          ExpansionTile(
            leading: Icon(Icons.people),
            title: Text("Human Resources"),
            children: [
              _buildDrawerItem(Icons.event, "Attendance & Leave", context, AttendanceScreen()),
              _buildDrawerItem(Icons.upload_file, "Bill Upload", context, BillUploadScreen()),
              _buildDrawerItem(Icons.receipt, "Payslip", context, PayslipScreen()),
              _buildDrawerItem(Icons.card_giftcard, "Vouchers", context, VouchersScreen()),
            ],
          ),
          _buildDrawerItem(Icons.flag, "Targets", context, TargetsScreen()),
          _buildDrawerItem(Icons.campaign, "Announcements", context, AnnouncementsScreen()),
          _buildDrawerItem(Icons.map, "Geo Tagging", context, GeoTagScreen()),
          _buildDrawerItem(Icons.fingerprint, "Punch In/Out", context, PunchInOutEmp()),
          _buildDrawerItem(Icons.account_circle, "Profile", context, ProfileScreen()),
          Divider(),
          _buildDrawerItem(Icons.logout, "Logout", context, LoginScreen(), isLogout: true),
          SizedBox(height: 60),
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
          await AuthService.clear();
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
