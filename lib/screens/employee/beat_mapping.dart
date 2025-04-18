// 🔄 Styled Beat Mapping UI to match design
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/beat_mapping_provider.dart';

class BeatMappingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BeatMappingScreen> createState() => _BeatMappingScreenState();
}

class _BeatMappingScreenState extends ConsumerState<BeatMappingScreen> {
  Position? currentLocation;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getCurrentLocation();
    await ref.read(beatMappingProvider.notifier).initialize();
    await ref.read(beatMappingProvider.notifier).fetchBeatMapping(currentLocation);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      CustomPopup.showPopup(context, "Permission Denied",
          "Location permission is required.", isSuccess: false);
      return;
    }
    currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(beatMappingProvider);
    final controller = ref.read(beatMappingProvider.notifier);
    final dealers = provider.filteredDealers;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text("Beat Mapping"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await controller.fetchBeatMapping(currentLocation);
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilters(controller, provider.dateRange),
          _buildStatsSummary(dealers),
          _buildSearchBar(controller),
          Expanded(child: _buildDealerList(dealers)),
        ],
      ),
    );
  }

  Widget _buildFilters(BeatMappingNotifier controller, DateTimeRange dateRange) {
    final dropdownValues = ref.watch(beatMappingProvider).dropdownValues;
    final formatter = DateFormat('dd MMM');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    controller.setDateRange(picked);
                    controller.fetchBeatMapping(currentLocation);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text("${formatter.format(dateRange.start)} to ${formatter.format(dateRange.end)}"),
                      SizedBox(width: 6),
                      Icon(Icons.calendar_today, size: 16)
                    ],
                  ),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  controller.resetFilters();
                  controller.fetchBeatMapping(currentLocation);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                child: Text("Reset Filters"),
              )
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text("Show Filters", style: TextStyle(fontWeight: FontWeight.w500)),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.only(top: 6),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dropdownValues.entries.map((entry) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      underline: SizedBox(),
                      hint: Text(entry.key),
                      value: null,
                      items: entry.value
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.addFilter(entry.key, val);
                          controller.fetchBeatMapping(currentLocation);
                        }
                      },
                    ),
                  );
                }).toList(),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(BeatMappingNotifier controller) {
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

  Widget _buildStatsSummary(List<dynamic> dealers) {
    int total = dealers.length;
    int done = dealers.where((d) => d['status'] == 'done').length;
    int pending = total - done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBox("Total", total, Colors.orange.shade200, Colors.orange),
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

  Widget _buildDealerList(List<dynamic> dealers) {
    return ListView.builder(
      itemCount: dealers.length,
      itemBuilder: (context, index) {
        final d = dealers[index];
        final isDone = d['status'] == 'done';
        return Card(
          color: isDone ? Colors.green.shade50 : null,
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
                    Column(
                      children: [
                        Icon(Icons.navigation_outlined, size: 18),
                        Text("${d['distance']?.toStringAsFixed(1)} kms")
                      ],
                    )
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(d['zone']),
                    _tag(d['district']),
                    _tag(d['taluka']),
                    _tag(d['position']),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: isDone
                      ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text("Done", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 4),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Text("${d['visits']}", style: TextStyle(fontSize: 10)),
                        )
                      ],
                    ),
                  )
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if ((d['distance'] ?? 9999) > 15000) { // 100 meters = 0.1 km
                        CustomPopup.showPopup(context, "Too Far", "You are more than 100 meters away from the dealer.", isSuccess: false);
                        return;
                      }

                      try {
                        final res = await ref.read(beatMappingProvider.notifier).markDealerDone(
                          dealerCode: d['code'],
                          distance: d['distance'] ?? 0,
                        );

                        if (res['success']) {
                          CustomPopup.showPopup(context, "Success", res['message']);

                          // ✅ Mark as done locally in provider state
                          final updatedDealers = [...ref.read(beatMappingProvider).allDealers];
                          final index = updatedDealers.indexWhere((item) => item['code'] == d['code']);
                          if (index != -1) {
                            updatedDealers[index]['status'] = 'done';
                            updatedDealers[index]['visits'] = (updatedDealers[index]['visits'] ?? 0) + 1;
                            ref.read(beatMappingProvider.notifier).state =
                                ref.read(beatMappingProvider.notifier).state.copyWith(
                                  allDealers: updatedDealers,
                                  filteredDealers: updatedDealers,
                                );
                          }

                        } else {
                          CustomPopup.showPopup(context, "Failed", res['message'], isSuccess: false);
                        }
                      } catch (e) {
                        CustomPopup.showPopup(context, "Error", "Something went wrong.", isSuccess: false);
                      }
                    },

                    child: Text("Mark"),
                  ),
                )
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
