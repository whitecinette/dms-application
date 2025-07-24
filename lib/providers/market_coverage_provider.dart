// 📦 Market Coverage Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';


typedef Dealer = Map<String, dynamic>;

class MarketCoverageState {
  final bool isLoading;
  final bool isRouteLoading;
  final List<Dealer> allDealers;
  final List<Dealer> filteredDealers;
  final List<Map<String, dynamic>> routes;
  final Map<String, List<String>> dropdownValues;
  final Map<String, List<String>> selectedFilters;
  final DateTimeRange dateRange;
  final int total;
  final int done;
  final int pending;

  MarketCoverageState({
    required this.isLoading,
    this.isRouteLoading = false,
    required this.allDealers,
    required this.filteredDealers,
    required this.routes,
    required this.dropdownValues,
    required this.selectedFilters,
    required this.dateRange,
    required this.total,
    required this.done,
    required this.pending,
  });

  MarketCoverageState copyWith({
    bool? isLoading,
    bool? isRouteLoading,
    List<Dealer>? allDealers,
    List<Dealer>? filteredDealers,
    List<Map<String, dynamic>>? routes, // ✅ Fix here
    Map<String, List<String>>? dropdownValues,
    Map<String, List<String>>? selectedFilters,
    DateTimeRange? dateRange,
    int? total,
    int? done,
    int? pending,
  }) {
    return MarketCoverageState(
      isLoading: isLoading ?? this.isLoading,
      isRouteLoading: isRouteLoading ?? this.isRouteLoading,
      allDealers: allDealers ?? this.allDealers,
      filteredDealers: filteredDealers ?? this.filteredDealers,
      routes: routes ?? this.routes, // ✅ Matches the new type
      dropdownValues: dropdownValues ?? this.dropdownValues,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      dateRange: dateRange ?? this.dateRange,
      total: total ?? this.total,
      done: done ?? this.done,
      pending: pending ?? this.pending,
    );
  }

}

