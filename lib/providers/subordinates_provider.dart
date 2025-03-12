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
  SubordinatesNotifier() : super(const AsyncValue.loading()) {
    fetchSubordinates();
  }

  // Fetch subordinates (self)
  Future<void> fetchSubordinates() async {
    try {
      print("Cp 11111");
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
      print("URLLLL2: ${Config.backendUrl}/user/get-subordinates");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Cp 2 $data['success']");

        if (data["success"]) {
          List<String> positions = (data["positions"] as List).cast<String>();

          // ✅ Store all subordinates grouped by position
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
        state = AsyncValue.error("Erroor: ${response.statusCode}", StackTrace.current);
        print("Error cp 3: ");
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error("Failed to connect to server", stackTrace);
      print("Errorrrr: $e");
    }
  }
}

// ✅ Register the provider
final subordinatesProvider = StateNotifierProvider<SubordinatesNotifier, AsyncValue<Map<String, List<Subordinate>>>>(
      (ref) => SubordinatesNotifier(),
);
