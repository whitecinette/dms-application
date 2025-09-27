import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hierarchy_data_stats_provider.dart';

class HierarchicalFilters extends ConsumerStatefulWidget {
  const HierarchicalFilters({Key? key}) : super(key: key);

  @override
  ConsumerState<HierarchicalFilters> createState() => _HierarchicalFiltersState();
}

class _HierarchicalFiltersState extends ConsumerState<HierarchicalFilters> {
  String activePosition = "division"; // default root
  List<Subordinate> currentList = [];
  List<Subordinate> history = []; // breadcrumb stack
  Subordinate? selected;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadSubordinates("division"); // load root immediately
  }

  Future<void> _loadSubordinates(String position, {String? parentCode}) async {
    final notifier = ref.read(subordinatesProvider.notifier);
    await notifier.fetchSubordinates(position: position, parentCode: parentCode);

    final subsState = ref.read(subordinatesProvider);
    subsState.whenData((map) {
      final items = map[position];
      if (items != null && items.isNotEmpty) {
        setState(() {
          currentList = items;
          activePosition = position;
        });
        print("🔍 Loaded ${items.length} items for $position"); // 👈 debug print
      } else {
        setState(() {
          currentList = [];
        });
        print("⚠️ No items found for $position"); // 👈 debug print
      }
    });
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

  void _drillDown(Subordinate sub) async {
    final nextPos = _nextPosition(sub.position);
    if (nextPos.isEmpty) {
      setState(() => selected = sub);
      return;
    }

    history.add(sub);
    await _loadSubordinates(nextPos, parentCode: sub.code);
  }

  void _goBack() {
    if (history.isEmpty) return;
    final last = history.removeLast();
    _loadSubordinates(last.position, parentCode: history.isEmpty ? null : history.last.code);
  }

  Color getGrowthColor(num growth) => growth >= 0 ? Colors.green : Colors.red;

  String _formatIndianNumber(num value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(1)} Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)} L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)} K";
    return value.toString();
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
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
          Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(sub.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Row 1 → MTD, LMTD, Growth
          Row(
            children: [
              _statBox("MTD", _formatIndianNumber(sub.mtdSellOut), Colors.blue),
              _statBox("LMTD", _formatIndianNumber(sub.lmtdSellOut), Colors.orange),
              _statBox("%Growth",
                  "${sub.sellOutGrowth.toStringAsFixed(2)}%",
                  getGrowthColor(sub.sellOutGrowth)),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2 → M-1, M-2, M-3
          Row(
            children: [
              _statBox("M-1", _formatIndianNumber(sub.m1), Colors.purple),
              _statBox("M-2", _formatIndianNumber(sub.m2), Colors.teal),
              _statBox("M-3", _formatIndianNumber(sub.m3), Colors.brown),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3 → ADS, FTD, TGT
          Row(
            children: [
              _statBox("ADS", sub.ads.toStringAsFixed(2), Colors.indigo),
              _statBox("FTD", _formatIndianNumber(sub.ftd), Colors.green),
              _statBox("TGT", _formatIndianNumber(sub.tgt), Colors.redAccent),
            ],
          ),
          const SizedBox(height: 6),

          // Row 4 → Req.ADS, Contribution
          Row(
            children: [
              _statBox("Req.ADS", sub.reqAds.toStringAsFixed(2), Colors.deepOrange),
              _statBox("Contribution",
                  "${sub.contribution.toStringAsFixed(2)}%", Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hierarchy Filters"),
        leading: history.isNotEmpty
            ? IconButton(icon: Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
      ),
      body: Column(
        children: [
          // Breadcrumbs
          if (history.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Wrap(
                children: history.map((e) => Chip(label: Text(e.name))).toList(),
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: currentList
                  .where((sub) =>
              sub.name.toLowerCase().contains(searchQuery) ||
                  sub.code.toLowerCase().contains(searchQuery))
                  .map((sub) {
                final isSelected = selected?.code == sub.code;
                return GestureDetector(
                  onTap: () => _drillDown(sub),
                  child: buildEntityCard(sub, isSelected),
                );
              })
                  .toList(),
            ),
          ),


          // Apply
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                onPressed: () => Navigator.pop(context, selected),
                child: const Text("Apply"),
              ),
            ),
          )
        ],
      ),
    );
  }
}
