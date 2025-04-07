import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';

class BeatMappingStatusScreen extends StatefulWidget {
  @override
  _BeatMappingStatusScreenState createState() =>
      _BeatMappingStatusScreenState();
}

class _BeatMappingStatusScreenState extends State<BeatMappingStatusScreen> {
  List<Map<String, dynamic>> beatData = [];
  String searchQuery = '';
  String statusFilter = 'all';
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchData(reset: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMoreData) {
      fetchData();
    }
  }

  Future<void> fetchData({bool reset = false}) async {
    if (reset) {
      setState(() {
        currentPage = 1;
        beatData.clear();
        hasMoreData = true;
      });
    }

    setState(() => isLoading = true);
    try {
      final newData = await ApiService.getAllWeeklyBeatMapping(
        status: statusFilter,
        searchQuery: searchQuery,
        page: currentPage,
        limit: 20,
      );

      setState(() {
        beatData.addAll(newData);
        currentPage++;
        hasMoreData = newData.length == 20;
      });
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => searchQuery = value);
      fetchData(reset: true);
    });
  }

  void _onFilterChanged(String? newStatus) {
    setState(() => statusFilter = newStatus ?? 'all');
    fetchData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beat Mapping Status")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSearchAndFilter(),
            const SizedBox(height: 12),
            Expanded(child: _buildBeatList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search by name or code",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text("All")),
              DropdownMenuItem(value: 'done', child: Text("Done")),
              DropdownMenuItem(value: 'pending', child: Text("Pending")),
            ],
            onChanged: _onFilterChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBeatList() {
    if (beatData.isEmpty && isLoading) {
      return _buildShimmerList();
    }

    if (beatData.isEmpty) {
      return Center(child: Text("No results found"));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: beatData.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < beatData.length) {
          final emp = beatData[index];
          return BeatCard(emp: emp);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class BeatCard extends StatelessWidget {
  final Map<String, dynamic> emp;

  const BeatCard({super.key, required this.emp});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emp['employeeName'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Code: ${emp['code']}"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBox("Done", emp['totalDone'] ?? 0, Colors.green),
                _buildStatusBox(
                    "Pending", emp['totalPending'] ?? 0, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            label == "Done" ? Icons.check_circle : Icons.pending_actions,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "$label: $count",
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