class MarketCoverageNotifier extends StateNotifier<MarketCoverageState> {
  MarketCoverageNotifier()
      : super(
    MarketCoverageState(
      isLoading: false,
      allDealers: [],
      filteredDealers: [],
      routes: [],
      dropdownValues: {
        'status': ['done', 'pending'],
        'zone': [],
        'district': [],
        'taluka': [],
        'town': [],
        'dealer/mdd': [],
      },
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
        'town': [],
        'dealer/mdd': [],
        'routes': [],
      },
      dateRange: _getDefaultWeekRange(),
      total: 0,
      done: 0,
      pending: 0,
    ),
  );
  List<Map<String, dynamic>> _lastFetchedRoutes = [];

  static DateTimeRange _getDefaultWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  void setDateRange(DateTimeRange range, {bool fetch = true}) {
    state = state.copyWith(dateRange: range);
    if (fetch) fetchCoverageData();
  }


  void resetFilters() {
    state = state.copyWith(
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
        'town': [],
        'dealer/mdd': [],
      },
      routes: [],
      dateRange: _getDefaultWeekRange(),
    );
    fetchCoverageData();
  }

  Future<void> toggleRoute(String routeName) async {
    // 1. Get all available routes
    final allRoutes = _lastFetchedRoutes;

    // 2. Get current selected route names
    final currentSelected = List<String>.from(state.selectedFilters['routes'] ?? []);

    // 3. Toggle the selected route
    if (currentSelected.contains(routeName)) {
      currentSelected.remove(routeName);
    } else {
      currentSelected.add(routeName);
    }

    // 4. Get the full route objects from allRoutes based on updated selection
    final selectedRoutes = allRoutes.where((r) => currentSelected.contains(r['name'])).toList();

    // 5. Calculate combined start and end date range
    DateTime? minStart;
    DateTime? maxEnd;
    for (final route in selectedRoutes) {
      final start = DateTime.tryParse(route['startDate'] ?? '');
      final end = DateTime.tryParse(route['endDate'] ?? '');
      if (start != null && (minStart == null || start.isBefore(minStart))) {
        minStart = start;
      }
      if (end != null && (maxEnd == null || end.isAfter(maxEnd))) {
        maxEnd = end;
      }
    }

    // 6. Update state properly
    state = state.copyWith(
      routes: selectedRoutes, // for UI info
      selectedFilters: {
        ...state.selectedFilters,
        'routes': currentSelected, // ✅ This line is the key!
      },
      dateRange: (minStart != null && maxEnd != null)
          ? DateTimeRange(start: minStart, end: maxEnd)
          : state.dateRange,
    );
  }





  void applyFilter(String key, String? value) {
    if (value != null) {
      final updated = [...state.selectedFilters[key]!, value];
      state = state.copyWith(selectedFilters: {
        ...state.selectedFilters,
        key: updated,
      });
      // fetchCoverageData();
    }
  }

  void applySearch(String query) {
    final filtered = state.allDealers.where((d) {
      return d['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          d['code'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
    state = state.copyWith(filteredDealers: filtered);
  }

  List<String> getDropdownOptions(String key) {
    return state.dropdownValues[key] ?? [];
  }

  Future<void> initialize({bool skipFetch = false}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print("❌ No token found");
      return;
    }

    final uri = Uri.parse('${Config.backendUrl}/user/market-coverage/dropdown');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['success'] == true) {
        final Map<String, List<String>> newDropdownValues = {};
        res.forEach((key, value) {
          if (key != 'success' && value is List) {
            newDropdownValues[key] = List<String>.from(value);
          }
        });
        state = state.copyWith(dropdownValues: newDropdownValues);
        print("🟦 Fetched Dropdown Values: $newDropdownValues");
      }
    } else {
      print("❌ Failed to fetch dropdowns: ${response.statusCode} - ${response.body}");
    }

    await fetchRoutePlans();
    if (!skipFetch) {
      await fetchCoverageData();
    }
  }

  Future<void> fetchCoverageData({Position? currentLocation}) async {
    state = state.copyWith(isLoading: true);

    final startDate = DateFormat("yyyy-MM-dd").format(state.dateRange.start);
    final endDate = DateFormat("yyyy-MM-dd").format(state.dateRange.end);

    final token = await AuthService.getToken();
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final uri = Uri.parse('${Config.backendUrl}/get-beat-mapping-report');
    final body = json.encode({
      "startDate": startDate,
      "endDate": endDate,
      "status": state.selectedFilters["status"],
      "zone": state.selectedFilters["zone"],
      "district": state.selectedFilters["district"],
      "taluka": state.selectedFilters["taluka"],
      "travel": [],
      "routes": state.selectedFilters["routes"] ?? [],
      "town": state.selectedFilters["town"] ?? [],  // ✅ Add this
    });

    if (currentLocation == null) {
      try {
        currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print("⚠️ Failed to fetch location: $e");
      }
    }

    try {
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['data'] != null) {
          final List<Dealer> all = List.from(res['data']);

          // Step 1: Add distance to all dealers
          for (final d in all) {
            final lat = d['latitude'] is Map
                ? double.tryParse(d['latitude']['\$numberDecimal'].toString()) ?? 0.0
                : (d['latitude']?.toDouble() ?? 0.0);

            final lng = d['longitude'] is Map
                ? double.tryParse(d['longitude']['\$numberDecimal'].toString()) ?? 0.0
                : (d['longitude']?.toDouble() ?? 0.0);

            if (currentLocation != null) {
              d['distance'] = Geolocator.distanceBetween(
                currentLocation.latitude,
                currentLocation.longitude,
                lat,
                lng,
              ) / 1000;
            } else {
              d['distance'] = null;
            }
          }

          // Step 2: Get route itinerary list
          final selectedRouteNames = state.routes.map((r) => r['name']).toList();

          final itinerarySet = <String>{};
          for (final r in state.routes) {
            if (selectedRouteNames.contains(r['name'])) {
              final items = r['itinerary'] as List<dynamic>? ?? [];
              itinerarySet.addAll(items.map((e) => e.toString()));
            }
          }

          // Step 3: Apply all filters
          final filtered = all.where((d) {
            final statusMatch = state.selectedFilters['status']!.isEmpty || state.selectedFilters['status']!.contains(d['status']);
            final zoneMatch = state.selectedFilters['zone']!.isEmpty || state.selectedFilters['zone']!.contains(d['zone']);
            final distMatch = state.selectedFilters['district']!.isEmpty || state.selectedFilters['district']!.contains(d['district']);
            final talukaMatch = state.selectedFilters['taluka']!.isEmpty || state.selectedFilters['taluka']!.contains(d['taluka']);
            // final townMatch = state.selectedFilters['town']!.isEmpty || state.selectedFilters['town']!.contains(d['town']);
            final townMatch = (state.selectedFilters['town'] ?? []).isEmpty || (state.selectedFilters['town'] ?? []).contains(d['town']);

            final positionMatch = state.selectedFilters['dealer/mdd']!.isEmpty || state.selectedFilters['dealer/mdd']!.contains(d['position']);
            final routeMatch = itinerarySet.isEmpty || itinerarySet.contains(d['town']);
            return statusMatch && zoneMatch && distMatch && talukaMatch && positionMatch && townMatch && routeMatch;
          }).toList();

          filtered.sort((a, b) => (a['distance'] ?? 9999).compareTo(b['distance'] ?? 9999));

          // Step 4: Update state
          state = state.copyWith(
            allDealers: all,
            filteredDealers: filtered,
            isLoading: false,
          );
          return;
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      print("Error in fetchCoverageData: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>> markDealerDone({
    required String dealerCode,
    required double distance,
    double? userLat,
    double? userLng,
    double? dealerLat,
    double? dealerLng,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return {"success": false, "message": "Token not found"};

    final uri = Uri.parse('${Config.backendUrl}/beat-mapping/mark-done');
    final body = json.encode({
      "dealerCode": dealerCode,
      "distance": distance,
      "userLat" : userLat,
      "userLng" : userLng,
      "dealerLat" : dealerLat,
      "dealerLng" : dealerLng,
    });

    try {
      final response = await http.put(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      final res = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": res['message'] ?? "Marked successfully"
        };
      } else {
        return {
          "success": false,
          "message": res['message'] ?? "Failed to mark dealer"
        };
      }
    } catch (e) {
      print("Error in markDealerDone: $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }

  Future<void> fetchRoutePlans() async {
    state = state.copyWith(isRouteLoading: true); // 🔄 Start loading

    final token = await AuthService.getToken();
    if (token == null) {
      state = state.copyWith(isRouteLoading: false); // ❌ Stop loading if no token
      return;
    }

    final uri = Uri.parse('${Config.backendUrl}/user/route-plan/get');
    final body = json.encode({
      "startDate": DateFormat("yyyy-MM-dd").format(state.dateRange.start),
      "endDate": DateFormat("yyyy-MM-dd").format(state.dateRange.end),
    });

    try {
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final List<Map<String, dynamic>> routeObjects = List<Map<String, dynamic>>.from(res['data']);

        _lastFetchedRoutes = routeObjects;

        state = state.copyWith(
          routes: routeObjects,
          isRouteLoading: false, // ✅ Stop loading on success
        );
      } else {
        state = state.copyWith(isRouteLoading: false); // ❌ Stop loading on error
      }
    } catch (e) {
      print("⚠️ Error fetching routes: $e");
      state = state.copyWith(isRouteLoading: false); // ❌ Stop loading on exception
    }
  }

  Future<void> updateDateRangeBasedOnRoutes() async {
    final selectedRouteNames = state.selectedFilters['routes'] ?? [];
    final selectedRoutes = state.routes.where((r) => selectedRouteNames.contains(r['name'])).toList();

    if (selectedRoutes.isEmpty) return;

    final startDates = selectedRoutes.map((r) => DateTime.tryParse(r['startDate'] ?? '')).whereType<DateTime>();
    final endDates = selectedRoutes.map((r) => DateTime.tryParse(r['endDate'] ?? '')).whereType<DateTime>();

    if (startDates.isEmpty || endDates.isEmpty) return;

    final newStart = startDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final newEnd = endDates.reduce((a, b) => a.isAfter(b) ? a : b);

    state = state.copyWith(dateRange: DateTimeRange(start: newStart, end: newEnd));
    fetchCoverageData(); // 🔁 Refresh based on new dates
  }

  void updateFilter(String key, List<String> updatedList) {
    print("🔄 Updating filter: $key => $updatedList"); // 👈 Log the change

    state = state.copyWith(selectedFilters: {
      ...state.selectedFilters,
      key: updatedList,
    });

    print("✅ Current selectedFilters: ${state.selectedFilters}"); // 👈 See full state
    fetchCoverageData();
  }





}

final marketCoverageProvider =
StateNotifierProvider<MarketCoverageNotifier, MarketCoverageState>((ref) {
  return MarketCoverageNotifier();
});
