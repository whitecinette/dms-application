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
  String? selectedSMD;
  String? selectedASM;
  String? selectedMDD;
  String? selectedTSE;
  String? selectedDealer;
  String? selectedDistrict;
  String? selectedTaluka;
  String? selectedZone;

  final List<String> districts = ['District A', 'District B', 'District C'];
  final List<String> talukas = ['Taluka 1', 'Taluka 2', 'Taluka 3'];
  final List<String> zones = ['Zone X', 'Zone Y', 'Zone Z'];
  final List<String> brands = [
    "Samsung", "Vivo", "Oppo", "Xiaomi", "Apple",
    "OnePlus", "Realme", "Motorola", "Others",
  ];

  DateTimeRange? selectedDateRange;
  List<Map<String, dynamic>> tableData = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = selectedDateRange?.start;
    final endDate = selectedDateRange?.end;
    final uri = Uri.parse(
      "${Config.backendUrl}/get-extraction-report-for-admin"
          "?metric=${isValueSelected ? "value" : "volume"}"
          "${startDate != null ? "&startDate=${dateFormat.format(startDate)}" : ""}"
          "${endDate != null ? "&endDate=${dateFormat.format(endDate)}" : ""}",
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as List<dynamic>? ?? [];
        tableData = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        tableData = [];
      }
    } catch (e) {
      tableData = [];
    }

    setState(() => loading = false);
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() => selectedDateRange = picked);
      fetchReport();
    }
  }

  String getDateRangeText() {
    if (selectedDateRange == null) return "Select Date Range";
    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end;
    return "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}";
  }

  Color heatMapColor(double value, double maxValue) {
    if (maxValue == 0) return Colors.white;
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(Colors.white, Colors.deepOrange.shade700, normalized)!;
  }

  Widget buildDropdown(
      String label,
      List<String> items,
      String? selectedItem,
      Function(String?) onChanged, {
        double width = 80,
        double fontSize = 10,
      }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1), // reduced vertical padding here
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedItem,
          hint: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),  // reduce padding inside dropdown items too
                child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget buildHeaderCell(String text, {double width = 100}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
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
            // Top filters
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickDateRange,
                    icon: Icon(Icons.date_range),
                    label: Text(getDateRangeText(), style: TextStyle(fontSize: 12)),
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

            // Scroll-safe dropdowns
            // Filters grouped in two rows
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildDropdown("District", districts, selectedDistrict, (val) => setState(() => selectedDistrict = val)),
                      SizedBox(width: 10),
                      buildDropdown("Taluka", talukas, selectedTaluka, (val) => setState(() => selectedTaluka = val)),
                      SizedBox(width: 10),
                      buildDropdown("Zone", zones, selectedZone, (val) => setState(() => selectedZone = val)),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildDropdown("SMD", ["SMD 1", "SMD 2"], selectedSMD, (val) => setState(() => selectedSMD = val)),
                      SizedBox(width: 10),
                      buildDropdown("ASM", ["ASM 1", "ASM 2"], selectedASM, (val) => setState(() => selectedASM = val)),
                      SizedBox(width: 10),
                      buildDropdown("MDD", ["MDD 1", "MDD 2"], selectedMDD, (val) => setState(() => selectedMDD = val)),
                      SizedBox(width: 10),
                      buildDropdown("TSE", ["TSE 1", "TSE 2"], selectedTSE, (val) => setState(() => selectedTSE = val)),
                      SizedBox(width: 10),
                      buildDropdown("Dealer", ["Dealer A", "Dealer B"], selectedDealer, (val) => setState(() => selectedDealer = val)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14),

            // Table section
            Expanded(
              child: loading
                  ? ShimmerLoader()
                  : tableData.isEmpty
                  ? Center(child: Text("No data found"))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    Table(
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
