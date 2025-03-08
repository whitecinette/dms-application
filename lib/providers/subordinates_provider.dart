import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';

// Model for Subordinates
class Subordinate {
  final String code;
  final String name;
  final int mtdSellOut;
  final int lmtdSellOut;
  final String sellOutGrowth;

  Subordinate({
    required this.code,
    required this.name,
    required this.mtdSellOut,
    required this.lmtdSellOut,
    required this.sellOutGrowth,
  });

  factory Subordinate.fromJson(Map<String, dynamic> json) {
    return Subordinate(
      code: json["code"],
      name: json["name"],
      mtdSellOut: json["mtd_sell_out"],
      lmtdSellOut: json["lmtd_sell_out"],
      sellOutGrowth: json["sell_out_growth"],
    );
  }
}

// Notifier to Manage State
class SubordinatesNotifier extends StateNotifier<AsyncValue<Map<String, List<Subordinate>>>> {
  SubordinatesNotifier() : super(const AsyncValue.loading()) {
    fetchSubordinates();
  }

  String? currentPosition; // Track current position level

  // Fetch subordinates (self)
  Future<void> fetchSubordinates() async {
    try {
      String? token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/get-subordinates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "filter_type": "volume",
          "start_date": "2025-02-01",
          "end_date": "2025-02-28",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"]) {
          currentPosition = data["position"];
          List<Subordinate> firstLevelSubordinates = (data["subordinates"][currentPosition] as List)
              .map((sub) => Subordinate.fromJson(sub))
              .toList();

          if (firstLevelSubordinates.isEmpty) {
            // Automatically fetch the next level
            fetchSubordinatesByCode(currentPosition!, firstLevelSubordinates.first.code);
          }

          state = AsyncValue.data({currentPosition!: firstLevelSubordinates});
        } else {
          state = AsyncValue.error("Failed to fetch subordinates", StackTrace.current);
        }
      } else {
        state = AsyncValue.error("Error: ${response.statusCode}", StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error("Failed to connect to server", stackTrace);
    }
  }

  // Fetch next-level subordinates when a subordinate is selected
  Future<void> fetchSubordinatesByCode(String position, String code) async {
    try {
      String? token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/get-subordinates-by-code"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "code": code,
          "filter_type": "volume",
          "start_date": "2025-02-01",
          "end_date": "2025-02-28",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"]) {
          String nextPosition = data["position"];
          List<Subordinate> nextSubordinates = (data["subordinates"][nextPosition] as List)
              .map((sub) => Subordinate.fromJson(sub))
              .toList();

          if (nextSubordinates.isNotEmpty) {
            state = AsyncValue.data({ // ✅ Update UI with new subordinates
              ...state.value ?? {},  // Keep existing subordinates
              nextPosition: nextSubordinates, // Add new subordinates
            });
          }
        }
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error("Failed to load subordinates", stackTrace);
    }
  }

}

// ✅ Register the provider
final subordinatesProvider = StateNotifierProvider<SubordinatesNotifier, AsyncValue<Map<String, List<Subordinate>>>>(
      (ref) => SubordinatesNotifier(),
);
