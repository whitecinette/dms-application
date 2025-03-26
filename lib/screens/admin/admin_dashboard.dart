import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import 'admin_sidebar.dart';
import '../employee/sales_dashboard.dart'; // Import SalesDashboard

class AdminDashboard extends StatelessWidget {
  final dynamic user;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AdminDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: Header(scaffoldKey: _scaffoldKey, user: user),
      drawer: AdminSidebar(user: user),
      body: SalesDashboard(), // Call SalesDashboard directly
    );
  }
}

