// lib/screens/employee/employee_dashboard.dart

import 'package:flutter/material.dart';
import 'employee_sidebar.dart';

class EmployeeDashboard extends StatelessWidget {
  final dynamic user;

  EmployeeDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Dashboard (${user['role']})")),
      drawer: EmployeeSidebar(user: user),
      body: Center(child: Text("Welcome, ${user['name']}!")),
    );
  }
}
