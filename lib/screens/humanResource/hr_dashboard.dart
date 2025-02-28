import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dms_app/screens/humanResource/hr_sidebar.dart';

class HrDashboard extends StatelessWidget {
  final dynamic user;

  HrDashboard({required this.user});

  final int totalEmployees = 100;
  final int totalPresent = 60;
  final int totalAbsent = 30;
  final int totalLeave = 10;

  final List<Map<String, String>> employees = [
    {"sno": "1", "name": "John Doe", "designation": "Manager", "checkin": "9:00 AM"},
    {"sno": "2", "name": "Jane Smith", "designation": "HR", "checkin": "9:15 AM"},
    {"sno": "3", "name": "Sam Wilson", "designation": "Developer", "checkin": "9:30 AM"},
    {"sno": "4", "name": "Emma Johnson", "designation": "Designer", "checkin": "9:45 AM"},
    {"sno": "5", "name": "Michael Brown", "designation": "Accountant", "checkin": "10:00 AM"},
  ];

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text("Hr Dashboard (${user['role']})")),
      drawer: HumanResourceSidebar(user: user),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildAttendanceCard(todayDate),
            SizedBox(height: 20),
            _buildPieChartSection(),
            SizedBox(height: 20),
            _buildWhatsUpToday(),
            SizedBox(height: 10),
            _buildEmployeeTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(String todayDate) {
    return Card(
      color: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todayDate,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[800], // Dark Blue Background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Check-in Time",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "--:-- AM",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10), // Space between the boxes
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[800], // Dark Blue Background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Check-out Time",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "--:-- PM",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPieChartSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 350;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: isSmallScreen ? 1.2 : 1.5,
                    child: PieChart(
                      PieChartData(
                        sections: _generatePieSections(),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 1,
                        centerSpaceRadius: isSmallScreen ? 20 : 30,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 5 : 10),
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegend(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    return [
      _pieSection(totalEmployees, "Employees", Colors.blue),
      _pieSection(totalPresent, "Present", Colors.green),
      _pieSection(totalAbsent, "Absent", Colors.red),
      _pieSection(totalLeave, "Leave", Colors.orange),
    ];
  }

  PieChartSectionData _pieSection(int value, String title, Color color) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: "$value", // Showing number instead of percentage
      radius: 40,
      titleStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  List<Widget> _buildLegend() {
    return [
      _legendItem("Total Employees", Colors.blue, totalEmployees),
      _legendItem("Present", Colors.green, totalPresent),
      _legendItem("Absent", Colors.red, totalAbsent),
      _legendItem("Leave", Colors.orange, totalLeave),
    ];
  }

  Widget _legendItem(String title, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 6),
          Text("$title: $value", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String time) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 3),
            Text(time, style: TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsUpToday() {
    return Center(
      child: Text("What's up today?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmployeeTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10, // Reduced spacing
          columns: [
            DataColumn(label: Text("S.No", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Designation", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Check-in Time", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: employees.map((emp) {
            return DataRow(cells: [
              DataCell(Text(emp["sno"]!)),
              DataCell(Text(emp["name"]!)),
              DataCell(Text(emp["designation"]!)),
              DataCell(Text(emp["checkin"]!)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
