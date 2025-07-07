import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config.dart';
import '../../services/auth_service.dart';


class ExtractionReportPage extends StatefulWidget {
  @override
  _ExtractionReportPageState createState() => _ExtractionReportPageState();
}

class _ExtractionReportPageState extends State<ExtractionReportPage> {
  List<bool> valueVolumeToggle = [true, false];
  List<bool> shareDefaultToggle = [false, true];
  Map<String, String> totalRow = {};
  List<Map<String, dynamic>> subordinate = [];
  List<String> positionLevels = [];
  List<Map<String, dynamic>> dropdownValue = []; // [{code, name, position}]
  Map<String, List<Map<String, dynamic>>> selectedActorsByPosition = {};




  int selectedMetric = 0;
  int selectedView = 1;

  List<Map<String, dynamic>> tableData = [];
  List<String> tableHeaders = [];
  bool loading = false;

  DateTimeRange? selectedDateRange;
  String? selectedSMD;
  String? selectedASM;
  String? selectedMDD;
  String? selectedTSE;
  String? selectedDealer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    selectedDateRange = DateTimeRange(start: firstDay, end: lastDay);
    fetchHierarchy(); // <-- NEW
    fetchReport();
  }

  Widget _dateButton(String label) {
    return ElevatedButton(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: selectedDateRange,
          firstDate: DateTime(2023),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            selectedDateRange = picked;
          });
          fetchReport(); // Refresh data on selection
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: const Size(10, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(
        label == "Start date"
            ? DateFormat('dd MMM').format(selectedDateRange?.start ?? DateTime.now())
            : DateFormat('dd MMM').format(selectedDateRange?.end ?? DateTime.now()),
      ),
    );
  }


  Future<void> fetchHierarchy() async {
    try {
      final Map<String, List<String>> positionCodes = {};
      for (final item in dropdownValue) {
        final pos = item['position'];
        if (!positionCodes.containsKey(pos)) {
          positionCodes[pos] = [];
        }
        positionCodes[pos]!.add(item['code']);
      }

      final params = positionCodes.map(
            (pos, codes) => MapEntry(pos, codes.join(',')),
      );

      final uri = Uri.parse("${Config.backendUrl}/get-hierarchy-filter")
          .replace(queryParameters: params);

      final token = await AuthService.getToken();

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token', // Or whatever your auth header is
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        subordinate.clear();
        positionLevels.clear();

        data.forEach((pos, list) {
          if (list is List && list.isNotEmpty) {
            positionLevels.add(pos);
            for (final person in list) {
              subordinate.add({
                'code': person['code'],
                'name': person['name'],
                'position': pos,
              });
            }
          }
        });

        setState(() {}); // refresh dropdowns
      }
    } catch (e) {
      print('Error fetching hierarchy: $e');
    }
  }



  final List<Map<String, String>> fallbackData = [
    {'Price Class': '6-10k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '10-15k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '15-20k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '20-30k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '30-40k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '40-70k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '70-100k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
  ];

  Map<String, dynamic> _extractRowValues(Map<String, dynamic> row) {
    final Map<String, dynamic> values = {};
    for (final key in tableHeaders) {
      if (key != 'Price Class' && key != 'Rank of Samsung') {
        values[key] = _parseValue(row[key]);
      }
    }
    return values;
  }

  Map<String, double> _getRowMinMax(Map<String, dynamic> rowValues) {
    double min = double.infinity;
    double max = -double.infinity;

    rowValues.forEach((key, val) {
      final parsed = _parseValue(val).toDouble();
      if (parsed < min) min = parsed;
      if (parsed > max) max = parsed;
    });

    return {'min': min, 'max': max};
  }


  dynamic _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      final cleaned = value
          .replaceAll(',', '')
          .replaceAll('%', '')  // <-- Important fix
          .trim();
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }


  String _getDisplayValue(dynamic value) {
    final parsed = _parseValue(value);

    if (selectedView == 0) {
      return "${parsed.toStringAsFixed(1)}%";
    }

    if (parsed >= 10000000) {
      return "${(parsed / 10000000).toStringAsFixed(2)} Cr";
    } else if (parsed >= 100000) {
      return "${(parsed / 100000).toStringAsFixed(2)} L";
    } else if (parsed >= 1000) {
      return "${(parsed / 1000).toStringAsFixed(1)} K";
    } else {
      return parsed.toString();
    }
  }





  Color _getHeatmapColor(dynamic val, double min, double max, {bool isTotal = false}) {
    final value = _parseValue(val).toDouble();
    if (max == min) return Colors.blue.shade100.withAlpha((0.65 * 255).toInt());

    final norm = ((value - min) / (max - min)).clamp(0.0, 1.0);

    final low = HSVColor.fromColor(Colors.blue.shade100);
    final high = HSVColor.fromColor(Colors.green.shade300);

    final color = HSVColor.lerp(low, high, norm)!.toColor();

    return color.withAlpha((0.95 * 255).toInt()); // pastel and safe from deprecation
  }









  double _calculateTotal(Map<String, dynamic> rowValues) {
    double sum = 0;
    rowValues.forEach((key, val) {
      if (val is num) sum += val.toDouble();
    });
    return sum;
  }



  Future<void> fetchReport() async {
    setState(() => loading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = selectedDateRange?.start;
    final endDate = selectedDateRange?.end;

    Map<String, String> queryParams = {
      "metric": selectedMetric == 0 ? "value" : "volume",
      "view": selectedView == 0 ? "share" : "default",  // 🔥 Add this line!
    };


    if (startDate != null) queryParams["startDate"] = dateFormat.format(startDate);
    if (endDate != null) queryParams["endDate"] = dateFormat.format(endDate);
    final Map<String, List<String>> grouped = {};

    for (final item in dropdownValue) {
      final pos = item['position'];
      if (!grouped.containsKey(pos)) grouped[pos] = [];
      grouped[pos]!.add(item['code']);
    }

    grouped.forEach((pos, codes) {
      queryParams[pos] = codes.join(',');
    });

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

        tableData = [];
        Set<String> allKeys = {};
        Map<String, dynamic>? extractedTotalRow;

        for (var row in data) {
          final rowMap = Map<String, dynamic>.from(row);
          final priceClass = rowMap['Price Class']?.toString().toLowerCase();

          if (priceClass == 'total') {
            extractedTotalRow = rowMap;
            continue;
          }

          allKeys.addAll(rowMap.keys.map((k) => k.trim()));
          tableData.add(rowMap);
        }

        allKeys.removeWhere((key) =>
        key == 'Price Class' || key == 'Rank of Samsung' || key.toLowerCase() == 'total');

        tableHeaders = allKeys.toList();

        // Capture the total row if found
        if (extractedTotalRow != null) {
          totalRow = extractedTotalRow.map((k, v) => MapEntry(k, v?.toString() ?? ''));
        }
      } else {
        tableData = [];
        tableHeaders = [];
      }
    } catch (e) {
      print("Error fetching report: $e");
      tableData = [];
      tableHeaders = [];
    }


    setState(() => loading = false);
  }

  Widget _dropdown(String label) {
    return SizedBox(
      width: 100,
      height: 36,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        hint: Text(label, style: const TextStyle(fontSize: 12)),
        items: ['Option 1', 'Option 2', 'Option 3']
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
            .toList(),
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildSegmentedToggle({
    required List<String> options,
    required int selectedIndex,
    required Function(int) onTap,
    required Color backgroundColor,
    required Color selectedColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                options[index],
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

  void _showFilterPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Filters",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              dropdownValue.clear();
                              selectedActorsByPosition.clear();
                              fetchReport();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Reset Filters"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: positionLevels.map((pos) {
                          final selectedCount = selectedActorsByPosition[pos]?.length ?? 0;
                          return ElevatedButton(
                            onPressed: () {
                              showMultiSelectModal(context, pos, () {
                                setStateDialog(() {});
                                fetchReport();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              selectedCount > 0
                                  ? '${pos.toUpperCase()} ($selectedCount)'
                                  : pos.toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // OPTIONAL: Show selected chips below filter buttons
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: dropdownValue.map((actor) {
                          return Chip(
                            label: Text(
                                "${actor['position'].toString().toUpperCase()} - ${actor['name']} (${actor['code']})",
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.grey.shade200,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showMultiSelectModal(BuildContext context, String position, VoidCallback onApply) {
    List<Map<String, dynamic>> selectedList = List.from(
      selectedActorsByPosition[position] ?? [],
    );
    String searchText = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = subordinate.where((actor) {
              final name = actor['name']?.toString().toLowerCase() ?? '';
              final code = actor['code']?.toString().toLowerCase() ?? '';
              return actor['position'] == position &&
                  (name.contains(searchText.toLowerCase()) ||
                      code.contains(searchText.toLowerCase()));
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select ${position.toUpperCase()}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: "Search name or code",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) => setModalState(() => searchText = val),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedList.map((actor) {
                          return Chip(
                            label: Text("${actor['name']} (${actor['code']})"),
                            onDeleted: () {
                              setModalState(() {
                                selectedList.removeWhere((a) => a['code'] == actor['code']);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final actor = filtered[index];
                            final alreadySelected = selectedList.any((s) => s['code'] == actor['code']);
                            return CheckboxListTile(
                              title: Text("${actor['name']} (${actor['code']})"),
                              value: alreadySelected,
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    selectedList.add(actor);
                                  } else {
                                    selectedList.removeWhere((a) => a['code'] == actor['code']);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => setModalState(() => selectedList.clear()),
                            child: const Text("CLEAR"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              selectedActorsByPosition[position] = List.from(selectedList);
                              dropdownValue = selectedActorsByPosition.values.expand((e) => e).toList();
                              onApply();
                              Navigator.of(context).pop();
                            },
                            child: const Text("APPLY"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isUsingFallback = tableData.length <= 1;
    final List<Map<String, dynamic>> dataToShow = isUsingFallback
        ? fallbackData
        : tableData.sublist(0, tableData.length - 1);


    final Map<String, dynamic> totalRow = tableData.length > 1
        ? tableData.last
        : {
      'Price Class': 'Total',
      'Samsung': '0',
      'Vivo': '0',
      'Oppo': '0',
    };

    final List<String> headersToShow = [
      ...tableHeaders,
      if (!tableHeaders.contains("Total")) "Total",
    ];



    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Extraction Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                _dateButton("Start date"),
                const SizedBox(width: 8),
                const Text("to"),
                const SizedBox(width: 8),
                _dateButton("End date"),
                const Spacer(),
                _resetButton()
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _showFilterPopup(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                      side: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Show Filters"),
                ),
                const Spacer(),
                _buildSegmentedToggle(
                  options: ['Value', 'Volume'],
                  selectedIndex: selectedMetric,
                  onTap: (index) {
                    setState(() {
                      selectedMetric = index;
                    });
                    fetchReport();
                  }
                  ,
                  backgroundColor: Colors.orange.shade300,
                  selectedColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 12),
                _buildSegmentedToggle(
                  options: ['Share', 'Default'],
                  selectedIndex: selectedView,
                  onTap: (index) {
                    setState(() {
                      selectedView = index;
                    });
                    fetchReport();
                  },
                  backgroundColor: Colors.blue.shade300,
                  selectedColor: Colors.blue.shade100,
                ),

              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _headerCell("Price band"),
                          for (final header in headersToShow) _headerCell(header),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (int index = 0; index < dataToShow.length + 1; index++)
                        _dataRow(
                          index == dataToShow.length ? totalRow : dataToShow[index],
                          isTotal: index == dataToShow.length,
                        ),
                    ],
                  ),
                ),
              ),
            ),







          ],
        ),
      ),
    );
  }

  Widget _resetButton() {
    return ElevatedButton(
      onPressed: () {},
      child: const Text("Reset Filters"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: const Size(10, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: Colors.orangeAccent, width: 1.2),
        ),
      ),
    );
  }

  Widget _headerCell(String label) {
    return Container(
      margin: const EdgeInsets.all(1),
      padding: cellPadding,
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Softer gray background
        borderRadius: BorderRadius.zero,
      ),
      alignment: Alignment.center,
      width: 110,
      height: 52,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: Colors.black87, // Dark gray text
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }





  Widget _dataRow(Map<String, dynamic> row, {bool isTotal = false}) {
    final rowValues = _extractRowValues(row);
    final minMax = _getRowMinMax(rowValues);

    return Row(
      children: [
        _dataCell(
          row['Price Class']?.toString() ?? '-',
          _getHeatmapColor(
            _calculateTotal(_extractRowValues(row)), // or some logic specific to Price class
            minMax['min'] ?? 0.0,
            minMax['max'] ?? 0.0,

          ),
          bold: true,
        ),

        for (final header in tableHeaders)
          _dataCell(
            _getDisplayValue(row[header]),
            _getHeatmapColor(row[header], minMax['min']!, minMax['max']!),
            bold: true,
          ),
        _dataCell(
          _getDisplayValue(row["Total"] ?? _calculateTotal(rowValues)),
          _getHeatmapColor(row["Total"], minMax['min']!, minMax['max']!),
          bold: true,
        ),
      ],
    );
  }





  Widget _dataCell(String value, Color color, {bool bold = false}) {
    return Container(
      margin: const EdgeInsets.all(1), // tighter grid
      padding: cellPadding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero, // square corners
      ),
      alignment: Alignment.center,
      width: 110, // 💡 Broader cells
      height: 52,  // 💡 Taller cells
      child: Text(
        value,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          fontSize: 13.5, // Slightly bigger font
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }





  static const cellPadding = EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0);

}
