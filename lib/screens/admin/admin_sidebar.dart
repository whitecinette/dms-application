import 'package:siddhaconnect/screens/admin/admin_extraction_report.dart';
import 'package:siddhaconnect/screens/admin/attendance.dart';
import 'package:siddhaconnect/screens/admin/beat_mapping_status.dart';
import 'package:siddhaconnect/screens/employee/punch_in_out_emp.dart';
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
import '../login_screen.dart';
import '../../services/auth_service.dart';
import 'admin_extraction_status_screen.dart';
import 'package:lucide_icons/lucide_icons.dart'; // 💡 Lucide = clean, flat icon set
import 'interactive_earth_screen.dart';

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

          _buildDrawerItem(LucideIcons.layoutDashboard, "Sales Dashboard", context, SalesDashboard(), color: Colors.blueGrey.shade700),

          ExpansionTile(
            leading: Icon(LucideIcons.pieChart, size: 20, color: Colors.deepPurple.shade600),
            title: Text("Extraction"),
            children: [
              ListTile(
                leading: Icon(LucideIcons.clipboardCheck, size: 20, color: Colors.green.shade700),
                title: Text("Extraction Status"),
                onTap: () => _navigateTo(context, ExtractionStatusAdminScreen()),
              ),
              ListTile(
                leading: Icon(LucideIcons.fileText, size: 20, color: Colors.teal.shade700),
                title: Text("Extraction Report"),
                onTap: () => _navigateTo(context, ExtractionReportPage()),
              ),
            ],
          ),

          _buildDrawerItem(LucideIcons.heartPulse, "Pulse", context, PulseScreen(), color: Colors.red.shade400),
          _buildDrawerItem(LucideIcons.map, "Beat Mapping", context, BeatMappingStatusScreen(), color: Colors.orange.shade700),

          ExpansionTile(
            leading: Icon(LucideIcons.users, size: 20, color: Colors.indigo.shade600),
            title: Text("Human Resources"),
            children: [
              _buildDrawerItem(LucideIcons.calendarCheck, "Attendance", context, AllAttendanceScreen(), color: Colors.purple.shade600),
              _buildDrawerItem(LucideIcons.receipt, "Payslip", context, PayslipScreen(), color: Colors.brown.shade600),
              _buildDrawerItem(LucideIcons.ticket, "Vouchers", context, VouchersScreen(), color: Colors.deepOrange.shade600),
            ],
          ),

          _buildDrawerItem(LucideIcons.target, "Targets", context, TargetsScreen(), color: Colors.teal.shade700),
          _buildDrawerItem(LucideIcons.megaphone, "Announcements", context, AnnouncementsScreen(), color: Colors.green.shade700),
          _buildDrawerItem(LucideIcons.fingerprint, "Punch In/Out", context, PunchInOutEmp(), color: Colors.blueGrey.shade600),
          _buildDrawerItem(
            LucideIcons.globe,
            "3D Earth",
            context,
            InteractiveEarthScreen(),
            color: Colors.lightBlue.shade700,
          ),

          _buildDrawerItem(LucideIcons.user, "Profile", context, ProfileScreen(), color: Colors.grey.shade800),

          Divider(),

          _buildDrawerItem(LucideIcons.logOut, "Logout", context, LoginScreen(), isLogout: true, color: Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Widget screen,
      {bool isLogout = false, Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(title),
      onTap: () async {
        if (isLogout) {
          await AuthService.clear();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        } else {
          _navigateTo(context, screen);
        }
      },
    );
  }
}
