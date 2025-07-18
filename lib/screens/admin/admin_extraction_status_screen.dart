import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';
import 'package:siddhaconnect/screens/admin/extraction_status_details.dart';
import '../../config.dart'; // Ensure Config.backendUrl is defined

class ExtractionStatusAdminScreen extends StatefulWidget {
  @override
  _ExtractionStatusAdminScreenState createState() => _ExtractionStatusAdminScreenState();
}

class _ExtractionStatusAdminScreenState extends State<ExtractionStatusAdminScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  List<String> selectedRoles = []; // e.g., ['asm', 'zsm']
  bool showSelfOnly = true;
  Map<String, dynamic>? selfData;
  List<String> availableRoles = [];





  bool isLoading = false;
  List<Map<String, dynamic>> statusData = [];

  Future<void> fetchAvailableRoles() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('${Config.backendUrl}/user/get-subordinate-positions'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          availableRoles = List<String>.from(decoded['subordinates']);
          selectedRoles = List<String>.from(decoded['subordinates']);
        });
      } else {
        print("Role API Error: ${response.body}");
      }
    } catch (e) {
      print("Fetch Exception: $e");
    }
  }

  void _showRoleFilterPopup() {
    final roles = availableRoles;
    final tempSelectedRoles = List<String>.from(selectedRoles); // temp copy

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text("Roles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          setModalState(() => tempSelectedRoles.clear());
                        },
                        child: Text("Clear"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...roles.map((role) => GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (tempSelectedRoles.contains(role)) {
                          tempSelectedRoles.remove(role);
                        } else {
                          tempSelectedRoles.add(role);
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(role),
                          Spacer(),
                          if (tempSelectedRoles.contains(role))
                            Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ),
                  )),

                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close popup
                      setState(() {
                        selectedRoles = tempSelectedRoles;
                      });
                      fetchExtractionStatus(); // fetch with new roles
                    },
                    child: Text("Apply"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentedViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: List.generate(2, (index) {
          final isSelected = showSelfOnly == (index == 1);
          return GestureDetector(
            onTap: () {
              setState(() {
                showSelfOnly = index == 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                index == 0 ? 'All Data' : 'Self',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildSelfCard() {
    if (selfData == null) return Center(child: Text("No self data"));

    final user = selfData!;
    final done = user['done'];
    final pending = user['pending'];
    final total = user['total'];
    final donePercent = int.parse(user['Done Percent'].replaceAll('%', ''));
    final pendingPercent = int.parse(user['Pending Percent'].replaceAll('%', ''));
    final cardWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 12, left: 2, right: 2),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          height: 340,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(user['code'], style: TextStyle(fontWeight: FontWeight.w600)),
                  Spacer(),
                  Text(user['position'], style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 6),

              // Name
              Text(user['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 20),

              // Bars side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Done Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$donePercent%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Done: $done", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      SizedBox(height: 6),
                      Container(
                        width: cardWidth * 0.4,
                        height: (donePercent.toDouble().clamp(12, 100)),
                        decoration: BoxDecoration(
                          color: Color(0xFFC8E6C9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Pending Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("$pendingPercent%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Pending: $pending", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      SizedBox(height: 6),
                      Container(
                        width: cardWidth * 0.4,
                        height: (pendingPercent.toDouble().clamp(12, 100)),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8BBD0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16),
              Text("Total: $total", style: TextStyle(color: Colors.grey[600])),

              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade200),
                    backgroundColor: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExtractionStatusDetailsScreen(
                          userCode: user['code'], // optional param
                          userName: user['name'],  // optional param
                        ),
                      ),
                    );
                  },
                  child: Text("View", style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }









  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });

      // 👇 Fetch data immediately when date changes
      if (_startDate != null && _endDate != null) {
        fetchExtractionStatus();
      }
    }
  }


  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });
  }

  Future<void> fetchExtractionStatus() async {
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();

      final uri = Uri.parse('${Config.backendUrl}/user/extraction-status-role-wise');

      final body = {
        "startDate": DateFormat("yyyy-MM-dd").format(_startDate ?? DateTime.now()),
        "endDate": DateFormat("yyyy-MM-dd").format(_endDate ?? DateTime.now()),
        "roles": selectedRoles,
      };

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          statusData = List<Map<String, dynamic>>.from(decoded["data"]);
          selfData = decoded["selfData"]; // 👈 Add this
        });
      } else {
        print("API Error: ${response.body}");
      }
    } catch (e) {
      print("Fetch Exception: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1); // First day of month
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of month
    fetchAvailableRoles();
    fetchExtractionStatus();
  }


  @override
  Widget build(BuildContext context) {
    final filteredData = statusData.where((e) =>
        e['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Extraction Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchExtractionStatus,
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _buildDateButton("Start date", _startDate, true),
                Text("  to  "),
                _buildDateButton("End date", _endDate, false),
                Spacer(),
                OutlinedButton(
                  onPressed: () {
                    _resetFilters();
                    fetchExtractionStatus();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50, // light orange fill
                    foregroundColor: Colors.black,          // black text
                    side: BorderSide(color: Colors.orange.shade200), // soft orange border
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Reset Filters"),
                )



              ],
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: _showRoleFilterPopup,
              child: Row(
                children: [
                  Text("View by Role"),
                  Icon(Icons.swap_vert),
                  Spacer(),
                  _buildSegmentedViewToggle(),
                ],
              ),

            ),

            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : showSelfOnly
                  ? _buildSelfCard()
                  : filteredData.isEmpty
                  ? Center(child: Text("No data found"))
                  : ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final user = filteredData[index];
                  final int done = user['done'];
                  final int pending = user['pending'];
                  final int total = user['total'];
                  final double doneWidth = 220 * (done / total);
                  final double pendingWidth = 220 * (pending / total);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user['code'], style: TextStyle(fontWeight: FontWeight.w600)),
                              Spacer(),
                              Text(user['position'], style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(user['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 12),

                          // Done bar
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 220,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFDCEDC8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    width: doneWidth,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF81C784),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(user['Done Percent'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text("Done: $done", style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 4),

                          // Pending bar
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 220,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFCDD2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    width: pendingWidth,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE57373),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(user['Pending Percent'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text("Pending: $pending", style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text("Total: $total", style: TextStyle(color: Colors.grey[600])),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.orange.shade200),
                                backgroundColor: Colors.orange.shade50,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExtractionStatusDetailsScreen(
                                      userCode: user['code'],
                                      userName: user['name'],
                                    ),
                                  ),
                                );
                              },
                              child: Text("View", style: TextStyle(color: Colors.black)),
                            ),
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStart) {
    return TextButton(
      onPressed: () => _selectDate(context, isStart),
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
      ),
      child: Text(
        date != null ? DateFormat('dd MMM').format(date) : label,
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
