// lib/screens/humanResource/HumanResourceSidebar.dart

import 'package:dms_app/screens/humanResource/actor_code.dart';
import 'package:dms_app/screens/humanResource/attendance.dart';
import 'package:dms_app/screens/humanResource/Hr_beat_mapping.dart';
import 'package:dms_app/screens/humanResource/announcement.dart';
import 'package:dms_app/screens/humanResource/dashboard.dart';
import 'package:dms_app/screens/humanResource/hr_dashboard.dart';
import 'package:dms_app/screens/humanResource/leave_request.dart';
import 'package:dms_app/screens/humanResource/obm.dart';
import 'package:dms_app/screens/humanResource/payroll.dart';
import 'package:dms_app/screens/humanResource/products.dart';
import 'package:dms_app/screens/humanResource/profile.dart';
import 'package:dms_app/screens/humanResource/punch_in_out.dart';
import 'package:dms_app/screens/humanResource/timeline.dart';
import 'package:dms_app/screens/humanResource/tracking.dart';
import 'package:dms_app/screens/humanResource/user_profile.dart';
import 'package:dms_app/screens/humanResource/vouchers.dart';
import 'package:flutter/material.dart';
import '../login_screen.dart'; // For logout

class HumanResourceSidebar extends StatelessWidget {
  final dynamic user;

  HumanResourceSidebar({required this.user});

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
          _buildDrawerItem(Icons.dashboard, "Dashboard", context, HrDashboard(user: user)),
          _buildDrawerItem(Icons.receipt_long, "Vouchers", context, VoucherScreen()),
          _buildDrawerItem(Icons.map, "Beat Mapping", context, BeatMappingScreen()),
          _buildDrawerItem(Icons.timeline, "Timeline", context, TimelineScreen()),
          _buildDrawerItem(Icons.account_balance_wallet, "Payroll", context, PayrollScreen()),
          _buildDrawerItem(Icons.campaign, "Announcement", context, AnnouncementScreen()),

          ExpansionTile(
            leading: Icon(Icons.schedule),
            title: Text("Attendance & Leaves"),
            children: [
              _buildDrawerItem(Icons.location_on, "Tracking", context, TrackingScreen()),
              _buildDrawerItem(Icons.event_available, "Attendance", context, AttendanceScreen()),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.group),
            title: Text("Employee Management"),
            children: [
              _buildDrawerItem(Icons.business, "OBM", context, ObmScreen()),
              _buildDrawerItem(Icons.badge, "Actor Code", context, ActorCodeScreen()),
              _buildDrawerItem(Icons.production_quantity_limits, "Products", context, ProductsScreen()),
              _buildDrawerItem(Icons.person_outline, "User Profile", context, UserProfileScreen()),
            ],
          ),
          _buildDrawerItem(Icons.fingerprint, "Punch In/Out", context, PunchInOut()),
          _buildDrawerItem(Icons.account_circle, "Profile", context, ProfileScreen()),
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
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          _navigateTo(context, screen);
        }
      },
    );
  }
}
