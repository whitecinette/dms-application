// lib/screens/dealer/dealer_dashboard.dart

import 'package:dms_app/screens/dealer/dealer_sidebar.dart';
import 'package:dms_app/screens/dealer/sales_dashboard.dart';
import 'package:dms_app/widgets/header.dart';
import 'package:flutter/material.dart';

class DealerDashboard extends StatelessWidget {
  final dynamic user; // Accepts user data
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DealerDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  key: _scaffoldKey,
      appBar: Header(scaffoldKey: _scaffoldKey, user: user),
      drawer: DealerSidebar(user: user),
      body: SalesDashboardForDealer(),
    );
  }
}
