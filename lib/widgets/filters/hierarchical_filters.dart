import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hierarchy_data_stats_provider.dart';


class HierarchicalFilters extends ConsumerStatefulWidget {
  @override
  _HierarchicalFiltersState createState() => _HierarchicalFiltersState();
}

class _HierarchicalFiltersState extends ConsumerState<HierarchicalFilters> {
  String? activeRoot;
  List<List<Subordinate>> cardStack = [];
  Map<String, Subordinate> selectedItem = {}; // one active selection per root
  String searchQuery = "";

  void _openFiltersPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // LEFT FIXED ROOT MENU
                      Container(
                        width: 120,
                        color: Colors.grey.shade100,
                        child: ListView(
                          children: ["Siddha", "District", "Dealer Category"]
                              .map((root) {
                            return ListTile(
                              selected: activeRoot == root,
                              title: Text(
                                root,
                                style: TextStyle(
                                  fontWeight: activeRoot == root
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: activeRoot == root
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                              onTap: () async {
                                setModalState(() {
                                  activeRoot = root;
                                  cardStack.clear();
                                  searchQuery = "";
                                });

                                await _loadRootCards(root, setModalState);
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      // RIGHT SIDE → CARDS
                      Expanded(
                        child: Column(
                          children: [
                            if (selectedItem.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Wrap(
                                  spacing: 6,
                                  children: selectedItem.entries.map((entry) {
                                    return Chip(
                                      label: Text(entry.value.name),
                                      onDeleted: () {
                                        setModalState(() {
                                          selectedItem.remove(entry.key);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Search bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search...",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 12),
                                ),
                                onChanged: (val) => setModalState(
                                      () => searchQuery = val.toLowerCase(),
                                ),
                              ),
                            ),

                            if (cardStack.length > 1)
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.all(8),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text("Back"),
                                  onPressed: () {
                                    setModalState(() {
                                      cardStack.removeLast();
                                    });
                                  },
                                ),
                              ),

                            Expanded(
                              child: cardStack.isEmpty
                                  ? const Center(
                                child: Text("Select a filter from the left"),
                              )
                                  : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: cardStack.last.length,
                                itemBuilder: (context, index) {
                                  final sub = cardStack.last[index];
                                  if (searchQuery.isNotEmpty &&
                                      !sub.name
                                          .toLowerCase()
                                          .contains(searchQuery) &&
                                      !sub.code
                                          .toLowerCase()
                                          .contains(searchQuery)) {
                                    return const SizedBox.shrink();
                                  }

                                  final isSelected =
                                      selectedItem[activeRoot]?.code ==
                                          sub.code;

                                  return GestureDetector(
                                    onTap: () async {
                                      setModalState(() {
                                        selectedItem[activeRoot!] = sub;
                                      });

                                      // Drill down → fetch children if any
                                      final notifier = ref.read(
                                          subordinatesProvider.notifier);
                                      await notifier.fetchSubordinates(
                                        position: sub.position,
                                        parentCode: sub.code,
                                      );

                                      final allSubs =
                                      ref.read(subordinatesProvider);
                                      final children = allSubs.value?[
                                      _nextPosition(sub.position)];

                                      if (children != null &&
                                          children.isNotEmpty) {
                                        setModalState(() {
                                          cardStack.add(children);
                                        });
                                      }
                                    },
                                    child: buildEntityCard(sub, isSelected),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Apply Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () {
                        Navigator.pop(context, selectedItem);
                      },
                      child: const Text("Apply"),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadRootCards(String root, StateSetter setModalState) async {
    final notifier = ref.read(subordinatesProvider.notifier);

    String position;
    if (root == "Siddha") {
      position = "division";
    } else if (root == "District") {
      position = "district";
    } else {
      position = "dealer_category";
    }

    await notifier.fetchSubordinates(position: position);
    final allSubs = ref.read(subordinatesProvider);
    final items = allSubs.value?[position];

    if (items != null && items.isNotEmpty) {
      setModalState(() {
        cardStack.add(items);
      });
    }
  }


  Widget buildEntityCard(Subordinate sub, bool isSelected) {
    Color getGrowthColor(num growth) => growth >= 0 ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple.withOpacity(0.05) : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.code,
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(sub.name,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              _statBox("MTD", _formatIndianNumber(sub.mtdSellOut), Colors.blue),
              const SizedBox(width: 6),
              _statBox(
                  "LMTD", _formatIndianNumber(sub.lmtdSellOut), Colors.orange),
              const SizedBox(width: 6),
              _statBox(
                  "%Growth", "${sub.sellOutGrowth}%", getGrowthColor(double.tryParse(sub.sellOutGrowth) ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  String _nextPosition(String pos) {
    switch (pos.toLowerCase()) {
      case "division": return "asm";
      case "asm": return "mdd";
      case "mdd": return "tse";
      case "tse": return "dealer";
      case "district": return "town";
      default: return "";
    }
  }



  String _formatIndianNumber(num value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(1)} Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)} L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)} K";
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _openFiltersPopup,
      child: const Text("Open Hierarchical Filters"),
    );
  }
}
