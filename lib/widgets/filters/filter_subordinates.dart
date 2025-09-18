import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sales_filter_provider.dart';
import '../../providers/subordinates_provider.dart';
import '../../utils/subordinate_shimmer_loader.dart';

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

  Future<void> _openFiltersPopup(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(builder: (context, ref, _) {
          final subordinatesData = ref.watch(subordinatesProvider).value ?? {};
          final filterState = ref.watch(salesFilterProvider);
          String activeFilter = activePosition ?? subordinatesData.keys.first;


          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Row(
                children: [
                  // LEFT SIDE FILTER TYPES
                  Container(
                    width: 120,
                    color: Colors.grey.shade100,
                    child: ListView(
                      children: subordinatesData.keys.map((position) {
                        return ListTile(
                          selected: activeFilter == position,
                          title: Text(position,
                              style: TextStyle(
                                  fontWeight: activeFilter == position
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: activeFilter == position
                                      ? Colors.deepPurple
                                      : Colors.black87)),
                          onTap: () {
                            setState(() => activeFilter = position);
                            activePosition = position; // 👈 persist selection
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  // RIGHT SIDE OPTIONS
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                    Expanded(
                    child: SingleChildScrollView(
                    child: _buildFilterOptions(
                      activeFilter,
                      subordinatesData[activeFilter] ?? [],
                      filterState,
                      ref,
                      setState,
                    ),
                  ),
                ),
                        ElevatedButton(
                          onPressed: () {
                            final filter = ref.read(salesFilterProvider);
                            ref.read(subordinatesProvider.notifier).fetchSubordinates(
                              filterType: filter.selectedType,
                              startDate: filter.startDate,
                              endDate: filter.endDate,
                            );
                            Navigator.pop(context);
                          },
                          child: Text("Apply"),
                        ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
      },
    );
  }

  Widget _buildFilterOptions(
      String filterType,
      List<Subordinate> options,
      SalesFilterState filterState,
      WidgetRef ref,
      StateSetter modalSetState,
      ) {
    if (filterType == "product_category") {
      // Category = simple card list
      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final sub = options[index];
          final isSelected = filterState.selectedCategory == sub.code;
          return GestureDetector(
            onTap: () {
              ref.read(salesFilterProvider.notifier).updateCategory(sub.code);
              setState(() {});
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: _buildSubordinateCard(sub, isSelected),
            ),
          );
        },
      );
    }

    // ✅ Other filters → search + dynamic list
    String query = searchQueries[filterType] ?? "";
    final filtered = options
        .where((s) =>
    s.name.toLowerCase().contains(query.toLowerCase()) ||
        s.code.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filtered.length + 1, // +1 for search bar
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                modalSetState(() => searchQueries[filterType] = val);
              },
            ),
          );
        }

        final sub = filtered[index - 1];
        final isSelected = filterState.selectedSubordinateCodes.contains(sub.code);
        return GestureDetector(
          onTap: () {
            final current = [...filterState.selectedSubordinateCodes];
            if (isSelected) {
              current.remove(sub.code);
            } else {
              current.add(sub.code);
            }
            ref.read(salesFilterProvider.notifier).updateSubordinates(current);
            modalSetState(() {});
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: _buildSubordinateCard(sub, isSelected),
          ),
        );
      },
    );
  }




  Future<void> _openCategoryPopup(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(builder: (context, ref, _) {
          final categories =
              ref.watch(subordinatesProvider).value?["product_category"] ?? [];
          final filterState = ref.watch(salesFilterProvider);

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: categories.map<Widget>((sub) {
                final isSelected = filterState.selectedCategory == sub.code;
                return GestureDetector(
                  onTap: () {
                    ref.read(salesFilterProvider.notifier).updateCategory(sub.code);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: _buildSubordinateCard(sub, isSelected),
                  ),
                );
              }).toList(),
            ),
          );
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final selected = ref.read(salesFilterProvider).selectedSubordinateCodes;
    localSelected = _groupByPosition(selected);
  }

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

  Widget _buildSubordinateCard(Subordinate sub, bool isSelected) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.lightBlueAccent.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.black)),
          Text(sub.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),

          // ✅ Stats overview reused
          _buildStatsOverview(sub),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(Subordinate sub) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statBox("MTD", formatIndianNumber(sub.mtdSellOut), Colors.blue),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _statBox("LMTD", formatIndianNumber(sub.lmtdSellOut), Colors.orange),
            ),
            SizedBox(width: 6),
            Expanded(
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
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _statBox("M-1", formatIndianNumber(sub.m1), Color(0xFFCE93D8))),
            SizedBox(width: 6),
            Expanded(child: _statBox("M-2", formatIndianNumber(sub.m2), Color(0xFFA5D6A7))),
            SizedBox(width: 6),
            Expanded(child: _statBox("M-3", formatIndianNumber(sub.m3), Color(0xFF80CBC4))),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _statBox("ADS", formatIndianNumber(sub.ads), Color(0xFFFBC02D))),
            SizedBox(width: 6),
            Expanded(child: _statBox("FTD", formatIndianNumber(sub.ftd), Color(0xFFFF8A65))),
            SizedBox(width: 6),
            Expanded(child: _statBox("Req.ADS", formatIndianNumber(sub.reqAds), Color(0xFFAED581))),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _statBox("TGT", formatIndianNumber(sub.tgt), Color(0xFFB0BEC5))),
            SizedBox(width: 6),
            Expanded(child: _statBox("Contribution", "${sub.contribution.toStringAsFixed(1)}%", Color(0xFF4FC3F7))),
          ],
        ),
      ],
    );
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
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subordinatesState = ref.watch(subordinatesProvider);
    final filterState = ref.watch(salesFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ✅ Filters button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openFiltersPopup(context),
                icon: Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF2D3A63)),
                label: Text(
                  "Filters",
                  style: TextStyle(
                    color: Color(0xFF2D3A63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // ✅ white background
                  foregroundColor: Color(0xFF2D3A63), // ✅ text & icon color
                  elevation: 2, // ✅ subtle shadow
                  shadowColor: Colors.black.withOpacity(0.15), // ✅ soft shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // ✅ smooth rounded corners
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

            ),
            SizedBox(width: 12),

            // ✅ Category button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openCategoryPopup(context),
                icon: Icon(Icons.category_outlined, color: Color(0xFF2D3A63)),
                label: Text(
                  filterState.selectedCategory.isEmpty
                      ? "Category"
                      : "Category: ${filterState.selectedCategory}",
                  style: TextStyle(color: Color(0xFF2D3A63)),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // ✅ white background
                  foregroundColor: Color(0xFF2D3A63), // ✅ text/icon color
                  elevation: 2, // ✅ subtle shadow
                  shadowColor: Colors.black.withOpacity(0.15), // ✅ soft shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // ✅ modern rounded corners
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

            ),
            SizedBox(width: 12),

            // ✅ Clear All button
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // background
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_alt_off_rounded,
                  color: Colors.grey[700], // minimal, neutral tone
                  size: 24,
                ),
                onPressed: () {
                  ref.read(salesFilterProvider.notifier).clearAllFilters();

                  final filter = ref.read(salesFilterProvider);
                  ref.read(subordinatesProvider.notifier).fetchSubordinates(
                    filterType: filter.selectedType,
                    startDate: filter.startDate,
                    endDate: filter.endDate,
                  );
                },
                splashRadius: 24,
              ),
            )


          ],
        ),

      ],
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
