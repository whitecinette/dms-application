import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/shimmer_loader.dart';
import 'package:intl/intl.dart';
import '../../config.dart';

class ExtractionReportScreen extends StatefulWidget {
  @override
  _ExtractionReportScreenState createState() => _ExtractionReportScreenState();
}

class _ExtractionReportScreenState extends State<ExtractionReportScreen> {
  bool isValueSelected = true;
  String? selectedRegion;
  String? selectedASM;
  String? selectedMDD;
  String? selectedTSE;
  String? selectedDealer;

  DateTimeRange? selectedDateRange;
  List<Map<String, dynamic>> tableData = [];
  bool loading = false;

  final List<String> brands = [
    "Samsung",
    "Vivo",
    "Oppo",
    "Xiaomi",
    "Apple",
    "OnePlus",
    "Realme",
    "Motorola",
    "Others",
  ];

  Widget buildHeaderCell(String text, {double width = 100}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget buildCardCell(String text, {Color? background, bool highlight = false}) {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      alignment: Alignment.center,
      color: background ?? Colors.white,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: highlight ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  String getDateRangeText() {
    if (selectedDateRange == null) return "Select Date Range";
    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end;
    return "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}";
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange ??
          DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth),
      helpText: "Select date range",
    );

    if (picked != null) {
      setState(() => selectedDateRange = picked);
      await fetchReport();
    }
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateStr = selectedDateRange != null ? dateFormat.format(selectedDateRange!.start) : null;
    final endDateStr = selectedDateRange != null ? dateFormat.format(selectedDateRange!.end) : null;

    final uri = Uri.parse(
        "${Config.backendUrl}/get-extraction-report-for-admin"
            "?metric=${isValueSelected ? "value" : "volume"}"
            "${startDateStr != null ? "&startDate=$startDateStr" : ""}"
            "${endDateStr != null ? "&endDate=$endDateStr" : ""}"
            "${selectedASM != null ? "&asm=$selectedASM" : ""}"
            "${selectedMDD != null ? "&mdd=$selectedMDD" : ""}"
            "${selectedTSE != null ? "&tse=$selectedTSE" : ""}"
            "${selectedDealer != null ? "&dealer=$selectedDealer" : ""}"
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> data = jsonResponse['data'] ?? [];
        tableData = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        tableData = [];
      }
    } catch (e) {
      tableData = [];
      print("Error: $e");
    }

    setState(() => loading = false);
  }

  Color heatMapColor(double value, double maxValue) {
    if (maxValue == 0) return Colors.white;
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(Colors.white, Colors.deepOrange.shade700, normalized)!;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    selectedDateRange = DateTimeRange(start: firstDay, end: lastDay);
    fetchReport();
  }

  Widget buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return SizedBox(
      width: 83,
      child: DropdownButtonFormField<String>(
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        value: selectedValue,
        style: TextStyle(fontSize: 10),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    for (var row in tableData) {
      for (var brand in brands) {
        final val = row[brand];
        if (val is num && val > maxValue) {
          maxValue = val.toDouble();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Extraction Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickDateRange,
                    icon: Icon(Icons.date_range),
                    label: Text(getDateRangeText()),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Row(
                  children: [
                    Text("Value", style: TextStyle(
                      color: isValueSelected ? Colors.blue : Colors.orange,
                      fontWeight: isValueSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isValueSelected,
                        activeColor: Colors.grey,
                        onChanged: (val) {
                          setState(() => isValueSelected = val);
                          fetchReport();
                        },
                      ),
                    ),
                    Text("Volume", style: TextStyle(
                      color: !isValueSelected ? Colors.blue : Colors.orange,
                      fontWeight: !isValueSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // Region
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Region",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              value: selectedRegion,
              items: ['North', 'South', 'East', 'West'].map((region) =>
                  DropdownMenuItem(value: region, child: Text(region))).toList(),
              onChanged: (value) => setState(() => selectedRegion = value),
            ),
            SizedBox(height: 10),

            // ASM/MDD/TSE/Dealer
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  buildDropdown("asm", ["ASM 1", "ASM 2"], selectedASM, (val) {
                    setState(() => selectedASM = val);
                    fetchReport();
                  }),
                  SizedBox(width: 6),
                  buildDropdown("mdd", ["MDD 1", "MDD 2"], selectedMDD, (val) {
                    setState(() => selectedMDD = val);
                    fetchReport();
                  }),
                  SizedBox(width: 6),
                  buildDropdown("tse", ["TSE 1", "TSE 2"], selectedTSE, (val) {
                    setState(() => selectedTSE = val);
                    fetchReport();
                  }),
                  SizedBox(width: 6),
                  buildDropdown("dealer", ["Dealer A", "Dealer B"], selectedDealer, (val) {
                    setState(() => selectedDealer = val);
                    fetchReport();
                  }),
                ],
              ),
            ),
            SizedBox(height: 14),

            // Table
            Expanded(
              child: loading
                  ? ShimmerLoader() // 👈 Show shimmer when loading
                  : tableData.isEmpty
                  ? Center(child: Text("No data found"))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: FixedColumnWidth(100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.blueGrey.shade100),
                      children: [
                        buildHeaderCell("Price Band"),
                        ...brands.map((b) => buildHeaderCell(b)).toList(),
                        buildHeaderCell("Rank of Samsung", width: 120),
                      ],
                    ),
                    ...tableData.map((row) {
                      return TableRow(
                        children: [
                          buildCardCell(row["Price Class"] ?? "-"),
                          ...brands.map((brand) {
                            final val = row[brand] ?? 0;
                            return buildCardCell(
                              val.toString(),
                              background: heatMapColor(
                                (val is num) ? val.toDouble() : 0,
                                maxValue,
                              ),
                              highlight: (val is num && val > maxValue * 0.7),
                            );
                          }).toList(),
                          buildCardCell(row["Rank of Samsung"]?.toString() ?? "-"),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
