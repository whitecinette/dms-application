import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

typedef Dealer = Map<String, dynamic>;

final extractionStatusProvider =
StateNotifierProvider<ExtractionStatusNotifier, ExtractionStatusState>(
        (ref) => ExtractionStatusNotifier());

class ExtractionStatusNotifier extends StateNotifier<ExtractionStatusState> {
  ExtractionStatusNotifier()
      : super(ExtractionStatusState(
    allDealers: [],
    filteredDealers: [],
    isLoading: false,
  ));

  Future<void> fetchDealersWithStatus({
    required String userCode,
    required DateTimeRange dateRange,
  }) async {
    state = state.copyWith(isLoading: true);

    final uri = Uri.parse(
        "${Config.backendUrl}/user/extraction-dealers-w-status"
            "?code=$userCode"
            "&startDate=${dateRange.start.toIso8601String()}"
            "&endDate=${dateRange.end.toIso8601String()}");

    try {
      print("📡 Requesting: $uri");
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        final dealers = List<Map<String, dynamic>>.from(jsonRes['dealers']);

        state = state.copyWith(
          allDealers: dealers,
          filteredDealers: dealers,
          isLoading: false,
        );
      } else {
        print("❌ Status Fetch Failed: ${response.body}");
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("❌ Error fetching dealers with status: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void applySearch(String query) {
    final q = query.toLowerCase();
    final filtered = state.allDealers.where((d) {
      return d['name'].toString().toLowerCase().contains(q) ||
          d['code'].toString().toLowerCase().contains(q);
    }).toList();

    state = state.copyWith(filteredDealers: filtered);
  }

  void markDealerDoneLocally(String dealerCode) {
    final updatedDealers = state.allDealers.map((d) {
      if (d['code'] == dealerCode) {
        return {
          ...d,
          'status': 'done',
          'visits': (d['visits'] ?? 0) + 1,
        };
      }
      return d;
    }).toList();

    state = state.copyWith(
      allDealers: updatedDealers,
      filteredDealers: updatedDealers,
    );
  }
}

class ExtractionStatusState {
  final List<Dealer> allDealers;
  final List<Dealer> filteredDealers;
  final bool isLoading;

  ExtractionStatusState({
    required this.allDealers,
    required this.filteredDealers,
    required this.isLoading,
  });

  ExtractionStatusState copyWith({
    List<Dealer>? allDealers,
    List<Dealer>? filteredDealers,
    bool? isLoading,
  }) {
    return ExtractionStatusState(
      allDealers: allDealers ?? this.allDealers,
      filteredDealers: filteredDealers ?? this.filteredDealers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
