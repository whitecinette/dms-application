import 'dart:convert';
import 'package:dms_app/services/api_service.dart';
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
  bool isLoading = true;

  Map<String, List<Map<String, String>>> hierarchyData = {};

  List<Map<String, String>> smdList = [];
  List<Map<String, String>> asmList = [];
  List<Map<String, String>> mddList = [];
  List<Map<String, String>> tseList = [];
  List<Map<String, String>> dealerList = [];

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
    loadHierarchyFilters();
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = selectedDateRange?.start;
    final endDate = selectedDateRange?.end;

    Map<String, String> queryParams = {
      "metric": isValueSelected ? "value" : "volume",
    };

    if (startDate != null) queryParams["startDate"] = dateFormat.format(startDate);
    if (endDate != null) queryParams["endDate"] = dateFormat.format(endDate);
    if (selectedSMD != null) queryParams["smd"] = selectedSMD!;
    if (selectedASM != null) queryParams["asm"] = selectedASM!;
    if (selectedMDD != null) queryParams["mdd"] = selectedMDD!;
    if (selectedTSE != null) queryParams["tse"] = selectedTSE!;
    if (selectedDealer != null) queryParams["dealer"] = selectedDealer!;

    final uri = Uri.parse("${Config.backendUrl}/get-extraction-report-for-admin")
        .replace(queryParameters: queryParams);

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

  Future<void> loadHierarchyFilters({Map<String, String>? filters}) async {
    try {
      final data = await ApiService.getHierarchyFilters(query: filters);
      print("Hierarchy filter data fetched: $data");

      setState(() {
        smdList = List<Map<String, String>>.from((data['smd'] ?? []).map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        }));

        asmList = List<Map<String, String>>.from((data['asm'] ?? []).map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        }));

        mddList = List<Map<String, String>>.from((data['mdd'] ?? []).map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        }));

        tseList = List<Map<String, String>>.from((data['tse'] ?? []).map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        }));

        dealerList = List<Map<String, String>>.from((data['dealer'] ?? []).map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        }));
      });
    } catch (e) {
      print('Failed to load hierarchy filters: $e');
    }
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

  // Modified buildDropdown for normal string list
  Widget buildDropdown(String label, List<String> items, String? selectedItem, Function(String?) onChanged, {double width = 80, double fontSize = 10,}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

// Modified version for single select with name shown on button + highlight selected card
  Widget buildCodeNameSelector(String label, List<Map<String, String>> items, String? selectedCode, Function(String?) onSelected,) {
    final isSelected = selectedCode != null && selectedCode.isNotEmpty;
    final selectedCount = isSelected ? 1 : 0;

    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                height: 350,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "Select $label",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? ShimmerLoader()
                          : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selected = item['code'] == selectedCode;

                          return Card(
                            color: selected ? Colors.blue.shade100 : Colors.white,
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(item['name'] ?? ""),
                              subtitle: Text(item['code'] ?? ""),
                              trailing: selected
                                  ? Icon(Icons.check_circle, color: Colors.blue)
                                  : null,
                              onTap: () {
                                if (selected) {
                                  onSelected(null);
                                } else {
                                  onSelected(item['code']);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$label${selectedCount > 0 ? ' $selectedCount' : ''}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget buildHeaderCell(String text, {double width = 100}) {
    return Container(
      margin: EdgeInsets.all(2),
      width: width,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // or .visible if you want full text
        softWrap: false,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildCardCell(String text, {Color? background, bool highlight = false}) {
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
          color: highlight ? Colors.black : Colors.grey.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

// Handle selection change for each dropdown
  void onSMDChanged(String? code) {
    setState(() {
      selectedSMD = code;
      selectedASM = null;
      selectedMDD = null;
      selectedTSE = null;
      selectedDealer = null;
    });
    loadHierarchyFilters(filters: code != null ? {'smd': code} : null);
    fetchReport();
  }

  void onASMChanged(String? code) {
    setState(() {
      selectedASM = code;
      selectedMDD = null;
      selectedTSE = null;
      selectedDealer = null;
    });
    loadHierarchyFilters(filters: code != null ? {'asm': code} : null);
    fetchReport();
  }

  void onMDDChanged(String? code) {
    setState(() {
      selectedMDD = code;
      selectedTSE = null;
      selectedDealer = null;
    });
    loadHierarchyFilters(filters: code != null ? {'mdd': code} : null);
    fetchReport();
  }

  void onTSEChanged(String? code) {
    setState(() {
      selectedTSE = code;
      selectedDealer = null;
    });
    loadHierarchyFilters(filters: code != null ? {'tse': code} : null);
    fetchReport();
  }

  void onDealerChanged(String? code) {
    setState(() {
      selectedDealer = code;
    });
    fetchReport();
  }


// Reset all filters
  void resetFilters() {
    setState(() {
      selectedSMD = null;
      selectedASM = null;
      selectedMDD = null;
      selectedTSE = null;
      selectedDealer = null;
    });
    loadHierarchyFilters(); // Load full data
    fetchReport();
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
                      buildCodeNameSelector("SMD", smdList, selectedSMD, onSMDChanged),
                      SizedBox(width: 10),
                      buildCodeNameSelector("ASM", asmList, selectedASM, onASMChanged),
                      SizedBox(width: 10),
                      buildCodeNameSelector("MDD", mddList, selectedMDD, onMDDChanged),
                      SizedBox(width: 10),
                      buildCodeNameSelector("TSE", tseList, selectedTSE, onTSEChanged),
                      SizedBox(width: 10),
                      buildCodeNameSelector("Dealer", dealerList, selectedDealer, onDealerChanged),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: resetFilters,
                        icon: Icon(Icons.refresh, size: 18),
                        label: Text("Reset"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
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
                      // border: TableBorder.all(color: Colors.grey.shade300),
                      children: [
                        TableRow(
                          // decoration: BoxDecoration(color: Colors.blueGrey.shade100),
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
