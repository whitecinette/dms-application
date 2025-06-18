// import 'dart:convert';
// import 'package:dms_app/services/api_service.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../../widgets/shimmer_loader.dart';
// import 'package:intl/intl.dart';
// import '../../config.dart';
//
// class ExtractionReportScreen extends StatefulWidget {
//   @override
//   _ExtractionReportScreenState createState() => _ExtractionReportScreenState();
// }
//
// class _ExtractionReportScreenState extends State<ExtractionReportScreen> {
//   bool isValueSelected = true;
//   String? selectedRegion;
//   String? selectedSMD;
//   String? selectedASM;
//   String? selectedMDD;
//   String? selectedTSE;
//   String? selectedDealer;
//   String? selectedDistrict;
//   String? selectedTaluka;
//   String? selectedZone;
//   bool isLoading = true;
//
//   Map<String, List<Map<String, String>>> hierarchyData = {};
//
//   List<Map<String, dynamic>> tableData = [];
//   List<String> tableHeaders = [];
//
//
//   List<Map<String, String>> smdList = [];
//   List<Map<String, String>> asmList = [];
//   List<Map<String, String>> mddList = [];
//   List<Map<String, String>> tseList = [];
//   List<Map<String, String>> dealerList = [];
//
//   final List<String> districts = ['District A', 'District B', 'District C'];
//   final List<String> talukas = ['Taluka 1', 'Taluka 2', 'Taluka 3'];
//   final List<String> zones = ['Zone X', 'Zone Y', 'Zone Z'];
//   final List<String> brands = [
//     "Samsung", "Vivo", "Oppo", "Xiaomi", "Apple",
//     "OnePlus", "Realme", "Motorola", "Others",
//   ];
//
//
//   DateTimeRange? selectedDateRange;
//   List<Map<String, dynamic>> tableData = [];
//   bool loading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     selectedDateRange = DateTimeRange(
//       start: DateTime(now.year, now.month, 1),
//       end: DateTime(now.year, now.month + 1, 0),
//     );
//     loadHierarchyFilters();
//     fetchReport();
//   }
//
//   Future<void> fetchReport() async {
//     setState(() => loading = true);
//
//     final dateFormat = DateFormat('yyyy-MM-dd');
//     final startDate = selectedDateRange?.start;
//     final endDate = selectedDateRange?.end;
//
//     Map<String, String> queryParams = {
//       "metric": isValueSelected ? "value" : "volume",
//     };
//
//     if (startDate != null) queryParams["startDate"] = dateFormat.format(startDate);
//     if (endDate != null) queryParams["endDate"] = dateFormat.format(endDate);
//     if (selectedSMD != null) queryParams["smd"] = selectedSMD!;
//     if (selectedASM != null) queryParams["asm"] = selectedASM!;
//     if (selectedMDD != null) queryParams["mdd"] = selectedMDD!;
//     if (selectedTSE != null) queryParams["tse"] = selectedTSE!;
//     if (selectedDealer != null) queryParams["dealer"] = selectedDealer!;
//
//     final uri = Uri.parse("${Config.backendUrl}/get-extraction-report-for-admin")
//         .replace(queryParameters: queryParams);
//
//     try {
//       final response = await http.get(uri);
//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         final data = jsonResponse['data'] as List<dynamic>? ?? [];
//         tableData = data.map((e) => Map<String, dynamic>.from(e)).toList();
//       } else {
//         tableData = [];
//       }
//     } catch (e) {
//       tableData = [];
//     }
//
//     setState(() => loading = false);
//   }
//
//   Future<void> loadHierarchyFilters({Map<String, String>? filters}) async {
//     try {
//       final data = await ApiService.getHierarchyFilters(query: filters);
//       print("Hierarchy filter data fetched: $data");
//
//       setState(() {
//         smdList = List<Map<String, String>>.from((data['smd'] ?? []).map((e) => {
//           'code': e['code'].toString(),
//           'name': e['name'].toString(),
//         }));
//
//         asmList = List<Map<String, String>>.from((data['asm'] ?? []).map((e) => {
//           'code': e['code'].toString(),
//           'name': e['name'].toString(),
//         }));
//
//         mddList = List<Map<String, String>>.from((data['mdd'] ?? []).map((e) => {
//           'code': e['code'].toString(),
//           'name': e['name'].toString(),
//         }));
//
//         tseList = List<Map<String, String>>.from((data['tse'] ?? []).map((e) => {
//           'code': e['code'].toString(),
//           'name': e['name'].toString(),
//         }));
//
//         dealerList = List<Map<String, String>>.from((data['dealer'] ?? []).map((e) => {
//           'code': e['code'].toString(),
//           'name': e['name'].toString(),
//         }));
//       });
//     } catch (e) {
//       print('Failed to load hierarchy filters: $e');
//     }
//   }
//
//
//   Future<void> pickDateRange() async {
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       initialDateRange: selectedDateRange,
//     );
//
//     if (picked != null) {
//       setState(() => selectedDateRange = picked);
//       fetchReport();
//     }
//   }
//
//   String getDateRangeText() {
//     if (selectedDateRange == null) return "Select Date Range";
//     final start = selectedDateRange!.start;
//     final end = selectedDateRange!.end;
//     return "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}";
//   }
//
//
//   // Modified buildDropdown for normal string list
//   Widget buildDropdown(String label, List<String> items, String? selectedItem, Function(String?) onChanged, {double width = 80, double fontSize = 10,}) {
//     return Container(
//       width: width,
//       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black, width: 1.5),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           value: selectedItem,
//           hint: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
//           items: items.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
//               ),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
//
// // Modified version for single select with name shown on button + highlight selected card
//   Widget buildCodeNameSelector(String label, List<Map<String, String>> items, String? selectedCode, Function(String?) onSelected,) {
//     final isSelected = selectedCode != null && selectedCode.isNotEmpty;
//     final selectedCount = isSelected ? 1 : 0;
//
//     return Container(
//       width: 100,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black, width: 1.5),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: InkWell(
//         onTap: () {
//           showModalBottomSheet(
//             context: context,
//             builder: (context) {
//               return Container(
//                 height: 350,
//                 child: Column(
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.all(12),
//                       child: Text(
//                         "Select $label",
//                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                     ),
//                     Expanded(
//                       child: items.isEmpty
//                           ? ShimmerLoader()
//                           : ListView.builder(
//                         itemCount: items.length,
//                         itemBuilder: (context, index) {
//                           final item = items[index];
//                           final selected = item['code'] == selectedCode;
//
//                           return Card(
//                             color: selected ? Colors.blue.shade100 : Colors.white,
//                             margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             child: ListTile(
//                               title: Text(item['name'] ?? ""),
//                               subtitle: Text(item['code'] ?? ""),
//                               trailing: selected
//                                   ? Icon(Icons.check_circle, color: Colors.blue)
//                                   : null,
//                               onTap: () {
//                                 if (selected) {
//                                   onSelected(null);
//                                 } else {
//                                   onSelected(item['code']);
//                                 }
//                                 Navigator.pop(context);
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "$label${selectedCount > 0 ? ' $selectedCount' : ''}",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(width: 6),
//             Icon(Icons.arrow_drop_down, color: Colors.black),
//           ],
//         ),
//       ),
//     );
//   }
//
// // Handle selection change for each dropdown
//   void onSMDChanged(String? code) {
//     setState(() {
//       selectedSMD = code;
//       selectedASM = null;
//       selectedMDD = null;
//       selectedTSE = null;
//       selectedDealer = null;
//     });
//     loadHierarchyFilters(filters: code != null ? {'smd': code} : null);
//     fetchReport();
//   }
//
//   void onASMChanged(String? code) {
//     setState(() {
//       selectedASM = code;
//       selectedMDD = null;
//       selectedTSE = null;
//       selectedDealer = null;
//     });
//     loadHierarchyFilters(filters: code != null ? {'asm': code} : null);
//     fetchReport();
//   }
//
//   void onMDDChanged(String? code) {
//     setState(() {
//       selectedMDD = code;
//       selectedTSE = null;
//       selectedDealer = null;
//     });
//     loadHierarchyFilters(filters: code != null ? {'mdd': code} : null);
//     fetchReport();
//   }
//
//   void onTSEChanged(String? code) {
//     setState(() {
//       selectedTSE = code;
//       selectedDealer = null;
//     });
//     loadHierarchyFilters(filters: code != null ? {'tse': code} : null);
//     fetchReport();
//   }
//
//   void onDealerChanged(String? code) {
//     setState(() {
//       selectedDealer = code;
//     });
//     fetchReport();
//   }
//
//
// // Reset all filters
//   void resetFilters() {
//     setState(() {
//       selectedSMD = null;
//       selectedASM = null;
//       selectedMDD = null;
//       selectedTSE = null;
//       selectedDealer = null;
//     });
//     loadHierarchyFilters(); // Load full data
//     fetchReport();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double maxValue = 0;
//     for (var row in tableData) {
//       for (var brand in brands) {
//         final val = row[brand];
//         if (val is num && val > maxValue) {
//           maxValue = val.toDouble();
//         }
//       }
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Extraction Report")),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Row 1: Date + Reset
//             Row(
//               children: [
//                 Expanded(
//                   child: buildPillButton("Start date", Colors.blue.shade50),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: buildPillButton("End date", Colors.blue.shade50),
//                 ),
//                 SizedBox(width: 8),
//                 buildPillButton("Reset Filters", Colors.yellow.shade100),
//               ],
//             ),
//             SizedBox(height: 10),
//
//             // Row 2: Show Filters
//             Row(
//               children: [
//                 TextButton.icon(
//                   onPressed: () => showFilterPopup(context),
//                   icon: Icon(Icons.keyboard_arrow_down),
//                   label: Text("Show Filters"),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.blue,
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10),
//
//             // Row 3: Value / Volume toggle
//             Row(
//               children: [
//                 buildMetricToggle("Value", isValueSelected, () {
//                   setState(() => isValueSelected = true);
//                   fetchReport();
//                 }),
//                 SizedBox(width: 8),
//                 buildMetricToggle("Volume", !isValueSelected, () {
//                   setState(() => isValueSelected = false);
//                   fetchReport();
//                 }),
//               ],
//             ),
//             SizedBox(height: 10),
//
//             // Row 4: Status Tags
//             Row(
//               children: [
//                 buildStatusTag("Share"),
//                 SizedBox(width: 8),
//                 buildStatusTag("Default", color: Colors.grey.shade300),
//               ],
//             ),
//
//             SizedBox(height: 16),
//
//             // Table Section
//             Expanded(
//               child: loading
//                   ? ShimmerLoader()
//                   : tableData.isEmpty
//                   ? Center(child: Text("No data found"))
//                   : SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Table(
//                       defaultColumnWidth: FixedColumnWidth(100),
//                       children: [
//                         TableRow(
//                           children: [
//                             buildHeaderCell("Price band"),
//                             ...brands.map((b) => buildHeaderCell(b)).toList(),
//                           ],
//                         ),
//                         ...tableData.map((row) {
//                           return TableRow(
//                             children: [
//                               buildCardCell(row["Price Class"] ?? "-"),
//                               ...brands.map((brand) {
//                                 final val = row[brand] ?? 0;
//                                 final numVal = val is num
//                                     ? val.toDouble()
//                                     : double.tryParse(val.toString()) ?? 0;
//                                 return buildCardCell(
//                                   numVal.toStringAsFixed(0),
//                                   background: heatMapColor(numVal, maxValue),
//                                   highlight: numVal > maxValue * 0.7,
//                                 );
//                               }).toList(),
//                             ],
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//
//       ),
//     );
//   }
//
//   Widget buildPillButton(String text, Color bgColor) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Center(
//         child: Text(
//           text,
//           style: TextStyle(fontWeight: FontWeight.w500),
//         ),
//       ),
//     );
//   }
//
//   Widget buildToggle(String label, bool active, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: active ? Colors.orange : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.orange),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: active ? Colors.white : Colors.orange,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Toggle buttons with custom pill style for Value/Volume and Share/Default
//   Widget buildMetricToggle(String label, bool isActive, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: isActive ? Colors.orange : Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.orange, width: 1.4),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 13,
//             color: isActive ? Colors.white : Colors.orange,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildChoiceToggle(String label, bool selected, VoidCallback onSelected) {
//     return ChoiceChip(
//       label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
//       selected: selected,
//       onSelected: (_) => onSelected(),
//       selectedColor: Colors.orange,
//       backgroundColor: Colors.transparent,
//       side: BorderSide(color: Colors.orange),
//       labelStyle: TextStyle(
//         color: selected ? Colors.white : Colors.orange,
//         fontSize: 13,
//       ),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//     );
//   }
//
// // Status tag (Share / Default) with better spacing and pastel fill
//   Widget buildStatusTag(String label, {Color? color}) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: color ?? Colors.blue.shade100,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontWeight: FontWeight.w600,
//           fontSize: 13,
//           color: Colors.black,
//         ),
//       ),
//     );
//   }
//
// // Filter popup
//   void showFilterPopup(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       isScrollControlled: true,
//       builder: (context) => Material(
//         elevation: 6,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Filters",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.yellow.shade100,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: TextButton(
//                       onPressed: resetFilters,
//                       child: Text(
//                         "Reset Filters",
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//               Wrap(
//                 spacing: 12,
//                 runSpacing: 12,
//                 children: [
//                   buildFilterDropdown("State", ["State A", "State B", "State C"]),
//                   buildFilterDropdown("District", ["District A", "District B"]),
//                   buildFilterDropdown("Town", ["Town 1", "Town 2"]),
//                   buildFilterDropdown("SMD", ["SMD X", "SMD Y"]),
//                   buildFilterDropdown("ASM", ["ASM 1", "ASM 2"]),
//                   buildFilterDropdown("MDD", ["MDD A", "MDD B"]),
//                   buildFilterDropdown("TSE", ["TSE A", "TSE B"]),
//                   buildFilterDropdown("Dealer", ["Dealer A", "Dealer B"]),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildFilterDropdown(String label, List<String> items) {
//     return Container(
//       width: 110,
//       padding: EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           hint: Text(
//             label,
//             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//           ),
//           icon: Icon(Icons.keyboard_arrow_down),
//           items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
//           onChanged: (val) {}, // placeholder
//         ),
//       ),
//     );
//   }
//
//   Widget buildHeaderCell(String text, {double width = 100}) {
//     return Container(
//       margin: EdgeInsets.all(2),
//       width: width,
//       decoration: BoxDecoration(
//         color: Color(0xFFFCEFEF),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
//       alignment: Alignment.center,
//       child: Text(
//         text,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(
//           fontWeight: FontWeight.w600,
//           fontSize: 13,
//           color: Colors.black87,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }
//
//   Widget buildCardCell(String text, {Color? background, bool highlight = false}) {
//     return Container(
//       margin: EdgeInsets.all(2),
//       decoration: BoxDecoration(
//         color: background ?? Color(0xFFFFF3E0),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       alignment: Alignment.center,
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
//           fontSize: 13,
//           color: highlight ? Colors.black : Colors.grey.shade800,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }
//
// // Override heatMapColor to return flat fills (optional: based on tiers)
//   Color heatMapColor(double value, double maxValue) {
//     if (value == 0) return Colors.white;
//     if (value > maxValue * 0.9) return Color(0xFFE53935); // deep red
//     if (value > maxValue * 0.7) return Color(0xFFFF7043); // orange
//     if (value > maxValue * 0.4) return Color(0xFFFFA726); // light orange
//     return Color(0xFFFFE0B2); // pastel
//   }
//
//
// }
