import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../widgets/shimmer_loader.dart';

class TabbedTables extends StatefulWidget {
  final String selectedType; // Volume or Value
  final String startDate;
  final String endDate;
  final String token; // User Auth Token

  TabbedTables({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.token,
  });

  @override
  _TabbedTablesState createState() => _TabbedTablesState();
}

class _TabbedTablesState extends State<TabbedTables> {
  String activeTab = "Segment"; // Default active tab
  final List<String> tabs = ["Segment", "Channel"];
  List<String> headers = [];
  List<Map<String, dynamic>> tableData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTableData(); // Initial API call
  }

  Future<void> fetchTableData() async {
    setState(() {
      isLoading = true;
    });

    String reportType = activeTab.toLowerCase(); // segment, channel

    String apiUrl = '${Config.backendUrl}/user/sales-data/report/self';

    Map<String, String> headersRequest = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${widget.token}"
    };

    Map<String, dynamic> body = {
      "start_date": widget.startDate,
      "end_date": widget.endDate,
      "filter_type": widget.selectedType,
      "report_type": reportType
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headersRequest,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          headers = List<String>.from(jsonResponse["headers"]);
          tableData = List<Map<String, dynamic>>.from(jsonResponse["data"]);
        });
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("API Fetch Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.035;

    return Column(
      children: [
        // Tabs
        Container(
          width: double.infinity, // 🔥 Full width of the parent
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Color(0xFFF5F0FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // ⬅️ Distribute tabs evenly
            children: tabs.map((tab) {
              final bool isActive = activeTab == tab;

              return Expanded( // 🧠 Makes each tab take equal width
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      activeTab = tab;
                    });
                    fetchTableData();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )
        ,


        SizedBox(height: 10),

        isLoading
            ? Center(child: ShimmerLoader())
            : _buildTable(headers, tableData, fontSize),
      ],
    );
  }

  Widget _buildTable(List<String> headers, List<Map<String, dynamic>> data, double fontSize) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 50,
                  dataRowHeight: 45,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: headers.map((header) {
                    return DataColumn(
                      label: Text(
                        header,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize * 0.9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  rows: data.map((row) {
                    return DataRow(
                      cells: headers.map((header) {
                        return DataCell(
                          Text(
                            row[header].toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize * 0.85,
                              fontWeight: header == headers.first ? FontWeight.bold : FontWeight.normal,
                              color: header == "% Growth"
                                  ? (double.tryParse(row[header].toString()) ?? 0) > 0
                                  ? Colors.green
                                  : Colors.red
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
