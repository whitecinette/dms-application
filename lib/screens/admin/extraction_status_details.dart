// 📍 Market Coverage UI (Flutter) strictly based on provided screenshot
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/market_coverage_provider.dart';
import '../../utils/custom_pop_up.dart';
import '../../providers/extraction_status_provider.dart';

class ExtractionStatusDetailsScreen extends ConsumerStatefulWidget {
  final String? initialRouteName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String>? initialItinerary;
  final String? userCode;
  final String? userName;

  const ExtractionStatusDetailsScreen({
    this.initialRouteName,
    this.initialStartDate,
    this.initialEndDate,
    this.initialItinerary,
    this.userCode,
    this.userName,
    super.key,
  });

  @override
  ConsumerState<ExtractionStatusDetailsScreen> createState() => _ExtractionStatusDetailsScreen();
}

class _ExtractionStatusDetailsScreen extends ConsumerState<ExtractionStatusDetailsScreen> {
  Position? currentLocation;
  String searchQuery = "";
  late final String? userCode = widget.userCode;
  late final String? userName = widget.userName;
  late DateTimeRange dateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    dateRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
    _initData();
  }

  Future<void> _initData() async {
    final controller = ref.read(extractionStatusProvider.notifier);

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      CustomPopup.showPopup(context, "Permission Denied", "Location permission is required.", isSuccess: false);
      return;
    }

    currentLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    print("\uD83D\uDCCD Location: \${currentLocation?.latitude}, \${currentLocation?.longitude}");

    await controller.fetchDealersWithStatus(
      userCode: userCode ?? '',
      dateRange: dateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(extractionStatusProvider);
    final controller = ref.read(extractionStatusProvider.notifier);
    final dealers = provider.filteredDealers;
    final isLoading = provider.isLoading;
    final formatter = DateFormat("dd MMM");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName ?? "User Name",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.userCode ?? "Code",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              final end = DateTime(now.year, now.month + 1, 0);
              dateRange = DateTimeRange(start: start, end: end);
              await controller.fetchDealersWithStatus(
                userCode: userCode ?? '',
                dateRange: dateRange,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(controller),
          _buildStatsSummary(dealers),
          _buildSearchBar(controller),
          Expanded(child: _buildDealerList(dealers)),
        ],
      ),
    );
  }

  Widget _buildHeader(ExtractionStatusNotifier controller) {
    final formatter = DateFormat('dd MMM');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: dateRange,
                firstDate: DateTime.now().subtract(Duration(days: 365)),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );

              if (picked != null) {
                setState(() {
                  dateRange = picked;
                });

                final loc = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                setState(() {
                  currentLocation = loc;
                });

                await controller.fetchDealersWithStatus(
                  userCode: userCode ?? '',
                  dateRange: picked,
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("${formatter.format(dateRange.start)} to ${formatter.format(dateRange.end)}"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<dynamic> dealers) {
    int total = dealers.length;
    int done = dealers.where((d) => d['status'] == 'done').length;
    int pending = total - done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBox("Total", total, Colors.orange.shade100, Colors.orange),
          _statBox("Done", done, Colors.green.shade100, Colors.green),
          _statBox("Pending", pending, Colors.red.shade100, Colors.red),
        ],
      ),
    );
  }

  Widget _statBox(String title, int value, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
          Text("$value", style: TextStyle(color: fg, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ExtractionStatusNotifier controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blue.shade50,
          prefixIcon: Icon(Icons.search),
          hintText: "Search by name/code",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (val) {
          searchQuery = val;
          controller.applySearch(val);
        },
      ),
    );
  }

  Widget _buildDealerList(List<dynamic> dealers) {
    return ListView.builder(
      itemCount: dealers.length,
      itemBuilder: (context, index) {
        final d = dealers[index];
        final isDone = d['status'] == 'done';
        return Card(
          color: isDone ? Colors.green.shade50 : Colors.red.shade50,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['code'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(d['name'] ?? ''),
                      ],
                    ),
                    // Column(
                    //   children: [
                    //     Icon(Icons.navigation_outlined, size: 18),
                    //     Text("${d['distance']?.toStringAsFixed(1)} kms")
                    //   ],
                    // )
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(d['zone']),
                    _tag(d['district']),
                    _tag(d['town']),
                    _tag(d['position']),
                    if (d['route'] != null) _tag(d['route']),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String? label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label ?? '-', style: TextStyle(fontSize: 12)),
    );
  }
}
