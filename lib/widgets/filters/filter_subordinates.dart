import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subordinates_provider.dart';
import '../../providers/sales_filter_provider.dart';

class FilterSubordinates extends ConsumerStatefulWidget {
  @override
  _FilterSubordinatesState createState() => _FilterSubordinatesState();
}

class _FilterSubordinatesState extends ConsumerState<FilterSubordinates> {
  String? activePosition;
  Map<String, String> searchQueries = {};

  @override
  Widget build(BuildContext context) {
    final subordinatesState = ref.watch(subordinatesProvider);
    final selectedCodes = ref.watch(salesFilterProvider).selectedSubordinateCodes;

    return subordinatesState.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
      data: (data) {
        if (data == null || data.isEmpty) return Center(child: Text("No data available"));

        final positions = data.keys.toList();

        return Column(
          children: [
            // Position Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: positions.map((position) {
                  final subs = (data[position] ?? []).cast<Subordinate>();
                  final selectedCount = subs.where((s) => selectedCodes.contains(s.code)).length;
                  final isActive = activePosition == position;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        activePosition = isActive ? null : position;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8, bottom: 6),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blueGrey : Colors.white,
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
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
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$selectedCount",
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          Icon(
                            isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: isActive ? Colors.white : Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Dropdown content
            if (activePosition != null)
              _buildDropdown(
                context,
                activePosition!,
                data.map((k, v) => MapEntry(k, (v as List).cast<Subordinate>())),
                selectedCodes,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(BuildContext context, String position, Map<String, List<Subordinate>> subordinatesMap, List<String> selectedCodes) {
    final query = searchQueries[position] ?? '';
    final List<Subordinate> allSubs = subordinatesMap[position] ?? [];
    final List<Subordinate> filtered = allSubs.where((sub) =>
    sub.name.toLowerCase().contains(query.toLowerCase()) || sub.code.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return Container(
      height: 280,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 32,
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey[600]),
                SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => searchQueries[position] = val),
                    decoration: InputDecoration.collapsed(hintText: "Search..."),
                    style: TextStyle(fontSize: 13),
                  ),
                )
              ],
            ),
          ),

          // Subordinate list
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final sub = filtered[index];
                final isSelected = selectedCodes.contains(sub.code);

                return GestureDetector(
                  onTap: () {
                    final provider = ref.read(salesFilterProvider.notifier);
                    final updated = List<String>.from(selectedCodes);

                    if (isSelected) {
                      updated.remove(sub.code);
                    } else {
                      updated.add(sub.code);
                    }

                    provider.updateSubordinates(updated);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text(sub.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                                  "${growthValue.toStringAsFixed(0)}%",
                                  growthValue >= 0 ? Colors.green : Colors.red,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _statBox(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
