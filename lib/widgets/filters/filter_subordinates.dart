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
  void didChangeDependencies() {
    super.didChangeDependencies();

    final filter = ref.watch(salesFilterProvider);

    // Refetch subordinates with updated filters
    ref.read(subordinatesProvider.notifier).fetchSubordinates(
      filterType: filter.selectedType,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  }


  @override
  void initState() {
    super.initState();
    // Load existing selected subordinates from provider
    final selected = ref.read(salesFilterProvider).selectedSubordinateCodes;
    localSelected = _groupByPosition(selected);
  }

  // Inside filter_subordinates.dart
  String formatIndianNumber(num value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(1)} Cr";
    } else if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(1)} L";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)} K";
    } else {
      return value.toString();
    }
  }


  Widget _buildPositionChip(String position) {
    final count = localSelected[position]?.length ?? 0;
    final isActive = activePosition == position;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            activePosition = null;
            final allSelected = localSelected.values.expand((e) => e).toList();
            final currentSelected = ref.read(salesFilterProvider).selectedSubordinateCodes;

            if (!_listEquals(allSelected, currentSelected)) {
              ref.read(salesFilterProvider.notifier).updateSubordinates(allSelected);
            }
          } else {
            activePosition = position;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5C6F7A) : Colors.white, // softer blueGrey
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              position,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF5C6F7A),
              ),
            ),
            if (count > 0)
              Container(
                margin: EdgeInsets.only(left: 6),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            SizedBox(width: 4),
            Icon(
              isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, // Minimalistic
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF5C6F7A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          localSelected.clear();
          activePosition = null;
          ref.read(salesFilterProvider.notifier).updateSubordinates([]);
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF0F0), // very light red background
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
            SizedBox(width: 6),
            Text(
              "Clear",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
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
            Container(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First horizontal scrollable row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final position in positions.take((positions.length / 2).ceil()))
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildPositionChip(position),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),

                  // Second horizontal scrollable row + Clear
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final position in positions.skip((positions.length / 2).ceil()))
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildPositionChip(position),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildClearButton(),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      color: Color(0x33b49fde),
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
              Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.black)),
              Text(sub.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _statBox("MTD", formatIndianNumber(sub.mtdSellOut), Colors.blue),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: _statBox("LMTD", formatIndianNumber(sub.lmtdSellOut), Colors.orange),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: _statBox(
                          "%Growth",
                          "${double.tryParse(sub.sellOutGrowth)?.toStringAsFixed(0) ?? '0'}%",
                          double.tryParse(sub.sellOutGrowth) != null &&
                              double.parse(sub.sellOutGrowth) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ✅ Second row: M-1 to M-3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _statBox("M-1", formatIndianNumber(sub.m1), const Color(0xFFCE93D8)), // soft brown
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _statBox("M-2", formatIndianNumber(sub.m2), const Color(0xFFA5D6A7)), // soft green
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _statBox("M-3", formatIndianNumber(sub.m3), const Color(0xFF80CBC4)), // soft blue
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ✅ Third row: ADS, FTD, Req. ADS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _statBox("ADS", formatIndianNumber(sub.ads), const Color(0xFFFBC02D)), // pale yellow
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _statBox("FTD", formatIndianNumber(sub.ftd), const Color(0xFFFF8A65)), // soft orange
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _statBox("Req.ADS", formatIndianNumber(sub.reqAds), const Color(0xFFAED581)), // pale green
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ✅ Final row: TGT + Contribution
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _statBox("TGT", formatIndianNumber(sub.tgt), Color(0xFFB0BEC5)),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: _statBox("Contribution", "${sub.contribution.toStringAsFixed(1)}%", const Color(0xFF4FC3F7)), // soft blue
                      ),
                    ],
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
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
