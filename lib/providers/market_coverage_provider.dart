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
        'dealer/mdd': [],
      },
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
        'dealer/mdd': [],
      },
      dateRange: _getDefaultWeekRange(),
      total: 0,
      done: 0,
      pending: 0,
    ),
  );

  static DateTimeRange _getDefaultWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
    fetchCoverageData();
  }

  void resetFilters() {
    state = state.copyWith(
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
        'dealer/mdd': [],
      },
      routes: [],
      dateRange: _getDefaultWeekRange(),
    );
    fetchCoverageData();
  }

  void toggleRoute(String routeName) {
    final current = List<String>.from(state.selectedFilters['routes'] ?? []);

    if (current.contains(routeName)) {
      current.remove(routeName);
    } else {
      current.add(routeName);
    }

    state = state.copyWith(
      selectedFilters: {
        ...state.selectedFilters,
        'routes': current,
      },
    );

    fetchCoverageData();
  }




  void applyFilter(String key, String? value) {
    if (value != null) {
      final updated = [...state.selectedFilters[key]!, value];
      state = state.copyWith(selectedFilters: {
        ...state.selectedFilters,
        key: updated,
      });
      fetchCoverageData();
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

  Future<void> initialize() async {
    for (final field in ['zone', 'district', 'taluka', 'dealer/mdd']) {
      final uri = Uri.parse('${Config.backendUrl}/beat-mapping/dropdown?field=$field');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['values'] != null) {
          state = state.copyWith(dropdownValues: {
            ...state.dropdownValues,
            field: List<String>.from(res['values']),
          });
        }
      }
    }
    await fetchRoutePlans();
    fetchCoverageData();


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

          // Step 1: First set raw data
          state = state.copyWith(
            allDealers: all,
            filteredDealers: all,
            isLoading: false,
          );

          // Step 2: Recalculate distance after state set
          if (currentLocation != null) {
            final updated = [...state.filteredDealers];
            for (final d in updated) {
              final lat = d['latitude'] is Map
                  ? double.tryParse(d['latitude']['\$numberDecimal'].toString()) ?? 0.0
                  : (d['latitude']?.toDouble() ?? 0.0);

              final lng = d['longitude'] is Map
                  ? double.tryParse(d['longitude']['\$numberDecimal'].toString()) ?? 0.0
                  : (d['longitude']?.toDouble() ?? 0.0);


              d['distance'] = Geolocator.distanceBetween(
                currentLocation.latitude,
                currentLocation.longitude,
                lat,
                lng,
              ) / 1000;
            }

            updated.sort((a, b) => (a['distance'] ?? 9999).compareTo(b['distance'] ?? 9999));

            // Step 3: Set again with distance
            state = state.copyWith(
              allDealers: updated,
              filteredDealers: updated,
            );
          }
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
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return {"success": false, "message": "Token not found"};

    final uri = Uri.parse('${Config.backendUrl}/beat-mapping/mark-done');
    final body = json.encode({
      "dealerCode": dealerCode,
      "distance": distance,
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
    final token = await AuthService.getToken();
    if (token == null) return;

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
        state = state.copyWith(routes: routeObjects);

      }
    } catch (e) {
      print("⚠️ Error fetching routes: $e");
    }
  }



}

final marketCoverageProvider =
StateNotifierProvider<MarketCoverageNotifier, MarketCoverageState>((ref) {
  return MarketCoverageNotifier();
});
