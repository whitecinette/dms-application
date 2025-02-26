// lib/screens/employee/employee_dashboard.dart

import 'package:dms_app/screens/humanResource/hr_sidebar.dart';
import 'package:flutter/material.dart';

class HrDashboard extends StatelessWidget {
  final dynamic user;

  HrDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hr Dashboard (${user['role']})")),
      drawer: HumanResourceSidebar(user: user),
      body: Center(child: Text("Welcome, ${user['name']}!")),
    );
  }
}
