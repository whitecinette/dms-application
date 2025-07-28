import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';
import '../../config.dart';

class MarketCoverageOverviewScreen extends StatefulWidget {
  const MarketCoverageOverviewScreen({super.key});

  @override
  State<MarketCoverageOverviewScreen> createState() => _MarketCoverageOverviewScreenState();
}

class _MarketCoverageOverviewScreenState extends State<MarketCoverageOverviewScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  List<String> availableRoles = [];
  List<String> selectedRoles = [];
  bool isLoading = false;
  List<Map<String, dynamic>> coverageData = [];

  Future<void> fetchRoles() async {
    final token = await AuthService.getToken();
    final res = await http.get(Uri.parse("${Config.backendUrl}/user/get-subordinate-positions"), headers: {
      'Authorization': 'Bearer $token'
    });

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      availableRoles = List<String>.from(decoded['subordinates']);
      selectedRoles = []; // default empty, backend will fallback to ['asm']
    }
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse("${Config.backendUrl}/admin/get-beat-mapping-overview"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'startDate': DateFormat("yyyy-MM-dd").format(_startDate ?? DateTime.now()),
        'endDate': DateFormat("yyyy-MM-dd").format(_endDate ?? DateTime.now()),
        'positions': selectedRoles
      }),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      coverageData = List<Map<String, dynamic>>.from(decoded['data']);
    }

    setState(() => isLoading = false);
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStart) {
    return TextButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
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
          if (_startDate != null && _endDate != null) {
            fetchData();
          }
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        date != null ? DateFormat('dd MMM').format(date) : label,
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildRoleFilterPopup() {
    final temp = List<String>.from(selectedRoles);
    return IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) => StatefulBuilder(
            builder: (context, setModal) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text("Roles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Spacer(),
                      OutlinedButton(
                        onPressed: () => setModal(() => temp.clear()),
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                  ...availableRoles.map((role) => CheckboxListTile(
                    title: Text(role),
                    value: temp.contains(role),
                    onChanged: (_) => setModal(() {
                      temp.contains(role) ? temp.remove(role) : temp.add(role);
                    }),
                  )),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedRoles = temp;
                      });
                      Navigator.pop(context);
                      fetchData();
                    },
                    child: Text("Apply"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = today;
    _endDate = today;
    fetchRoles().then((_) => fetchData());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = coverageData.where((d) => d['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Market Coverage Overview"),
        actions: [
          IconButton(onPressed: fetchData, icon: Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildDateButton("Start Date", _startDate, true),
                SizedBox(width: 8),
                _buildDateButton("End Date", _endDate, false),
                Spacer(),
                OutlinedButton(
                  onPressed: () {
                    final today = DateTime.now();
                    setState(() {
                      _startDate = today;
                      _endDate = today;
                      _searchQuery = '';
                    });
                    fetchData();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade50,
                  ),
                  child: Text("Reset Filters"),
                )
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text("Roles", style: TextStyle(fontWeight: FontWeight.bold)),
                _buildRoleFilterPopup(),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user['code'], style: TextStyle(fontWeight: FontWeight.bold)),
                              Spacer(),
                              Text(user['position'], style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(user['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStyledChip("Total", user['ovTotal'], user['total'], Colors.orange.shade100, Colors.orange.shade800),
                              _buildStyledChip("Done", user['ovDone'], user['done'], Colors.green.shade100, Colors.green.shade800),
                              _buildStyledChip("Pending", user['ovPending'], user['pending'], Colors.red.shade100, Colors.red.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledChip(String label, int ov, int today, Color bgColor, Color labelColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
          SizedBox(height: 4),
          Text("Overall / Today", style: TextStyle(fontSize: 10, color: Colors.black54)),
          Text("$ov / $today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}