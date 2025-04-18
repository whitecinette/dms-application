import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config.dart';
import '../services/auth_service.dart';

typedef Dealer = Map<String, dynamic>;

class BeatMappingState {
  final bool isLoading;
  final List<Dealer> allDealers;
  final List<Dealer> filteredDealers;
  final Map<String, List<String>> dropdownValues;
  final Map<String, List<String>> selectedFilters;
  final DateTimeRange dateRange;

  BeatMappingState({
    required this.isLoading,
    required this.allDealers,
    required this.filteredDealers,
    required this.dropdownValues,
    required this.selectedFilters,
    required this.dateRange,
  });

  BeatMappingState copyWith({
    bool? isLoading,
    List<Dealer>? allDealers,
    List<Dealer>? filteredDealers,
    Map<String, List<String>>? dropdownValues,
    Map<String, List<String>>? selectedFilters,
    DateTimeRange? dateRange,
  }) {
    return BeatMappingState(
      isLoading: isLoading ?? this.isLoading,
      allDealers: allDealers ?? this.allDealers,
      filteredDealers: filteredDealers ?? this.filteredDealers,
      dropdownValues: dropdownValues ?? this.dropdownValues,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class BeatMappingNotifier extends StateNotifier<BeatMappingState> {
  BeatMappingNotifier()
      : super(
    BeatMappingState(
      isLoading: false,
      allDealers: [],
      filteredDealers: [],
      dropdownValues: {
        'status': ['done', 'pending'],
        'zone': [],
        'district': [],
        'taluka': [],
      },
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
      },
      dateRange: _getDefaultWeekRange(),
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
  }

  void resetFilters() {
    state = state.copyWith(
      selectedFilters: {
        'status': [],
        'zone': [],
        'district': [],
        'taluka': [],
      },
      dateRange: _getDefaultWeekRange(),
    );
  }

  Future<void> initialize() async {
    for (final field in ['zone', 'district', 'taluka']) {
      final uri = Uri.parse('${Config.backendUrl}/beat-mapping/dropdown?field=$field');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['values'] != null) {
          state = state.copyWith(
            dropdownValues: {
              ...state.dropdownValues,
              field: List<String>.from(res['values']),
            },
          );
        }
      }
    }
  }

  void addFilter(String key, String value) {
    final updated = [...state.selectedFilters[key]!, value];
    state = state.copyWith(
      selectedFilters: {
        ...state.selectedFilters,
        key: updated,
      },
    );
  }

  void applySearch(String search) {
    final filtered = state.allDealers.where((dealer) {
      return dealer['name']
          .toString()
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();
    state = state.copyWith(filteredDealers: filtered);
  }

  Future<void> fetchBeatMapping(Position? currentLocation) async {
    state = state.copyWith(isLoading: true);
    final startDate = DateFormat("yyyy-MM-dd").format(state.dateRange.start);
    final endDate = DateFormat("yyyy-MM-dd").format(state.dateRange.end);

    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token not found");

    final uri = Uri.parse('${Config.backendUrl}/get-beat-mapping-report');
    final body = json.encode({
      "startDate": startDate,
      "endDate": endDate,
      "status": state.selectedFilters['status'],
      "zone": state.selectedFilters['zone'],
      "district": state.selectedFilters['district'],
      "taluka": state.selectedFilters['taluka'],
      "travel": []
    });

    final response = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      "Authorization": "Bearer $token",
    }, body: body);

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['data'] != null) {
        final List<Dealer> all = List.from(res['data']);

        if (currentLocation != null) {
          for (final d in all) {
            final lat = d['latitude']?.toDouble() ?? 0.0;
            final lng = d['longitude']?.toDouble() ?? 0.0;
            d['distance'] = Geolocator.distanceBetween(
                currentLocation.latitude, currentLocation.longitude, lat, lng) /
                1000;
          }
        }

        all.sort((a, b) => a['distance'].compareTo(b['distance']));
        state = state.copyWith(
          allDealers: all,
          filteredDealers: all,
          isLoading: false,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: false);
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

      // ✅ Add success = true only if 200, else false
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

}

final beatMappingProvider =
StateNotifierProvider<BeatMappingNotifier, BeatMappingState>(
        (ref) => BeatMappingNotifier());
