import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../widgets/shimmer_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Add this
import '../providers/sales_filter_provider.dart';

class TabbedTables extends ConsumerStatefulWidget {
  final String selectedType;
  final String startDate;
  final String endDate;
  final String token;

  TabbedTables({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.token,
  });

  @override
  _TabbedTablesState createState() => _TabbedTablesState();
}

class _TabbedTablesState extends ConsumerState<TabbedTables> {

  String activeTab = "Segment"; // Default active tab
  final List<String> tabs = ["Segment", "Channel"];
  List<String> headers = [];
  List<Map<String, dynamic>> tableData = [];
  bool isLoading = false;
  Map<String, List<Map<String, dynamic>>> productDataMap = {};
  String? expandedSegment;
  String? loadingSegment;

  @override
  void initState() {
    super.initState();
    fetchTableData(); // Initial API call
  }

  Future<void> fetchTableData() async {
    setState(() {
      isLoading = true;
    });

    final filterState = ref.read(salesFilterProvider); // 👈 Get selected subordinates

    String reportType = activeTab.toLowerCase();
    String apiUrl = '${Config.backendUrl}/user/sales-data/report/self';

    Map<String, String> headersRequest = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${widget.token}"
    };

    Map<String, dynamic> body = {
      "start_date": widget.startDate,
      "end_date": widget.endDate,
      "filter_type": widget.selectedType,
      "report_type": reportType,
      "subordinate_codes": filterState.selectedSubordinateCodes, // 👈 This line adds the list
    };

    print("📊 TabbedTables sending: $body");

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

  /// Formats a number into a short, readable string.
  /// Examples:
  ///  - 4567   → 4.57K
  ///  - 125000 → 1.25L
  ///  - 34500000 → 3.45Cr
  String formatNumber(dynamic value) {
    if (value == null) return "-";

    String str = value.toString().trim();

    // 🧹 Fix slashes/commas and remove junk
    str = str.replaceAll("\\", ".").replaceAll(",", ".");
    str = str.replaceAll(RegExp(r"[^0-9.\-]"), ""); // only digits, dot, minus

    double? numValue = double.tryParse(str);
    if (numValue == null) return value.toString();

    bool isNegative = numValue < 0;
    numValue = numValue.abs();

    String formatted;
    if (numValue >= 10000000) {
      formatted = "${(numValue / 10000000).toStringAsFixed(2)}Cr";
    } else if (numValue >= 100000) {
      formatted = "${(numValue / 100000).toStringAsFixed(2)}L";
    } else if (numValue >= 1000) {
      formatted = "${(numValue / 1000).toStringAsFixed(2)}K";
    } else {
      formatted = numValue.toStringAsFixed(2);
    }

    // remove trailing .00/.0
    formatted = formatted.replaceAll(RegExp(r"\.0+$"), "");
    formatted = formatted.replaceAll(RegExp(r"(\.\d*?)0+$"), r"\1");

    return isNegative ? "-$formatted" : formatted;
  }



