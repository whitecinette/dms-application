import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class SalesFilterState {
  final String selectedType;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedSubordinate;

  SalesFilterState({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.selectedSubordinate,
  });

  SalesFilterState copyWith({
    String? selectedType,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedSubordinate,
  }) {
    return SalesFilterState(
      selectedType: selectedType ?? this.selectedType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSubordinate: selectedSubordinate ?? this.selectedSubordinate,
    );
  }

  Map<String, dynamic> getApiFilters() {
    return {
      "filter_type": selectedType,
      "start_date": startDate.toIso8601String().split("T")[0],
      "end_date": endDate.toIso8601String().split("T")[0],
      "subordinate": selectedSubordinate,
    };
  }
}

class SalesFilterNotifier extends StateNotifier<SalesFilterState> {
  SalesFilterNotifier()
      : super(SalesFilterState(
    selectedType: 'value',
    startDate: DateTime(2025, 2, 1),
    endDate: DateTime(2025, 2, 28),
    selectedSubordinate: 'self',
  ));

  void updateType(String type) {
    state = state.copyWith(selectedType: type.toLowerCase());
  }

  void updateDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void updateSubordinate(String subordinateId) {
    state = state.copyWith(selectedSubordinate: subordinateId);
  }
}

// 📦 Riverpod Provider
final salesFilterProvider =
StateNotifierProvider<SalesFilterNotifier, SalesFilterState>((ref) {
  return SalesFilterNotifier();
});
