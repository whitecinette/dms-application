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
  // fetch routes by user
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

  // // add route plan by user
  // Future<bool> addRoutePlanFromSelectedRoutes(List<String> selectedRoutes) async {
  //   print("reachingggggggg");
  //   state = state.copyWith(isLoading: true);
  //   final token = await AuthService.getToken();
  //
  //   if (token == null) {
  //     state = state.copyWith(isLoading: false);
  //     return false;
  //   }
  //
  //   final uri = Uri.parse("${Config.backendUrl}/add-route-plan-by-user");
  //   final body = jsonEncode({
  //     "routes": selectedRoutes,
  //   });
  //
  //   try {
  //     final response = await http.post(uri, headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     }, body: body);
  //
  //     final success = response.statusCode == 200 || response.statusCode == 201;
  //
  //     if (success) {
  //       await fetchRoutePlans(); // Refresh the list after adding
  //     }
  //
  //     return success;
  //   } catch (e) {
  //     print("Error in addRoutePlanFromSelectedRoutes: $e");
  //     state = state.copyWith(isLoading: false);
  //     return false;
  //   }
  // }
  //

  // request route plan
  Future<bool> requestRoutePlan(List<String> selectedRoutes) async {
    print("requesting route plan...");
    state = state.copyWith(isLoading: true);

    final token = await AuthService.getToken();
    print("Token in requestRoutePlan: $token");  // ⬅️ Add this
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final uri = Uri.parse("${Config.backendUrl}/request-route-plan");
    final body = jsonEncode({
      "routes": selectedRoutes,
      // optional: include "startDate" and "endDate" if your backend supports it
      // "startDate": "2025-07-20",
      // "endDate": "2025-07-22"
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        // If you have a separate list of requested routes, refresh it here
        // await fetchRequestedRoutePlans();
      }

      return success;
    } catch (e) {
      print("Error in requestRoutePlan: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }


  // get Requested Route Plan
  Future<void> fetchRequestedRoutePlans({required DateTimeRange selectedRange}) async {
    print("Fetching requested route plans...");
    state = state.copyWith(isLoading: true);

    final token = await AuthService.getToken();
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final uri = Uri.parse("${Config.backendUrl}/get-requested-route").replace(
      queryParameters: {
        'startDate': selectedRange.start.toIso8601String(),
        'endDate': selectedRange.end.toIso8601String(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        final List<dynamic> rawData = jsonRes['data'] ?? [];

        print("Fetched ${rawData.length} requested routes");

        final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(rawData);

        state = state.copyWith(
          routes: data,
          filteredRoutes: data,
          isLoading: false,
        );
      } else {
        print("Failed to fetch requested route plans: ${response.statusCode}");
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("Error in fetchRequestedRoutePlans: $e");
      state = state.copyWith(isLoading: false);
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
          "town": List<String>.from(jsonRes['town'] ?? []),
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching dropdowns: $e");
      return null;
    }
  }
  // fetch user routes
  Future<List<String>> fetchUserRoutes() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final uri = Uri.parse("${Config.backendUrl}/get-route-by-user");

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        final List data = jsonRes['data'] ?? [];

        // Extract unique route names
        final routeNames = data.map<String>((item) => item['name'].toString()).toSet().toList();

        return routeNames;
      } else {
        print("Failed to fetch user routes: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching user routes: $e");
      return [];
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
