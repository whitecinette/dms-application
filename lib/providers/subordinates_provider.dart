import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import 'sales_filter_provider.dart'; // ✅ Needed to read current filters

// Model for Subordinates
class Subordinate {
  final String code;
  final String name;
  final int mtdSellOut;
  final int lmtdSellOut;
  final String sellOutGrowth;
  final String position;

  Subordinate({
    required this.code,
    required this.name,
    required this.mtdSellOut,
    required this.lmtdSellOut,
    required this.sellOutGrowth,
    required this.position,
  });

  factory Subordinate.fromJson(Map<String, dynamic> json) {
    return Subordinate(
      code: json["code"],
      name: json["name"],
      mtdSellOut: json["mtd_sell_out"] ?? 0,
      lmtdSellOut: json["lmtd_sell_out"] ?? 0,
      sellOutGrowth: json["sell_out_growth"] ?? "0.00",
      position: json["position"] ?? "",
    );
  }
}

// Notifier to Manage State
class SubordinatesNotifier extends StateNotifier<AsyncValue<Map<String, List<Subordinate>>>> {
  final Ref ref;

  SubordinatesNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchSubordinates(); // Initial load with default filters
  }

  Future<void> fetchSubordinates({
    String? filterType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filter = ref.read(salesFilterProvider); // Read current filters if not passed

      final token = await AuthService.getToken();
      if (token == null) throw Exception("Token not found");

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/get-subordinates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "filter_type": filterType ?? filter.selectedType,
          "start_date": (startDate ?? filter.startDate).toIso8601String().split("T")[0],
          "end_date": (endDate ?? filter.endDate).toIso8601String().split("T")[0],
          "subordinate_codes": filter.selectedSubordinateCodes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"]) {
          List<String> positions = (data["positions"] as List).cast<String>();
          Map<String, List<Subordinate>> subordinatesMap = {};

          for (String position in positions) {
            subordinatesMap[position] = (data["subordinates"] as List)
                .where((sub) => sub["position"] == position)
                .map((sub) => Subordinate.fromJson(sub))
                .toList();
          }

          state = AsyncValue.data(subordinatesMap);
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
}

// ✅ Register the provider
final subordinatesProvider = StateNotifierProvider<SubordinatesNotifier, AsyncValue<Map<String, List<Subordinate>>>>(
      (ref) => SubordinatesNotifier(ref),
);
