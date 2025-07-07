import 'package:dms_app/widgets/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/auth_service.dart';

class ExtractionStatusAdminScreen extends StatefulWidget {


  @override
  State<ExtractionStatusAdminScreen> createState() =>
      _ExtractionStatusAdminScreenState();

}

class _ExtractionStatusAdminScreenState extends State<ExtractionStatusAdminScreen> {
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  Map<String, List<Map<String, String>>> dropdownOptions = {
    "mdd": [],
    "asm": [],
    "smd": [],
  };

  bool isLoading = false;


  final TextEditingController searchController = TextEditingController();

  List<String> selectedMdd = [];
  List<String> selectedAsm = [];
  List<String> selectedSmd = [];

  List<Map<String, dynamic>> statusData = [];

  // Dummy dropdown items
  final List<Map<String, String>> dummyMdd = [
    {"code": "MDD01", "name": "MDD One"},
    {"code": "MDD02", "name": "MDD Two"},
  ];
  final List<Map<String, String>> dummyAsm = [
    {"code": "ASM01", "name": "ASM One"},
    {"code": "ASM02", "name": "ASM Two"},
  ];
  final List<Map<String, String>> dummySmd = [
    {"code": "SMD01", "name": "SMD One"},
    {"code": "SMD02", "name": "SMD Two"},
  ];

  @override
  void initState() {
    super.initState();
    fetchDropdownData("mdd");
    fetchDropdownData("asm");
    fetchDropdownData("smd");

    fetchExtractionStatus();
  }

