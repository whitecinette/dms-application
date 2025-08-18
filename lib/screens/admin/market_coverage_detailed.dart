// 📍 Market Coverage UI (Flutter) strictly based on provided screenshot
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/market_coverage_provider.dart';
import '../../utils/custom_pop_up.dart';

class MarketCoverageDetailed extends ConsumerStatefulWidget {
  final String? initialRouteName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String>? initialItinerary;
  final String userCode;
  final String userName;

  const MarketCoverageDetailed({
    this.initialRouteName,
    this.initialStartDate,
    this.initialEndDate,
    this.initialItinerary,
    required this.userCode,
    required this.userName,
    super.key,
  });

  @override
  ConsumerState<MarketCoverageDetailed> createState() => _MarketCoverageDetailedState();
}

class _MarketCoverageDetailedState extends ConsumerState<MarketCoverageDetailed> {
  Position? currentLocation;
  bool showFilters = false;
  bool showRoutes = false;
  String searchQuery = "";
  String routeSearchQuery = "";
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final controller = ref.read(marketCoverageProvider.notifier);

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      CustomPopup.showPopup(context, "Permission Denied", "Location permission is required.", isSuccess: false);
      return;
    }

    currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    print("📍 Market Cov coords: \${currentLocation?.latitude}, \${currentLocation?.longitude}");

    controller.state = controller.state.copyWith(isLoading: true);

    await controller.initializeDropdownsOnly();
    await controller.fetchRoutePlans();

    if (widget.initialRouteName != null) {
      controller.updateFilter('routes', [widget.initialRouteName!], fetch: false);

      if (widget.initialStartDate != null && widget.initialEndDate != null) {
        controller.setDateRange(
          DateTimeRange(
            start: widget.initialStartDate!,
            end: widget.initialEndDate!,
          ),
          fetch: false,
        );
      }
    }

    await controller.fetchCoverageData(
      currentLocation: currentLocation,
      userCode: widget.userCode.isEmpty ? null : widget.userCode,
    );

  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(marketCoverageProvider);
    final controller = ref.read(marketCoverageProvider.notifier);
    final allDealers = provider.filteredDealers;
    final dealers = selectedStatus == 'all'
        ? allDealers
        : allDealers.where((d) => d['status'] == selectedStatus).toList();

    final isLoading = provider.isLoading;
    final dateRange = provider.dateRange;
    final formatter = DateFormat("dd MMM");

    print("Filtered dealers: \$dealers");

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            Text(widget.userName, style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              if (currentLocation == null) return;
              await controller.fetchCoverageData(currentLocation: currentLocation, userCode: widget.userCode);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(controller, dateRange),
          _buildToggleBar(dateRange),
          if (showFilters) _buildFilterDropdowns(controller, provider),
          if (showRoutes) _buildRouteDropdown(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // color: Colors.blue.shade50,
                // borderRadius: BorderRadius.circular(10),
                // border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Status: "),
                  SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      icon: Icon(Icons.keyboard_arrow_down),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text("All")),
                        DropdownMenuItem(value: 'done', child: Text("Done")),
                        DropdownMenuItem(value: 'pending', child: Text("Pending")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),


          _buildStatsSummary(dealers),
          _buildSearchBar(controller),
          Expanded(child: _buildDealerList(dealers)),
        ],
      ),
    );
  }


  Widget _buildHeader(MarketCoverageNotifier controller, DateTimeRange dateRange) {
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
                controller.setDateRange(picked);

                // 🔁 Refresh the location correctly
                final loc = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                setState(() {
                  currentLocation = loc;
                });

                // 🔁 Now fetch using updated date + location
                await controller.fetchCoverageData(currentLocation: loc);
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
          Spacer(),
          TextButton(
            onPressed: () {
              controller.resetFilters();
              controller.fetchCoverageData(currentLocation: currentLocation);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange.shade200),
            ),
            child: Text("Reset Filters"),
          )
        ],
      ),
    );
  }

  Widget _buildToggleBar(DateTimeRange range) {
    final selectedRouteCount = ref.watch(marketCoverageProvider).selectedFilters['routes']?.length ?? 0;
    final formatter = DateFormat('dd MMM');

    return Container(
      color: Colors.blue.shade50,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() {
                  showFilters = !showFilters;
                  if (showFilters) showRoutes = false;
                }),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Text("Show Filters"),
                        SizedBox(width: 6),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.orange,
                          child: Text(
                            _getSelectedFilterCount().toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    Icon(showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  final shouldShow = !showRoutes;

                  setState(() {
                    showRoutes = shouldShow;
                    if (shouldShow) showFilters = false;
                  });

                  if (shouldShow) {
                    ref.read(marketCoverageProvider.notifier).fetchRoutePlans();
                  }
                },
                child: Row(
                  children: [
                    Text("Show Routes"),
                    SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.orange,
                      child: Text("$selectedRouteCount", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    Icon(showRoutes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // Text(
          //   "Selected Dates: ${formatter.format(range.start)} to ${formatter.format(range.end)}",
          //   style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          // ),
        ],
      ),
    );
  }

  Widget _buildRouteDropdown() {
    final provider = ref.watch(marketCoverageProvider);
    final routes = provider.routes;
    final isLoading = provider.isLoading;

    if (provider.isRouteLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (routes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "No routes found, please refresh or add new!",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }


    return SizedBox(
      height: 300, // Set a height so the dropdown is scrollable
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search Routes",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() {
                  routeSearchQuery = val.toLowerCase().trim();
                });
              },
            ),

          ),
          Expanded(
            child: ListView(
              children: routes.where((r) {
                final name = (r['name'] ?? '').toString().toLowerCase();
                final itineraryString = (r['itinerary'] ?? []).join(',').toLowerCase();
                return name.contains(routeSearchQuery) || itineraryString.contains(routeSearchQuery);
              }).map((r) {
                final itineraryList = (r['itinerary'] ?? []) as List<dynamic>;
                final itinerary = itineraryList.join(', ');
                final start = DateFormat("dd MMM yyyy").format(DateTime.tryParse(r['startDate'] ?? '') ?? DateTime.now());
                final end = DateFormat("dd MMM yyyy").format(DateTime.tryParse(r['endDate'] ?? '') ?? DateTime.now());

                final isSelected = provider.selectedFilters['routes']?.contains(r['name']) ?? false;

                return InkWell(
                  onTap: () async {
                    final notifier = ref.read(marketCoverageProvider.notifier);
                    notifier.toggleRoute(r['name'] ?? '');
                    await notifier.fetchCoverageData(currentLocation: currentLocation);// 👈 You need to define this method in the provider
                  },

                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.near_me_outlined, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r['name'] ?? ''}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                itinerary,
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "$start to $end",
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterDropdowns(MarketCoverageNotifier controller, MarketCoverageState provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.dropdownValues.keys.map((filter) {
              final selectedValues = provider.selectedFilters[filter] ?? [];

              // 👇 Get dropdown items safely using null-aware operator
              final dropdownItems = provider.dropdownValues[filter]
                  ?.map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
                  .toList();

              // 👇 Show loader if items not fetched yet
              if (dropdownItems == null) {
                return Container(
                  width: 120,
                  height: 40,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      underline: SizedBox(),
                      hint: Text(filter),
                      value: null,
                      items: dropdownItems,
                      onChanged: (val) => controller.applyFilter(filter, val),
                    ),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: selectedValues.map((val) {
                      return Chip(
                        label: Text(val),
                        backgroundColor: Colors.blue.shade100,
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          final updated = [...selectedValues]..remove(val);
                          controller.updateFilter(filter, updated);
                        },
                      );
                    }).toList(),
                  )
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => controller.fetchCoverageData(),
              icon: Icon(Icons.check_circle_outline),
              label: Text("Apply Filters"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildSearchBar(MarketCoverageNotifier controller) {
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

  Widget _summaryCard({
    required String label,
    required int overall,
    required int today,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text("Overall/Today", style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("$overall", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const Text(" / "),
              Text("$today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatsSummary(List<dynamic> dealers) {
    final state = ref.watch(marketCoverageProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryCard(
            label: "Total",
            overall: state.ovTotal,
            today: state.total,
            bgColor: Colors.orange.shade100,
            textColor: Colors.brown,
          ),
          _summaryCard(
            label: "Done",
            overall: state.ovDone,
            today: state.done,
            bgColor: Colors.green.shade100,
            textColor: Colors.green.shade800,
          ),
          _summaryCard(
            label: "Pending",
            overall: state.ovPending,
            today: state.pending,
            bgColor: Colors.red.shade100,
            textColor: Colors.red.shade700,
          ),
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
                    // _tag(d['taluka']),
                    _tag(d['town']),
                    _tag(d['position']),
                    if (d['route'] != null) _tag(d['route']),
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
                          ),
                          SizedBox(width: 6),
                          // ✅ Show marked time if available, else blank
                          Text(
                            d['markedDoneAtText'] ?? "na ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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


                      final userLat = currentLocation?.latitude;
                      final userLng = currentLocation?.longitude;
                      final dealerLat = d['latitude'];
                      final dealerLng = d['longitude'];

                      print("🧭 User Location: ($userLat, $userLng)");
                      print("🏪 Dealer Location: ($dealerLat, $dealerLng)");
                      print("📏 Distance: ${d['distance']?.toStringAsFixed(2)} km");

                      if ((d['distance'] ?? 9999) > 15.0) {
                        CustomPopup.showPopup(context, "Too Far", "You are more than 100 meters away from the dealer.", isSuccess: false);
                        return;
                      }

                      try {
                        // final res = await ref.read(marketCoverageProvider.notifier).markDealerDone(
                        //   dealerCode: d['code'],
                        //   distance: d['distance'] ?? 0,
                        // );


                        ///CHECKINGG
                        ///
                        final res = await ref.read(marketCoverageProvider.notifier).markDealerDone(
                          dealerCode: d['code'],
                          distance: d['distance'] ?? 0,
                          userLat: currentLocation?.latitude,
                          userLng: currentLocation?.longitude,
                          dealerLat: d['latitude'],
                          dealerLng: d['longitude'],
                        );


                        if (res['success']) {
                          CustomPopup.showPopup(context, "Success", res['message']);

                          final updatedDealers = [...ref.read(marketCoverageProvider).allDealers];
                          final index = updatedDealers.indexWhere((item) => item['code'] == d['code']);
                          if (index != -1) {
                            updatedDealers[index]['status'] = 'done';
                            updatedDealers[index]['visits'] = (updatedDealers[index]['visits'] ?? 0) + 1;
                            ref.read(marketCoverageProvider.notifier).state =
                                ref.read(marketCoverageProvider.notifier).state.copyWith(
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

  int _getSelectedFilterCount() {
    final filters = ref.read(marketCoverageProvider).selectedFilters;
    int total = 0;
    for (final entry in filters.entries) {
      if (entry.key != 'routes') {
        total += entry.value.length;
      }
    }
    return total;
  }



}
