import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sales_filter_provider.dart';
import '../../providers/subordinates_provider.dart';

class FilterSubordinates extends ConsumerStatefulWidget {
  @override
  _FilterSubordinatesState createState() => _FilterSubordinatesState();
}

class _FilterSubordinatesState extends ConsumerState<FilterSubordinates> {
  Map<String, List<String>> localSelected = {};
  Map<String, String> searchQueries = {};
  String? activePosition;

  @override
  void initState() {
    super.initState();
    // Load existing selected subordinates from provider
    final selected = ref.read(salesFilterProvider).selectedSubordinateCodes;
    localSelected = _groupByPosition(selected);
  }

  @override
  Widget build(BuildContext context) {
    final subordinatesState = ref.watch(subordinatesProvider);
    final filterNotifier = ref.read(salesFilterProvider.notifier);

    return subordinatesState.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
      data: (data) {
        if (data.isEmpty) return Center(child: Text("No data available"));

        List<String> positions = data.keys.toList();

        return Column(
          children: [
            // Top Row of Position Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: positions.map((position) {
                  int count = localSelected[position]?.length ?? 0;
                  bool isActive = activePosition == position;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isActive) {
                          activePosition = null;

                          // Flatten all selected subordinate codes
                          final allSelected = localSelected.values.expand((e) => e).toList();

                          // Read current selected codes from provider
                          final currentSelected = ref.read(salesFilterProvider).selectedSubordinateCodes;

                          // Compare sorted lists to avoid unnecessary updates
                          final isDifferent = !_listEquals(allSelected, currentSelected);

                          if (isDifferent) {
                            filterNotifier.updateSubordinates(allSelected);
                            print("📤 Updated subordinates → $allSelected");
                          }
                        } else {
                          activePosition = position;
                        }
                      });
                    },

                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blueGrey : Colors.white,
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            position,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.blueGrey,
                            ),
                          ),
                          if (count > 0)
                            Container(
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange,
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(color: Colors.white, fontSize: 10),
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

            if (activePosition != null)
              Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          searchQueries[activePosition!] = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search...",
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),

                  // Dropdown List
                  Container(
                    height: 300,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView(
                      children: _buildDropdownItems(
                        data[activePosition!] ?? [],
                        activePosition!,
                      ),
                    ),
                  )
                ],
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDropdownItems(List<Subordinate> subs, String position) {
    String query = searchQueries[position] ?? "";
    final filtered = subs.where((s) =>
    s.name.toLowerCase().contains(query.toLowerCase()) ||
        s.code.toLowerCase().contains(query.toLowerCase())).toList();

    return filtered.map((sub) {
      bool isSelected = localSelected[position]?.contains(sub.code) ?? false;
      return GestureDetector(
        onTap: () {
          setState(() {
            localSelected[position] ??= [];
            if (isSelected) {
              localSelected[position]!.remove(sub.code);
            } else {
              localSelected[position]!.add(sub.code);
            }
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.lightBlueAccent.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(sub.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBox("MTD", "${sub.mtdSellOut}", Colors.blue),
                  _statBox("LMTD", "${sub.lmtdSellOut}", Colors.orange),
                  _statBox(
                    "%Growth",
                    "${double.tryParse(sub.sellOutGrowth)?.toStringAsFixed(0) ?? '0'}%",
                    double.tryParse(sub.sellOutGrowth) != null &&
                        double.parse(sub.sellOutGrowth) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Map<String, List<String>> _groupByPosition(List<String> codes) {
    final Map<String, List<String>> grouped = {};
    final data = ref.read(subordinatesProvider).value ?? {};

    for (var entry in data.entries) {
      grouped[entry.key] = entry.value
          .where((sub) => codes.contains(sub.code))
          .map((sub) => sub.code)
          .toList();
    }

    return grouped;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    return sortedA.every((element) => sortedB.contains(element));
  }

}
