import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../widgets/sales_filters.dart';
import 'employee_sidebar.dart';
import '../../widgets/filters/filter_date_range.dart';
import '../../widgets/sales_overview.dart';
import '../../widgets/filters/filter_subordinates.dart';
import '../../widgets/tabbed_tables.dart';

class SalesDashboard extends StatefulWidget {
  @override
  _SalesDashboardState createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  String selectedFilter = 'MTD';
  String selectedType = 'Value';

  void updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  void updateType(String type) {
    setState(() {
      selectedType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      // appBar: Header(scaffoldKey: GlobalKey<ScaffoldState>(), user: {'name': 'User', 'role': 'Sales'}),
      drawer: EmployeeSidebar(user: {'name': 'User', 'role': 'Sales'}),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters Row
              SalesFilters(
                onFilterChange: updateFilter,
                onTypeChange: updateType,
              ),

              SizedBox(height: 10),

              // Date Range Selector
              FilterDateRange(
                onDateChange: (DateTime start, DateTime end) {
                  print("Selected Date Range: $start - $end"); // Placeholder for API integration
                },
              ),

              SizedBox(height: 10),

              // Sales Overview Boxes
              SalesOverview(),

              SizedBox(height: 10),

              // Subordinate Filter Row
              FilterSubordinates(),

              SizedBox(height: 10),

              // Tabbed Tables (Segment, Channel, Model)
              TabbedTables(),

              SizedBox(height: 20),

              // Placeholder for future API results
              Center(
                child: Text(
                  "Selected: $selectedFilter - $selectedType",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
