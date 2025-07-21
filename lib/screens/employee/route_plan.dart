// // RoutePlanScreen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import '../../providers/route_plan_provider.dart';
// import '../employee/market_coverage.dart';
// import '../../providers/market_coverage_provider.dart';
//
//
// class RoutePlanScreen extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<RoutePlanScreen> createState() => _RoutePlanScreenState();
// }
//
// class AddRouteModal extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<AddRouteModal> createState() => _AddRouteModalState();
// }
//
// class _AddRouteModalState extends ConsumerState<AddRouteModal> {
//   DateTimeRange? selectedRange;
//   final Map<String, List<String>> itinerary = {
//     "district": [],
//     "zone": [],
//     "taluka": [],
//     "town" : [],
//   };
//
//   List<String> districtOptions = [];
//   List<String> zoneOptions = [];
//   List<String> talukaOptions = [];
//   List<String> townOptions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     final today = DateTime.now();
//     selectedRange = DateTimeRange(
//       start: DateTime(today.year, today.month, today.day),
//       end: DateTime(today.year, today.month, today.day + 1),
//     );
//     _fetchDropdownOptions();
//   }
//
//   Future<void> _fetchDropdownOptions() async {
//     final options = await ref.read(routePlanProvider.notifier).fetchMarketCoverageDropdown();
//     if (options != null) {
//       setState(() {
//         districtOptions = options['district'] ?? [];
//         zoneOptions = options['zone'] ?? [];
//         talukaOptions = options['taluka'] ?? [];
//         townOptions = options['town'] ?? [];
//       });
//     }
//   }
//
//   void _addItem(String key, String value) {
//     if (!itinerary[key]!.contains(value)) {
//       setState(() => itinerary[key]!.add(value));
//     }
//   }
//
//   void _submit() async {
//     if (selectedRange == null) return;
//     final success = await ref.read(routePlanProvider.notifier).addRoutePlan(
//       startDate: selectedRange!.start,
//       endDate: selectedRange!.end,
//       itinerary: itinerary,
//     );
//     if (success) {
//       await ref.read(routePlanProvider.notifier).fetchRoutePlans();
//       Navigator.pop(context);
//     }
//   }
//
//   void _showMultiSelect(BuildContext context, String label, List<String> options) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (context) {
//         final selected = Set<String>.from(itinerary[label]!);
//         String searchQuery = "";
//
//         return StatefulBuilder(
//           builder: (context, setStateModal) {
//             final filteredOptions = options
//                 .where((option) => option.toLowerCase().contains(searchQuery.toLowerCase()))
//                 .toList();
//
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 16,
//                 right: 16,
//                 top: 16,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text("Select $label", style: TextStyle(fontWeight: FontWeight.bold)),
//
//                   SizedBox(height: 8),
//                   TextField(
//                     decoration: InputDecoration(
//                       hintText: "Search...",
//                       prefixIcon: Icon(Icons.search),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     onChanged: (val) => setStateModal(() => searchQuery = val),
//                   ),
//
//                   SizedBox(height: 12),
//                   Flexible(
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: filteredOptions.length,
//                       itemBuilder: (context, index) {
//                         final option = filteredOptions[index];
//                         final isSelected = selected.contains(option);
//                         return CheckboxListTile(
//                           value: isSelected,
//                           title: Text(option),
//                           onChanged: (checked) {
//                             setStateModal(() {
//                               if (checked == true) {
//                                 selected.add(option);
//                               } else {
//                                 selected.remove(option);
//                               }
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ),
//
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() => itinerary[label] = selected.toList());
//                       Navigator.pop(context);
//                     },
//                     child: Text("Done"),
//                   )
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//
//   Widget _buildDropdownButton(String label, List<String> options) {
//     return InkWell(
//       onTap: () => _showMultiSelect(context, label, options),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: Colors.deepPurple.shade100),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(label, style: TextStyle(color: Colors.deepPurple)),
//             SizedBox(width: 200),
//             Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildChips() {
//     final allTags = [
//       ...itinerary['district']!.map((e) => {'type': 'district', 'value': e}),
//       ...itinerary['zone']!.map((e) => {'type': 'zone', 'value': e}),
//       ...itinerary['taluka']!.map((e) => {'type': 'taluka', 'value': e}),
//       ...itinerary['town']!.map((e) => {'type' : 'town', 'value': e}),
//     ];
//
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: allTags.map((tag) {
//         return Chip(
//           label: Text(tag['value']!),
//           deleteIcon: Icon(Icons.close),
//           onDeleted: () {
//             setState(() {
//               itinerary[tag['type']]!.remove(tag['value']);
//             });
//           },
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final formatter = DateFormat('dd MMM');
//     final isLoading = ref.watch(routePlanProvider).isLoading;
//     return Padding(
//       padding: MediaQuery.of(context).viewInsets,
//       child: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Add Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//             // SizedBox(height: 12),
//             // Row(
//             //   children: [
//             //     GestureDetector(
//             //       onTap: () async {
//             //         final picked = await showDateRangePicker(
//             //           context: context,
//             //           initialDateRange: selectedRange,
//             //           firstDate: DateTime.now().subtract(Duration(days: 365)),
//             //           lastDate: DateTime.now().add(Duration(days: 365)),
//             //         );
//             //         if (picked != null) {
//             //           setState(() => selectedRange = picked);
//             //         }
//             //       },
//             //       child: Container(
//             //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             //         decoration: BoxDecoration(
//             //           color: Colors.blue.shade50,
//             //           borderRadius: BorderRadius.circular(8),
//             //         ),
//             //         child: Text(
//             //           "${formatter.format(selectedRange!.start)} to ${formatter.format(selectedRange!.end)}",
//             //           style: TextStyle(fontWeight: FontWeight.w500),
//             //         ),
//             //       ),
//             //     ),
//             //     Spacer(),
//             //     TextButton(
//             //       onPressed: () {
//             //         setState(() {
//             //           itinerary['district'] = List.from(districtOptions);
//             //           itinerary['zone'] = List.from(zoneOptions);
//             //           itinerary['taluka'] = List.from(talukaOptions);
//             //           itinerary['town'] = List.from(townOptions);
//             //         });
//             //       },
//             //       child: Text("+ Add All", style: TextStyle(color: Colors.deepPurple)),
//             //     ),
//             //   ],
//             // ),
//             SizedBox(height: 36),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 // _buildDropdownButton('district', districtOptions),
//                 // _buildDropdownButton('zone', zoneOptions),
//                 // _buildDropdownButton('taluka', talukaOptions),
//                 _buildDropdownButton('town', townOptions)
//               ],
//             ),
//             SizedBox(height: 12),
//             _buildChips(),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: isLoading ? null : _submit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange.shade50,
//                 foregroundColor: Colors.black,
//               ),
//               child: isLoading
//                   ? SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               )
//                   : Text("Submit"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _RoutePlanScreenState extends ConsumerState<RoutePlanScreen> {
//   DateTimeRange? selectedRange;
//
//   @override
//   void initState() {
//     super.initState();
//
//     final now = DateTime.now();
//     final startOfMonth = DateTime(now.year, now.month, 1);
//     final endOfMonth = DateTime(now.year, now.month + 1, 0);
//
//     selectedRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
//
//     // ✅ Ensures provider is ready before we fetch
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchRoutes();
//     });
//   }
//
//
//   Future<void> _fetchRoutes({bool reset = false}) async {
//     if (reset) {
//       final now = DateTime.now();
//       final startOfMonth = DateTime(now.year, now.month, 1);
//       final endOfMonth = DateTime(now.year, now.month + 1, 0);
//       selectedRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
//     }
//
//     if (selectedRange != null) {
//       ref.read(routePlanProvider.notifier).setDateRange(selectedRange!);
//       await ref.read(routePlanProvider.notifier).fetchRoutePlans();
//     }
//   }
//
//   void _openAddModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) => AddRouteModal(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(routePlanProvider);
//     final formatter = DateFormat('dd MMM');
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Routes'),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: ElevatedButton(
//               onPressed: _openAddModal,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFFEDE9FE), // Light purple
//                 foregroundColor: Colors.deepPurple,
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 elevation: 0,
//               ),
//               child: Text('+ Add New', style: TextStyle(fontWeight: FontWeight.w500)),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () async {
//                     final picked = await showDateRangePicker(
//                       context: context,
//                       initialDateRange: selectedRange,
//                       firstDate: DateTime.now().subtract(Duration(days: 365)),
//                       lastDate: DateTime.now().add(Duration(days: 365)),
//                     );
//                     if (picked != null) {
//                       setState(() => selectedRange = picked);
//                       _fetchRoutes();
//                     }
//                   },
//                   child: Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '${formatter.format(selectedRange!.start)} to ${formatter.format(selectedRange!.end)}',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                 ),
//                 Spacer(),
//                 Row(
//                   children: [
//                     TextButton(
//                       onPressed: () => _fetchRoutes(reset: true),
//                       child: Text('Reset Filters'),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.refresh),
//                       tooltip: 'Refresh',
//                       onPressed: _fetchRoutes,
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search',
//                 prefixIcon: Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
//               ),
//               onChanged: (val) => ref.read(routePlanProvider.notifier).search(val),
//             ),
//           ),
//           Expanded(
//             child: state.filteredRoutes.isEmpty
//                 ? Center(
//               child: Text(
//                 "No routes found! Please refresh or add new.",
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             )
//                 : ListView.builder(
//               itemCount: state.filteredRoutes.length,
//               itemBuilder: (context, index) {
//                 final route = state.filteredRoutes[index];
//                 return Card(
//                   margin: EdgeInsets.all(10),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   child: ListTile(
//                       onTap: () {
//                         final provider = ref.read(marketCoverageProvider.notifier);
//                         provider.resetFilters(); // ✅ Clear filters
//
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => MarketCoverageScreen(
//                               initialRouteName: route['name'],
//                               initialStartDate: DateTime.parse(route['startDate']),
//                               initialEndDate: DateTime.parse(route['endDate']),
//                               initialItinerary: List<String>.from(route['itinerary']),
//                             ),
//                           ),
//                         );
//                       },
//                     leading: Icon(Icons.near_me_outlined),
//                     title: Text(route['name'], style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(route['itinerary'].join(', ')),
//                         SizedBox(height: 4),
//                         // Text(
//                         //   '${DateFormat("dd MMM yyyy").format(DateTime.parse(route['startDate']))} to ${DateFormat("dd MMM yyyy").format(DateTime.parse(route['endDate']))}',
//                         //   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                         // ),
//
//                         Text(
//                           '${DateFormat("dd MMM yyyy").format(DateTime.parse(route['startDate']))} ',
//                           style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: Icon(Icons.delete_outline, color: Colors.redAccent),
//                       onPressed: () async {
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (BuildContext dialogContext) {
//                             return AlertDialog(
//                               title: Text("Delete Route"),
//                               content: Text("Are you sure you want to delete this route? This will also remove related dealers from schedule."),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(dialogContext, false),
//                                   child: Text("Cancel"),
//                                 ),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.redAccent,
//                                     foregroundColor: Colors.white,
//                                   ),
//                                   onPressed: () => Navigator.pop(dialogContext, true),
//                                   child: Text("Delete"),
//                                 ),
//
//                               ],
//                             );
//                           },
//                         );
//
//                         if (confirm == true) {
//                           final success = await ref.read(routePlanProvider.notifier).deleteRoute(route['_id']);
//                           if (success) {
//                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Route deleted successfully")));
//                             _fetchRoutes();
//                           }
//                         }
//                       },
//                     ),
//                   ),
//                 );
//
//               },
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
// }
