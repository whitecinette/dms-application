import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subordinates_provider.dart';

class FilterSubordinates extends ConsumerStatefulWidget {
  @override
  _FilterSubordinatesState createState() => _FilterSubordinatesState();
}

class _FilterSubordinatesState extends ConsumerState<FilterSubordinates> {
  Map<String, List<String>> selectedSubordinates = {};
  Map<String, String> searchQueries = {};
  String? activePosition; // ✅ Default is null (all dropdowns closed)

  @override
  Widget build(BuildContext context) {
    final subordinatesState = ref.watch(subordinatesProvider);
    final double dropdownHeight = 280; // Fixed height for the dropdown

    return subordinatesState.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
      data: (data) {
        if (data == null || data.isEmpty) {
          return Center(child: Text("No data available"));
        }

        List<String> positions = data.keys.toList();
        Map<String, List<Subordinate>> subordinatesMap = data.map((key, value) => MapEntry(
            key,
            (value as List).cast<Subordinate>()
        ));

        return Column(
          children: [
            // **Position Buttons**
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // ✅ Enables horizontal scrolling
              child: Container(
                width: MediaQuery.of(context).size.width, // ✅ Makes the row 100vw
                padding: EdgeInsets.symmetric(horizontal: 2), // ✅ Adds 2px horizontal padding
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: positions.map((position) {
                    int selectedCount = selectedSubordinates[position]?.length ?? 0;
                    bool isActive = activePosition == position; // ✅ Check if dropdown is open

                    return GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            activePosition = (activePosition == position) ? null : position; // ✅ Toggle dropdown
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: EdgeInsets.only(right: 6, bottom: 6), // ✅ Small gap between buttons
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blueGrey : Colors.white, // ✅ Highlight active dropdown
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.blueGrey, width: 1), // ✅ 1px border around button
                        ),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  position,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (selectedCount > 0)
                                  Container(
                                    margin: EdgeInsets.only(left: 4),
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$selectedCount",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            Icon(
                              isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down, // ✅ Change icon on toggle
                              color: isActive ? Colors.white : Colors.blueGrey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // **Search Bar (Only Visible When a Dropdown is Open)**
            if (activePosition != null) // ✅ Hide when dropdown is closed
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                child: Container(
                  height: 32, // ✅ Set fixed height for compactness
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 1),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8), // ✅ Minimal padding
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Colors.grey[600]), // ✅ Compact icon
                      SizedBox(width: 6), // ✅ Small spacing
                      Expanded(
                        child: TextField(
                          onChanged: (val) { // ✅ Search functionality restored
                            if (mounted) {
                              setState(() {
                                searchQueries[activePosition!] = val; // ✅ Updates search query
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Search...",
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]), // ✅ Smaller placeholder text
                            border: InputBorder.none, // ✅ Removes default border
                            isDense: true, // ✅ Makes it compact
                            contentPadding: EdgeInsets.symmetric(vertical: 4), // ✅ Reduces inside space
                          ),
                          style: TextStyle(fontSize: 14), // ✅ Ensures entered text remains readable
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // **Dropdown Content (Only Visible When a Dropdown is Open)**
            if (activePosition != null)
              Container(
                width: double.infinity, // ✅ Full width
                height: dropdownHeight,
                margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10), // ✅ Only 2px horizontal margin
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F3F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildDropdown(activePosition!, subordinatesMap),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String position, Map<String, List<Subordinate>> subordinatesMap) {
    List<Subordinate> filteredSubordinates = subordinatesMap[position] ?? [];
    String query = searchQueries[position] ?? "";

    List<Subordinate> displayedSubordinates = filteredSubordinates.where((sub) =>
    sub.name.toLowerCase().contains(query.toLowerCase()) ||
        sub.code.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: displayedSubordinates.length,
      itemBuilder: (context, index) {
        var sub = displayedSubordinates[index];
        bool isSelected = selectedSubordinates[position]?.contains(sub.code) ?? false;

        return Container(
          width: double.infinity, // ✅ Full width
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 2), // ✅ Only 2px left-right gap
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sub.code,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Text(
                sub.name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBox("MTD", "${sub.mtdSellOut}", Colors.blue),
                  _statBox("LMTD", "${sub.lmtdSellOut}", Colors.orange),
                  Builder(
                    builder: (context) {
                      double growthValue = double.tryParse(sub.sellOutGrowth.toString()) ?? 0;
                      return _statBox(
                        "%Growth",
                        "${growthValue}%",
                        growthValue >= 0 ? Colors.green : Colors.red,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String title, String value, Color color) {
    return Container(
      width: 80, // ✅ Equal width for all stat boxes
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      margin: EdgeInsets.only(right: 2), // ✅ 2px gap between elements
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ Left-align content
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 8, color: Colors.grey[600]), // ✅ Small gray label
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), // ✅ Bigger colored value
          ),
        ],
      ),
    );
  }
}
