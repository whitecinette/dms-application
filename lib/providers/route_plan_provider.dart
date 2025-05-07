import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config.dart';
import '../../services/auth_service.dart';

typedef RoutePlan = Map<String, dynamic>;

class RoutePlanState {
  final List<RoutePlan> routes;
  final List<RoutePlan> filteredRoutes;
  final bool isLoading;
  final DateTimeRange dateRange;

  RoutePlanState({
    required this.routes,
    required this.filteredRoutes,
    required this.isLoading,
    required this.dateRange,
  });

  RoutePlanState copyWith({
    List<RoutePlan>? routes,
    List<RoutePlan>? filteredRoutes,
    bool? isLoading,
    DateTimeRange? dateRange,
  }) {
    return RoutePlanState(
      routes: routes ?? this.routes,
      filteredRoutes: filteredRoutes ?? this.filteredRoutes,
      isLoading: isLoading ?? this.isLoading,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class RoutePlanNotifier extends StateNotifier<RoutePlanState> {
  RoutePlanNotifier()
      : super(RoutePlanState(
    routes: [],
    filteredRoutes: [],
    isLoading: false,
    dateRange: _getDefaultRange(),
  ));

  static DateTimeRange _getDefaultRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
  }

  void search(String query) {
    final results = state.routes.where((r) {
      final name = r['name']?.toString().toLowerCase() ?? "";
      return name.contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(filteredRoutes: results);
  }

  Future<void> fetchRoutePlans() async {
    state = state.copyWith(isLoading: true);

    final token = await AuthService.getToken();
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final uri = Uri.parse("${Config.backendUrl}/user/route-plan/get");
    final body = jsonEncode({
      "startDate": DateFormat("yyyy-MM-dd").format(state.dateRange.start),
      "endDate": DateFormat("yyyy-MM-dd").format(state.dateRange.end),
    });

    try {
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        final List<RoutePlan> data = List.from(jsonRes['data'] ?? []);
        state = state.copyWith(routes: data, filteredRoutes: data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("Error fetching routes: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addRoutePlan({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, List<String>> itinerary,
  }) async {
    state = state.copyWith(isLoading: true);
    final token = await AuthService.getToken();
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final uri = Uri.parse("${Config.backendUrl}/user/route-plan/add");
    final body = jsonEncode({
      "startDate": DateFormat("yyyy-MM-dd").format(startDate),
      "endDate": DateFormat("yyyy-MM-dd").format(endDate),
      "itinerary": itinerary,
      "status": "active",
      "approved": true
    });

    try {
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        await fetchRoutePlans();
      }

      return success;
    } catch (e) {
      print("Error adding route plan: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<Map<String, List<String>>?> fetchMarketCoverageDropdown() async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final uri = Uri.parse("${Config.backendUrl}/user/market-coverage/dropdown");

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        return {
          "district": List<String>.from(jsonRes['district'] ?? []),
          "zone": List<String>.from(jsonRes['zone'] ?? []),
          "taluka": List<String>.from(jsonRes['taluka'] ?? []),
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching dropdowns: $e");
      return null;
    }
  }

  Future<bool> deleteRoute(String routeId) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Config.backendUrl}/route-plan/delete/$routeId');
    print("URI ${uri}");

    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    return response.statusCode == 200;
  }

}

final routePlanProvider =
StateNotifierProvider<RoutePlanNotifier, RoutePlanState>((ref) => RoutePlanNotifier());
