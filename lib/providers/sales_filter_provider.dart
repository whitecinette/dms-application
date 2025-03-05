import 'package:flutter/material.dart';

class SalesFilterProvider extends ChangeNotifier {
  String selectedType = 'value';  // Default: Value or Volume
  DateTime startDate = DateTime(2025, 2, 1);  // Default Start Date
  DateTime endDate = DateTime(2025, 2, 28);   // Default End Date
  String selectedSubordinate = "self";  // Default: Self Data

  void updateType(String type) {
    selectedType = type.toLowerCase(); // Ensure lowercase for API
    notifyListeners();
  }

  void updateDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    notifyListeners();
  }

  void updateSubordinate(String subordinateId) {
    selectedSubordinate = subordinateId;
    notifyListeners();
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
