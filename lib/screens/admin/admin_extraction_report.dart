import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ExtractionReportPage extends StatefulWidget {
  @override
  _ExtractionReportPageState createState() => _ExtractionReportPageState();
}

class _ExtractionReportPageState extends State<ExtractionReportPage> {
  List<bool> valueVolumeToggle = [true, false];
  List<bool> shareDefaultToggle = [false, true];

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

  final List<Map<String, String>> fallbackData = [
    {'Price Class': '6-10k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '10-15k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '15-20k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '20-30k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '30-40k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
    {'Price Class': '40-70k', 'Samsung': '2,00,089', 'Vivo': '12,889', 'Oppo': '0'},
    {'Price Class': '70-100k', 'Samsung': '10,089', 'Vivo': '30,00,987', 'Oppo': '10,000'},
  ];

  final Map<String, String> totalRow = {
    'Price Class': 'Total',
    'Samsung': '10,089',
    'Vivo': '30,00,987',
    'Oppo': '10,000',
  };

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = selectedDateRange?.start;
    final endDate = selectedDateRange?.end;

    Map<String, String> queryParams = {
      "metric": selectedMetric == 0 ? "value" : "volume",
    };

    if (startDate != null) queryParams["startDate"] = dateFormat.format(startDate);
    if (endDate != null) queryParams["endDate"] = dateFormat.format(endDate);
    if (selectedSMD != null) queryParams["smd"] = selectedSMD!;
    if (selectedASM != null) queryParams["asm"] = selectedASM!;
    if (selectedMDD != null) queryParams["mdd"] = selectedMDD!;
    if (selectedTSE != null) queryParams["tse"] = selectedTSE!;
    if (selectedDealer != null) queryParams["dealer"] = selectedDealer!;

    final uri = Uri.parse("https://your-api.com/get-extraction-report-for-admin")
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as List<dynamic>? ?? [];

        tableData = data.map((e) => Map<String, dynamic>.from(e)).toList();

        if (tableData.isNotEmpty) {
          final firstRow = tableData.first;
          tableHeaders = firstRow.keys
              .where((key) => key != "Price Class" && key != "Rank of Samsung")
              .toList();
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
                      const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Reset Filters"),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _dropdown("state"),
                      _dropdown("district"),
                      _dropdown("town"),
                      _dropdown("smd"),
                      _dropdown("asm"),
                      _dropdown("mdd"),
                      _dropdown("tse"),
                      _dropdown("dealer"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dataToShow =
    tableData.isNotEmpty ? tableData : fallbackData;

    final List<String> headersToShow = tableHeaders.isNotEmpty
        ? tableHeaders
        : fallbackData.first.keys.where((k) => k != 'Price Class').toList();

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
                  onTap: (index) => setState(() => selectedMetric = index),
                  backgroundColor: Colors.orange.shade300,
                  selectedColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 12),
                _buildSegmentedToggle(
                  options: ['Share', 'Default'],
                  selectedIndex: selectedView,
                  onTap: (index) => setState(() => selectedView = index),
                  backgroundColor: Colors.blue.shade300,
                  selectedColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _headerCell("Price band"),
                for (final header in headersToShow) _headerCell(header),
              ],
            ),
            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!loading)
              Expanded(
                child: ListView.builder(
                  itemCount: dataToShow.length + 1,
                  itemBuilder: (_, index) {
                    if (index == dataToShow.length) {
                      return _dataRow(totalRow, isTotal: true);
                    }
                    return _dataRow(dataToShow[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFE3F2FD),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: const Size(10, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: cellPadding,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEDD),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _dataRow(Map<String, dynamic> row, {bool isTotal = false}) {
    final keys = row.keys.where((k) => k != 'Price Class');
    return Row(
      children: [
        _dataCell(row['Price Class']?.toString() ?? '-', Colors.orange.shade50),
        for (final key in keys)
          _dataCell(
            row[key]?.toString() ?? '-',
            _getCellColor(key, row[key], isTotal),
          ),
      ],
    );
  }

  Color _getCellColor(String key, dynamic value, bool isTotal) {
    if (isTotal) return Colors.orange.shade200;
    if (value == 0 || value == null || value == '0') return Colors.white;
    if ((value is int && value > 100000) || (value is String && value.contains('30,00,987')))
      return Colors.deepOrange;
    return Colors.orange.shade100;
  }

  Widget _dataCell(String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: cellPadding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  static const cellPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0);
}