import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sales_filter_provider.dart';
import '../../widgets/header.dart';
import '../../widgets/sales_filters.dart';
import '../../widgets/filters/filter_date_range.dart';
import '../../widgets/sales_overview.dart';
import '../../widgets/filters/filter_subordinates.dart';
import '../../widgets/tabbed_tables.dart';
import '../../services/auth_service.dart';
import 'employee_sidebar.dart';

class SalesDashboard extends ConsumerStatefulWidget {
  @override
  _SalesDashboardState createState() => _SalesDashboardState();
}

class _SalesDashboardState extends ConsumerState<SalesDashboard> {
  String userToken = "";
  String selectedFilter = 'MTD';


  @override
  void initState() {
    super.initState();
    loadUserToken();
  }

  void loadUserToken() async {
    String? token = await AuthService.getToken();
    if (token != null) {
      setState(() {
        userToken = token;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(salesFilterProvider);
    final filterNotifier = ref.read(salesFilterProvider.notifier);

    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      drawer: EmployeeSidebar(user: {'name': 'User', 'role': 'Sales'}),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SalesFilters(
                onFilterChange: (filter) {
                  setState(() => selectedFilter = filter);
                },
                onTypeChange: filterNotifier.updateType,
                selectedFilter: selectedFilter,
                selectedType: filterState.selectedType,
              ),
              SizedBox(height: 10),
              FilterDateRange(
                initialStartDate: filterState.startDate,
                initialEndDate: filterState.endDate,
                onDateChange: filterNotifier.updateDateRange,
              ),
              SizedBox(height: 10),

              // 🧩 Key ensures rebuild when hierarchy changes
              // 🧩 Unique keys to avoid duplicate 'root'
              SalesOverview(
                key: ValueKey('overview_${filterState.selectedHierarchyCode ?? "root"}'),
                token: userToken,
              ),

              SizedBox(height: 10),
              FilterSubordinates(),
              SizedBox(height: 10),

              // 🧩 Key ensures TabbedTables refresh too
              // 🧩 Unique key for TabbedTables too
              TabbedTables(
                key: ValueKey('tables_${filterState.selectedHierarchyCode ?? "root"}'),
                selectedType: filterState.selectedType,
                startDate: filterState.startDate.toIso8601String().split("T")[0],
                endDate: filterState.endDate.toIso8601String().split("T")[0],
                token: userToken,
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}
