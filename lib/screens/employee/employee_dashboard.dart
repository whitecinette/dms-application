import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import 'employee_sidebar.dart';
import 'sales_dashboard.dart'; // Import SalesDashboard

class EmployeeDashboard extends StatelessWidget {
  final dynamic user;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  EmployeeDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: EmployeeSidebar(user: user),
      body: SalesDashboard(), // Call SalesDashboard directly
    );
  }
}
