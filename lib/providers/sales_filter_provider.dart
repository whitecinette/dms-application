import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hierarchy_selection_provider.dart';

/// 🧩 Data model for all sales filters (type, date, subordinates, categories)
class SalesFilterState {
  final String selectedType;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedSubordinate;
  final List<String> selectedSubordinateCodes;
  final List<String> selectedCategories;
  final String? selectedHierarchyCode;       // ✅ added
  final String? selectedHierarchyPosition;   // ✅ added

  SalesFilterState({
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.selectedSubordinate,
    required this.selectedSubordinateCodes,
    this.selectedCategories = const [],
    this.selectedHierarchyCode,
    this.selectedHierarchyPosition,
  });

  SalesFilterState copyWith({
    String? selectedType,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedSubordinate,
    List<String>? selectedSubordinateCodes,
    List<String>? selectedCategories,
    String? selectedHierarchyCode,
    String? selectedHierarchyPosition,
  }) {
    return SalesFilterState(
      selectedType: selectedType ?? this.selectedType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSubordinate: selectedSubordinate ?? this.selectedSubordinate,
      selectedSubordinateCodes:
      selectedSubordinateCodes ?? this.selectedSubordinateCodes,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedHierarchyCode:
      selectedHierarchyCode ?? this.selectedHierarchyCode,
      selectedHierarchyPosition:
      selectedHierarchyPosition ?? this.selectedHierarchyPosition,
    );
  }

  /// 🧠 Build API-friendly map
  Map<String, dynamic> getApiFilters() {
    return {
      "filter_type": selectedType,
      "start_date": startDate.toIso8601String().split("T")[0],
      "end_date": endDate.toIso8601String().split("T")[0],
      "subordinate": selectedSubordinate,
      "subordinate_codes": selectedSubordinateCodes,
      if (selectedCategories.isNotEmpty)
        "product_categories": selectedCategories,
      if (selectedHierarchyCode != null) "code": selectedHierarchyCode,
      if (selectedHierarchyPosition != null)
        "position": selectedHierarchyPosition,
    };
  }
}

/// 🧩 State notifier for all sales filters
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

  // ✅ Bulk update categories
  void updateCategories(List<String> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  // ✅ Update from hierarchy selection
  void updateHierarchy(HierarchySelection selection) {
    state = state.copyWith(
      selectedSubordinateCodes: selection.pathCodes,
      selectedHierarchyCode: selection.activeCode,
      selectedHierarchyPosition: selection.activePosition,
    );
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
      selectedCategories: [],
    );
  }

  // ✅ Update type (value or volume)
  void updateType(String type) {
    state = state.copyWith(selectedType: type.toLowerCase());
  }

  // ✅ Update date range
  void updateDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  // ✅ Update single subordinate
  void updateSubordinate(String subordinateId) {
    state = state.copyWith(selectedSubordinate: subordinateId);
  }

  // ✅ Update multiple subordinates
  void updateSubordinates(List<String> codes) {
    state = state.copyWith(selectedSubordinateCodes: codes);
  }
}

/// 🧩 Global provider with listener for hierarchy changes
final salesFilterProvider =
StateNotifierProvider<SalesFilterNotifier, SalesFilterState>(
      (ref) {
    final notifier = SalesFilterNotifier();

    // 👇 Listen to hierarchy changes globally
    ref.listen<HierarchySelection?>(
      hierarchySelectionProvider,
          (previous, next) {
        if (next != null &&
            (previous?.activeCode != next.activeCode ||
                previous?.activePosition != next.activePosition)) {
          notifier.updateHierarchy(next);
        }
      },
    );

    return notifier;
  },
);
