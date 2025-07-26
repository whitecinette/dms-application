// lib/screens/employee/employee_sidebar.dart

import 'package:siddhaconnect/screens/employee/geo_tag.dart';
import 'package:siddhaconnect/screens/employee/market_coverage.dart';
import 'package:siddhaconnect/screens/employee/punch_in_out_emp.dart';
import 'package:siddhaconnect/screens/employee/route_plan_backup.dart';
import 'package:siddhaconnect/screens/employee/human_resources/travel_schedule.dart';
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
import '../admin/admin_extraction_status_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';



class EmployeeSidebar extends StatelessWidget {
  final dynamic user;
  final allowedPositions = ['smd', 'spd', 'zsm', 'asm', 'tse'];


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
          _buildDrawerItem(LucideIcons.barChart2, "Sales Dashboard", context, SalesDashboard(), iconColor: Colors.blueAccent),
          _buildDrawerItem(LucideIcons.database, "Add Extraction", context, ExtractionScreen(), 	iconColor: Colors.deepPurple, iconSize: 20),
          if (allowedPositions.contains(user['position'])) ...[
            ListTile(
              leading: Icon(LucideIcons.clipboardList, color: Colors.indigo, size: 20),
              title: Text("Extraction Status"),
              onTap: () => _navigateTo(context, ExtractionStatusAdminScreen()),
            ),
          ],
          // _buildDrawerItem(Icons.monitor_heart, "Pulse", context, PulseScreen()),
          // _buildDrawerItem(Icons.map, "Beat Mapping", context, BeatMappingScreen()),
          // _buildDrawerItem(Icons.route, "Route Plan", context, RoutePlanScreen()),
          _buildDrawerItem(	LucideIcons.map, "Route Plan", context, RoutePlanScreen(), iconColor: Colors.green),

          _buildDrawerItem(	LucideIcons.briefcase, "Market Coverage", context, MarketCoverageScreen(), iconColor: 	Colors.deepOrange[400]),
          ExpansionTile(
            leading: Icon(	LucideIcons.building, color: Colors.brown, size: 20),
            title: Text("Human Resources"),
            children: [
              _buildDrawerItem(	LucideIcons.calendarCheck2, "Attendance & Leave", context, AttendanceScreen(), iconColor: Colors.orange),
              _buildDrawerItem(	LucideIcons.fileUp, "Bill Upload", context, BillUploadScreen(), iconColor: Colors.cyan),
              // _buildDrawerItem(Icons.receipt, "Payslip", context, PayslipScreen()),
              // _buildDrawerItem(Icons.card_giftcard, "Vouchers", context, VouchersScreen()),r
            ],
          ),
          // _buildDrawerItem(Icons.flag, "Targets", context, TargetsScreen()),
          // _buildDrawerItem(Icons.campaign, "Announcements", context, AnnouncementsScreen()),
          _buildDrawerItem(	LucideIcons.mapPin, "Geo Tagging", context, GeoTagScreen(), iconColor: Colors.redAccent),
          _buildDrawerItem(	LucideIcons.fingerprint, "Punch In/Out", context, PunchInOutEmp(), iconColor: 	Colors.green[600]),
          _buildDrawerItem(	LucideIcons.user, "Profile", context, ProfileScreen(), iconColor: Colors.brown),

          Divider(),
          _buildDrawerItem(	LucideIcons.logOut, "Logout", context, LoginScreen(), isLogout: true, iconColor: Colors.grey),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Widget screen, {bool isLogout = false, Color? iconColor, double iconSize = 20,}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: iconSize),
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
