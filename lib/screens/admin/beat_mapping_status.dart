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

class BeatCard extends StatefulWidget {
  final Map<String, dynamic> emp;

  const BeatCard({super.key, required this.emp});

  @override
  State<BeatCard> createState() => _BeatCardState();
}

class _BeatCardState extends State<BeatCard> {
  bool showDone = false;
  bool showPending = false;
  List<Map<String, dynamic>> doneDealers = [];
  List<Map<String, dynamic>> pendingDealers = [];
  bool loadingDone = false;
  bool loadingPending = false;

  void fetchDealersByStatus(String status) async {
    final List<dynamic> beatMappings = widget.emp['beatMappings'] ?? [];
    List<Map<String, dynamic>> dealers = [];

    for (final mapping in beatMappings) {
      final schedule = mapping['schedule'] ?? {};
      schedule.forEach((day, dealerList) {
        for (final dealer in dealerList) {
          if (dealer['status'] == status) {
            dealers.add({
              'day': day,
              'dealerName': dealer['name'] ?? '',
              'dealerCode': dealer['code'] ?? '',
            });
          }
        }
      });
    }

    setState(() {
      if (status == 'done') {
        doneDealers = dealers;
        loadingDone = false;
      } else {
        pendingDealers = dealers;
        loadingPending = false;
      }
    });
  }

  void toggleDone() {
    setState(() {
      showDone = !showDone;
      if (showDone) {
        showPending = false;
        if (doneDealers.isEmpty) {
          loadingDone = true;
          fetchDealersByStatus('done');
        }
      }
    });
  }

  void togglePending() {
    setState(() {
      showPending = !showPending;
      if (showPending) {
        showDone = false;
        if (pendingDealers.isEmpty) {
          loadingPending = true;
          fetchDealersByStatus('pending');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.emp;

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Code: ${emp['code']}"),
            const SizedBox(height: 12),
            _buildStatusDropdown(
              title: "Done",
              count: emp['totalDone'] ?? 0,
              isExpanded: showDone,
              color: Colors.green,
              onToggle: toggleDone,
              dealers: doneDealers,
              isLoading: loadingDone,
            ),
            const SizedBox(height: 8),
            _buildStatusDropdown(
              title: "Pending",
              count: emp['totalPending'] ?? 0,
              isExpanded: showPending,
              color: Colors.red,
              onToggle: togglePending,
              dealers: pendingDealers,
              isLoading: loadingPending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color color,
    required List<Map<String, dynamic>> dealers,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      title == "Done" ? Icons.check_circle : Icons.pending_actions,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$title: $count",
                      style: TextStyle(fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: color,
                )
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: isLoading
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: color),
              ),
            )
                : dealers.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "No dealers found",
                style: TextStyle(color: color),
              ),
            )
                : _buildDealerGrid(dealers, color),
          )
      ],
    );
  }

  Widget _buildDealerGrid(List<Map<String, dynamic>> dealers, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int crossAxisCount;

        if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        } else if (width >= 400) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          itemCount: dealers.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5,
          ),
          itemBuilder: (context, index) {
            final dealer = dealers[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 3,
                  )
                ],
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dealer['dealerName'] ?? 'Unnamed',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Code: ${dealer['dealerCode'] ?? '-'}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


