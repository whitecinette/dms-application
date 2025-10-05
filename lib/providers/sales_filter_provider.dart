import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class SalesFilterState {
  final String selectedType;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedSubordinate;
  final List<String> selectedSubordinateCodes;
  final List<String> selectedCategories; // ✅ supports multiple categories

  SalesFilterState({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.selectedSubordinate,
    required this.selectedSubordinateCodes,
    this.selectedCategories = const [], // ✅ default empty
  });

  SalesFilterState copyWith({
    String? selectedType,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedSubordinate,
    List<String>? selectedSubordinateCodes,
    List<String>? selectedCategories,
  }) {
    return SalesFilterState(
      selectedType: selectedType ?? this.selectedType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSubordinate: selectedSubordinate ?? this.selectedSubordinate,
      selectedSubordinateCodes:
      selectedSubordinateCodes ?? this.selectedSubordinateCodes,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }

  Map<String, dynamic> getApiFilters() {
    return {
      "filter_type": selectedType,
      "start_date": startDate.toIso8601String().split("T")[0],
      "end_date": endDate.toIso8601String().split("T")[0],
      "subordinate": selectedSubordinate,
      "subordinate_codes": selectedSubordinateCodes,
      if (selectedCategories.isNotEmpty)
        "product_categories": selectedCategories, // ✅ plural + list
    };
  }
}

class SalesFilterNotifier extends StateNotifier<SalesFilterState> {
  SalesFilterNotifier()
      : super(
    SalesFilterState(
      selectedType: 'value',
      startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      endDate: DateTime.now(),
      selectedSubordinate: 'self',
      selectedSubordinateCodes: [],
    ),
  );

  // ✅ Bulk update
  void updateCategories(List<String> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  // ✅ Add one category
  void addCategory(String category) {
    if (!state.selectedCategories.contains(category)) {
      final updated = [...state.selectedCategories, category];
      state = state.copyWith(selectedCategories: updated);
    }
  }

  // ✅ Remove one category
  void removeCategory(String category) {
    final updated =
    state.selectedCategories.where((c) => c != category).toList();
    state = state.copyWith(selectedCategories: updated);
  }

  // ✅ Clear all filters
  void clearAllFilters() {
    state = state.copyWith(
      selectedSubordinateCodes: [],
      selectedCategories: [], // ✅ reset category list
      // Optionally reset other filters:
      // selectedType: "value",
      // startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      // endDate: DateTime.now(),
    );
  }

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