  Future<void> fetchDropdownData(String position) async {
    final uri = Uri.parse('${Config.backendUrl}/admin/get-users-by-positions');
    final body = {"positions": [position]};

    final response = await http.post(uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)["data"];
      setState(() {
        dropdownOptions[position] = List<Map<String, String>>.from(
          data.map((item) => {
            "code": item["code"].toString(),
            "name": item["name"].toString(),
          }),
        );
      });


      print("Fetched for $position: $data");

    } else {
      print("Failed to fetch $position: ${response.body}");
    }
  }


  Future<void> fetchExtractionStatus() async {
    setState(() => isLoading = true); // 👈 Start loading
    final token = await AuthService.getToken();

    final uri = Uri.parse('${Config.backendUrl}/user/extraction-status-role-wise',
    );

    final body = {
      "startDate": DateFormat("yyyy-MM-dd").format(dateRange.start),
      "endDate": DateFormat("yyyy-MM-dd").format(dateRange.end),
      "mdd": selectedMdd,
      "asm": selectedAsm,
      "smd": selectedSmd,
    };

    final response = await http.post(uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        statusData = List<Map<String, dynamic>>.from(decoded["data"]);
      });
    } else {
      print("Error: ${response.body}");
    }

    setState(() => isLoading = false); // 👈 Stop loading
  }


  List<Map<String, dynamic>> get filteredData {
    final query = searchController.text.toLowerCase();
    return statusData.where((item) {
      final name = item["name"].toString().toLowerCase();
      final code = item["code"].toString().toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  Widget buildColoredBlock(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget buildMultiSelectDropdown({
    required String title,
    required String position,
    required List<String> selectedValues,
    required Function(List<String>) onApply,
  }) {
    final items = dropdownOptions[position] ?? [];

    return GestureDetector(
      onTap: () => _showCustomDropdown(context, position, selectedValues, onApply),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValues.isEmpty
                    ? title
                    : selectedValues
                    .map((code) {
                  final item = items.firstWhere(
                        (e) => e["code"] == code,
                    orElse: () => {"code": code, "name": ""},
                  );
                  return item["name"] ?? code;
                })
                    .join(", "),
                style: TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),

      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("dd MMM");

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              // 🔙 Back Button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  SizedBox(width: 10),
                  Text("Extraction Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

              SizedBox(height: 12),

              // 🔍 Date & Filter Row
              // Row(
              //   children: [
              //     Expanded(
              //       child: GestureDetector(
              //         onTap: () async {
              //           final picked = await showDateRangePicker(
              //             context: context,
              //             initialDateRange: dateRange,
              //             firstDate: DateTime(2023),
              //             lastDate: DateTime.now(),
              //           );
              //           if (picked != null) {
              //             setState(() => dateRange = picked);
              //             fetchExtractionStatus();
              //           }
              //         },
              //         child: Container(
              //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(8),
              //             border: Border.all(color: Colors.grey.shade400),
              //           ),
              //           child: Row(
              //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //             children: [
              //               Text("${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}"),
              //               Icon(Icons.calendar_month),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 8),
              //     IconButton(
              //       icon: Icon(Icons.refresh),
              //       onPressed: fetchExtractionStatus,
              //     )
              //   ],
              // ),

              SizedBox(height: 10),

              // 🧠 Search
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search by name or code...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: 10),

              // 🔽 Dropdowns Row
              Row(
                children: [
                  Expanded(
                    child: buildMultiSelectDropdown(
                      title: "SMD",
                      position: "smd",
                      selectedValues: selectedSmd,
                      onApply: (values) {
                        setState(() => selectedSmd = values);
                        fetchExtractionStatus();
                      },
                    ),
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: buildMultiSelectDropdown(
                      title: "MDD",
                      position: "mdd",
                      selectedValues: selectedMdd,
                      onApply: (values) {
                        setState(() => selectedMdd = values);
                        fetchExtractionStatus();
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: buildMultiSelectDropdown(
                      title: "ASM",
                      position: "asm",
                      selectedValues: selectedAsm,
                      onApply: (values) {
                        setState(() => selectedAsm = values);
                        fetchExtractionStatus();
                      },
                    ),
                  ),


                ],
              ),

              SizedBox(height: 10),


              // 🧾 Dropdowns
              // MultiSelectDialogField(
              //   items: dummyMdd.map((e) => MultiSelectItem(e["code"], "${e["code"]} - ${e["name"]}")).toList(),
              //   listType: MultiSelectListType.LIST,
              //   title: Text("Select MDD"),
              //   buttonText: Text("Select MDD"),
              //   onConfirm: (values) {
              //     selectedMdd = values.map((e) => e.toString()).toList();
              //     fetchExtractionStatus();
              //   },
              // ),
              //
              // MultiSelectDialogField(
              //   items: dummyAsm.map((e) => MultiSelectItem(e["code"], "${e["code"]} - ${e["name"]}")).toList(),
              //   listType: MultiSelectListType.LIST,
              //   title: Text("Select ASM"),
              //   buttonText: Text("Select ASM"),
              //   onConfirm: (values) {
              //     selectedAsm = values.map((e) => e.toString()).toList();
              //     fetchExtractionStatus();
              //   },
              // ),
              //
              // MultiSelectDialogField(
              //   items: dummySmd.map((e) => MultiSelectItem(e["code"], "${e["code"]} - ${e["name"]}")).toList(),
              //   listType: MultiSelectListType.LIST,
              //   title: Text("Select SMD"),
              //   buttonText: Text("Select SMD"),
              //   onConfirm: (values) {
              //     selectedSmd = values.map((e) => e.toString()).toList();
              //     fetchExtractionStatus();
              //   },
              // ),

              SizedBox(height: 10),

              // 🔢 Status Grid
              Expanded(
                child: isLoading ?
                ShimmerLoader()
                    : ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (_, index) {
                    final person = filteredData[index];
                    return Container(
                      margin: EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF6F3FF),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.24),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row with code and total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                person["code"],
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                "Total: ${person["total"]}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            person["name"],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          // Done / Pending blocks
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Done", style: TextStyle(color: Colors.green, fontSize: 12)),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${person['done']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                          Text(
                                            '${person['donePercent']}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Pending", style: TextStyle(color: Colors.red, fontSize: 12)),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${person['pending']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.red.shade900,
                                            ),
                                          ),
                                          Text(
                                            '${person['pendingPercent']}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.red.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              ),

            ],
          ),
        ),
      ),
    );
  }


  void _showCustomDropdown(BuildContext context, String position, List<String> selectedValues, Function(List<String>) onApply) {
    List<String> tempSelected = List.from(selectedValues);
    final items = dropdownOptions[position] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select ${position.toUpperCase()}"),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListView(
                  children: items.map((item) {
                    final code = item["code"]!;
                    final name = item["name"]!;
                    return CheckboxListTile(
                      value: tempSelected.contains(code),
                      title: Text("$code - $name", style: TextStyle(fontSize: 13)),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            tempSelected.add(code);
                          } else {
                            tempSelected.remove(code);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[900])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onApply(tempSelected);
              },
              child: Text("Apply", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[600], // Deep Blue
              ),
            ),

          ],
        );
      },
    );
  }


}
