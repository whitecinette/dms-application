import 'package:siddhaconnect/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:siddhaconnect/utils/responsive.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<dynamic> employees = [];
  List<dynamic> filteredEmployees = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await ApiService.getAllEmployees(page: 1, limit: 20);

      if (response['success']) {
        setState(() {
          employees = response['data'];
          filteredEmployees = employees; // Initialize filtered list
        });
      } else {
        throw Exception(response['message'] ?? "Failed to fetch employees");
      }
    } catch (e) {
      print("Error fetching employees: $e");
    }
  }

  void filterEmployees() {
    setState(() {
      filteredEmployees = employees.where((employee) {
        final name = employee['name']?.toString().toLowerCase() ?? "";
        final position = employee['position']?.toString().toLowerCase() ?? "";
        final code = employee['code']?.toString().toLowerCase() ?? "";

        return name.contains(searchQuery.toLowerCase()) ||
            position.contains(searchQuery.toLowerCase()) ||
            code.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      appBar: AppBar(title: Text("Employee Dashboard")),
      body: employees.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(responsive.width(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Universal Search Bar
            TextField(
              onChanged: (value) {
                searchQuery = value;
                filterEmployees();
              },
              decoration: InputDecoration(
                hintText: "Search employees by name, position, or code...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: responsive.height(12)),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => print("Add Payroll clicked"),
                  child: Text("Add Payroll"),
                ),
                ElevatedButton(
                  onPressed: () => print("Add Employee clicked"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Add Employee"),
                ),
              ],
            ),
            SizedBox(height: responsive.height(16)),

            // Employee Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: responsive.width(20),
                    headingRowHeight: responsive.height(50),
                    dataRowHeight: responsive.height(45),
                    columns: [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Position')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: filteredEmployees.map((employee) {
                      return DataRow(cells: [
                        DataCell(Text(employee['name'] ?? 'N/A')),
                        DataCell(Text(employee['code'] ?? 'N/A')),
                        DataCell(Text(employee['position'] ?? 'N/A')),
                        DataCell(Text(employee['status'] ?? 'N/A')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
