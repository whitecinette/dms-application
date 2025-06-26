import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class SalesFilterState {
  final String selectedType;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedSubordinate;
  final List<String> selectedSubordinateCodes;

  SalesFilterState({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.selectedSubordinate,
    required this.selectedSubordinateCodes,
  });

  SalesFilterState copyWith({
    String? selectedType,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedSubordinate,
    List<String>? selectedSubordinateCodes,
  }) {
    return SalesFilterState(
      selectedType: selectedType ?? this.selectedType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSubordinate: selectedSubordinate ?? this.selectedSubordinate,
      selectedSubordinateCodes:
      selectedSubordinateCodes ?? this.selectedSubordinateCodes,
    );
  }

  Map<String, dynamic> getApiFilters() {
    return {
      "filter_type": selectedType,
      "start_date": startDate.toIso8601String().split("T")[0],
      "end_date": endDate.toIso8601String().split("T")[0],
      "subordinate": selectedSubordinate,
      "subordinate_codes": selectedSubordinateCodes,
    };
  }
}


class SalesFilterNotifier extends StateNotifier<SalesFilterState> {
  SalesFilterNotifier()
      : super(SalesFilterState(
    selectedType: 'value',
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime.now(),
    selectedSubordinate: 'self',
    selectedSubordinateCodes: [],
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

  void updateSubordinates(List<String> codes) {
    state = state.copyWith(selectedSubordinateCodes: codes);
  }
}


// 📦 Riverpod Provider
final salesFilterProvider =
StateNotifierProvider<SalesFilterNotifier, SalesFilterState>((ref) {
  return SalesFilterNotifier();
});
