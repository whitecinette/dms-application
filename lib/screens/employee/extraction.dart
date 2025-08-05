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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Color(0xFFE0E0E0)),
                        columnSpacing: 20,
                        columns: tableHeaders
                            .map((header) => DataColumn(
                          label: Text(
                            _beautifyHeader(header),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                            .toList(),
                        rows: filteredData
                            .map(
                              (row) => DataRow(
                            cells: tableHeaders
                                .map((header) => DataCell(Text("${row[header] ?? ''}")))
                                .toList(),
                          ),
                        )
                            .toList(),
                      ),
                    ),
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
