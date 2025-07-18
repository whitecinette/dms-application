import 'package:siddhaconnect/widgets/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:siddhaconnect/services/api_service.dart';
import 'package:shimmer/shimmer.dart';  // Import shimmer package
import 'custom_pop_up.dart';

Future<String?> showDealerSelectionDialog(BuildContext context) async {
  String? selectedDealerCode;
  bool isLoading = true;
  List<Map<String, dynamic>> dealers = [];
  List<Map<String, dynamic>> filteredDealers = [];
  TextEditingController searchController = TextEditingController();

  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            // Fetch data only once
            ApiService.getJaipurDealers().then((result) {
              setState(() {
                dealers = result;
                filteredDealers = result;
                isLoading = false;
              });
            }).catchError((error) {
              setState(() {
                isLoading = false;
              });
              Navigator.of(context).pop();
              CustomPopup.showPopup(context, "Error", "Failed to load dealers.");
            });

            // Show shimmer while loading
            return AlertDialog(
              title: Text("Select Dealer"),
              content: SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ShimmerLoader(), // <<=== your shimmer loader
              ),
            );
          }

          // Filter dealers based on search query
          void filterDealers(String query) {
            setState(() {
              filteredDealers = dealers.where((dealer) {
                final code = dealer['code'].toLowerCase();
                final name = dealer['name'].toLowerCase();
                final searchQuery = query.toLowerCase();
                return code.contains(searchQuery) || name.contains(searchQuery);
              }).toList();
            });
          }

          return AlertDialog(
            title: Text("Select Dealer"),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Dealer',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: filterDealers,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredDealers.length,
                      itemBuilder: (context, index) {
                        final dealer = filteredDealers[index];
                        final code = dealer['code'];
                        final name = dealer['name'];
                        final isSelected = selectedDealerCode == code;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDealerCode = code;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.store, color: Colors.blueAccent),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: selectedDealerCode != null
                    ? () => Navigator.of(context).pop(selectedDealerCode)
                    : null,
                child: Text("Select"),
              ),
            ],
          );
        },
      );
    },
  );
}