  Future<void> fetchProductWiseData(String segment) async {
    final filterState = ref.read(salesFilterProvider);

    final uri = Uri.parse('${Config.backendUrl}/user/sales-data/product-wise');
    final body = {
      "selected_subords": filterState.selectedSubordinateCodes,
      "filter_type": widget.selectedType,
      "start_date": widget.startDate,
      "end_date": widget.endDate,
      "segment": segment,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}",
      },
      body: jsonEncode(body),
    );

    print("Product RES: ${response}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        productDataMap[segment] = List<Map<String, dynamic>>.from(data["data"]);
      });
      final decoded = jsonDecode(response.body);
      print("✅ Product Data Received: $decoded");
    } else {
      print("❌ Error fetching model data: ${response.body}");
    }
  }


  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.025;

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
    double cellWidth = 80;
    double cellHeight = 40;
    String firstHeader = headers.first;
    List<String> restHeaders = headers.sublist(1);


    // 🔍 Compute per-column min & max
    Map<String, double> maxValues = {};
    Map<String, double> minValues = {};

    for (var header in restHeaders) {
      List<double> values = data.map((row) {
        return double.tryParse(row[header]?.toString() ?? '') ?? 0;
      }).toList();



      if (values.isNotEmpty) {
        maxValues[header] = values.reduce((a, b) => a > b ? a : b);
        minValues[header] = values.reduce((a, b) => a < b ? a : b);
      }
    }

    // 🔥 Cell background color
    Color getCellColor(String header, double value) {
      double maxVal = maxValues[header] ?? 1;
      double minVal = minValues[header] ?? -1;

      if (value == 0) return Colors.red.shade100;

      double ratio = 0;
      if (value > 0 && maxVal > 0) {
        ratio = (value / maxVal).clamp(0.0, 1.0);
        ratio = ratio * ratio;
        return Color.lerp(Colors.green.shade100, Colors.green.shade900, ratio)!;
      } else if (value < 0 && minVal < 0) {
        ratio = (value / minVal).clamp(0.0, 1.0).abs();
        ratio = ratio * ratio;
        return Color.lerp(Colors.red.shade100, Colors.red.shade900, ratio)!;
      }

      return Colors.grey.shade100;
    }

    // 🌗 Font color based on background luminance
    Color getTextColor(Color bg) {
      return bg.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    }

    return Container(
      height: 400,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: cellWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      firstHeader,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                    ),
                  ),
                  ...restHeaders.map((header) => Container(
                    width: cellWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      header,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                    ),
                  )),
                ],
              ),
              SizedBox(height: 8),

              // Data rows
              ...data.map((row) {
                final segmentName = row[firstHeader]?.toString() ?? "";
                final isExpanded = expandedSegment == segmentName;
                final hasProductData = productDataMap[segmentName]?.isNotEmpty == true;
                final productRows = productDataMap[segmentName] ?? [];

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (expandedSegment == segmentName) {
                          setState(() => expandedSegment = null);
                        } else {
                          setState(() {
                            expandedSegment = segmentName;
                            loadingSegment = segmentName; // 🔄 Start loading
                          });
                          await fetchProductWiseData(segmentName);
                          setState(() => loadingSegment = null); // ✅ Done loading
                        }
                      },

                      child: Row(
                        children: [
                          Container(
                            width: cellWidth,
                            height: cellHeight,
                            alignment: Alignment.center,
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  segmentName,
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
                                ),
                                SizedBox(width: 4),
                                if (loadingSegment == segmentName)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                  ),
                              ],
                            ),

                          ),
                          ...restHeaders.map((header) {
                            double val = double.tryParse(row[header]?.toString() ?? "0") ?? 0;
                            Color bg = getCellColor(header, val);
                            Color txtColor = getTextColor(bg);

                            return Container(
                              width: cellWidth,
                              height: cellHeight,
                              alignment: Alignment.center,
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatNumber(
                                  (row[header]?.toString() ?? "").replaceAll("\\", "."),
                                ),
                                style: TextStyle(fontSize: fontSize, color: txtColor),
                              ),


                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    // 🔻 Product dropdown rows
                    if (isExpanded && hasProductData)
                      Container(
                        height: 200,
                        margin: EdgeInsets.only(top: 4, bottom: 12),
                        padding: EdgeInsets.only(top: 4),
                        child: SingleChildScrollView(
                          child: Column(
                            children: productRows.map((product) {
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF9F5FF), // Lavender white
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: cellWidth,
                                      height: cellHeight,
                                      alignment: Alignment.center,
                                      margin: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product[firstHeader]?.toString() ?? "-",
                                        style: TextStyle(fontSize: fontSize * 0.95),
                                      ),
                                    ),
                                    ...restHeaders.map((header) {
                                      double val = double.tryParse(product[header]?.toString() ?? "0") ?? 0;
                                      Color bg = getCellColor(header, val);
                                      Color txtColor = getTextColor(bg);

                                      return Container(
                                        width: cellWidth,
                                        height: cellHeight,
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          formatNumber(product[header]),
                                          style: TextStyle(fontSize: fontSize * 0.95, color: txtColor),
                                        ),

                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),



                  ],
                );
              }).toList(),

              // ➕ Column Totals Row
              Builder(
                builder: (_) {
                  Map<String, dynamic> totals = {};
                  for (var header in restHeaders) {
                    double sum = 0;
                    for (var row in data) {
                      double val = double.tryParse(row[header]?.toString() ?? "0") ?? 0;
                      sum += val;
                    }
                    totals[header] = sum;
                  }

                  return Row(
                    children: [
                      // First column: TOTAL
                      Container(
                        width: cellWidth,
                        height: cellHeight,
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "TOTAL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Rest columns
                      ...restHeaders.map((header) {
                        dynamic displayValue = totals[header];

                        // 🛠 Special case: % Contribution column
                        if (header.toLowerCase().contains("contribution")) {
                          displayValue = 100;
                        }

                        return Container(
                          width: cellWidth,
                          height: cellHeight,
                          alignment: Alignment.center,
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatNumber(displayValue),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),



            ],
          ),
        ),
      ),
    );
  }










}
