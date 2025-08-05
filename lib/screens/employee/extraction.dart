import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config.dart';
import '../../widgets/add_extraction_step_one.dart';
import '../../services/auth_gate.dart';
import '../../widgets/unified_extraction_screen.dart';

class ExtractionScreen extends StatefulWidget {
  @override
  _ExtractionScreenState createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  List<String> tableHeaders = [];
  List<Map<String, dynamic>> tableData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;
  String? errorMessage;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExtractionData();
    searchController.addListener(_filterData);
  }

  Future<void> fetchExtractionData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get-extraction-records/month"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (data["success"]) {
        setState(() {
          tableHeaders = List<String>.from(data["headers"]);
          tableData = List<Map<String, dynamic>>.from(data["data"]);
          filteredData = tableData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load extraction records.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
        isLoading = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupDataByDealer() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in filteredData) {
      final dealerCode = row["dealer_code"] ?? "Unknown";
      if (!grouped.containsKey(dealerCode)) {
        grouped[dealerCode] = [];
      }
      grouped[dealerCode]!.add(row);
    }
    return grouped;
  }


  void _filterData() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredData = tableData.where((row) {
        return row.values
            .map((value) => value.toString().toLowerCase())
            .any((value) => value.contains(query));
      }).toList();
    });
  }

  String _beautifyHeader(String header) {
    return header
        .replaceAll("_", " ")
        .split(" ")
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(" ");
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Extraction"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AuthGate()),
                  (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: fetchExtractionData,
          ),
        ],
      ),




      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(10, 10, 10, 80),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : tableData.isEmpty
                ? Center(
              child: Text(
                "No extraction records available.",
                style: TextStyle(fontSize: 16),
              ),
            )
                : Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: _groupDataByDealer().entries.map((entry) {
                      final dealerCode = entry.key;
                      final records = entry.value;
                      final dealerName = records.first['dealer_name'] ?? '';


                      final totalValue = records.fold<double>(0, (sum, row) => sum + (row['total'] ?? 0));
                      final totalUnits = records.fold<int>(0, (sum, row) => sum + ((row['quantity'] ?? 0) as num).toInt());


                      return ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          "$dealerCode - $dealerName",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("₹${totalValue.toStringAsFixed(0)} / $totalUnits units"),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                              headingTextStyle: TextStyle(color: Colors.black),
                              dataRowMinHeight: 32,
                              dataRowMaxHeight: 38,
                              columnSpacing: 12,
                              columns: tableHeaders
                                  .map((header) => DataColumn(
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                  child: Text(
                                    _beautifyHeader(header),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),

                              ))
                                  .toList(),
                              rows: records
                                  .map(
                                    (row) => DataRow(
                                  cells: tableHeaders
                                      .map((header) => DataCell(Text("${row[header] ?? ''}")))
                                      .toList(),
                                ),
                              )
                                  .toList(),
                            ),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UnifiedExtractionScreen()),
                );

                // Only fetch data if extraction was successful (we'll return true from Submit)
                if (result == true) {
                  fetchExtractionData();
                }
              },



              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Add New", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
