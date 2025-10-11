import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import 'sales_filter_provider.dart';
import 'hierarchy_selection_provider.dart';

// Model for Subordinates
class Subordinate {
  final String code;
  final String name;
  final int mtdSellOut;
  final int lmtdSellOut;
  final double sellOutGrowth; // keep as double
  final String position;

  // New fields
  final int m1;
  final int m2;
  final int m3;
  final double ads;
  final int ftd;
  final int tgt;
  final double reqAds;
  final double contribution;

  Subordinate({
    required this.code,
    required this.name,
    required this.mtdSellOut,
    required this.lmtdSellOut,
    required this.sellOutGrowth,
    required this.position,
    this.m1 = 0,
    this.m2 = 0,
    this.m3 = 0,
    this.ads = 0.0,
    this.ftd = 0,
    this.tgt = 0,
    this.reqAds = 0.0,
    this.contribution = 0.0,
  });

  factory Subordinate.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Subordinate(
      code: json["code"] ?? "",
      name: json["name"] ?? "",
      mtdSellOut: parseInt(json["mtd_sell_out"]),
      lmtdSellOut: parseInt(json["lmtd_sell_out"]),
      sellOutGrowth: parseDouble(json["sell_out_growth"]),
      position: json["position"] ?? "",

      m1: parseInt(json["M-1"]),
      m2: parseInt(json["M-2"]),
      m3: parseInt(json["M-3"]),
      ads: parseDouble(json["ADS"]),
      ftd: parseInt(json["FTD"]),
      tgt: parseInt(json["TGT"]),
      reqAds: parseDouble(json["Req. ADS"]),
      contribution: parseDouble(json["Contribution%"]),
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
    String? position,
    String? parentCode,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final filter = ref.read(salesFilterProvider);
      final token = await AuthService.getToken();
      if (token == null) throw Exception("Token not found");

      // ✅ Include subordinate codes + product categories from filter state
      final body = {
        "filter_type": filterType ?? filter.selectedType,
        "start_date":
        (startDate ?? filter.startDate).toIso8601String().split("T")[0],
        "end_date":
        (endDate ?? filter.endDate).toIso8601String().split("T")[0],
        "position": position,
        "parent_code": parentCode,
        "subordinate_codes": filter.selectedSubordinateCodes, // ✅ NEW
        "product_categories": filter.selectedCategories,      // ✅ NEW
        "page": page,
        "limit": limit,
      };

      print("🚀 Fetching subordinates with filters:");
      print(jsonEncode(body));

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/hierarchy/data-stats"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🔍 API Response: $data");

        if (data["success"] == true) {
          final String pos = data["position"] ?? "";
          final List<dynamic> subsJson = data["subordinates"] ?? [];

          Map<String, List<Subordinate>> subordinatesMap = {
            pos: subsJson.map((sub) => Subordinate.fromJson(sub)).toList(),
          };

          state = AsyncValue.data(subordinatesMap);
        } else {
          state = AsyncValue.error("Failed to fetch subordinates", StackTrace.current);
        }
      } else {
        print("❌ Error: ${response.statusCode} ${response.body}");
        state = AsyncValue.error("Error: ${response.statusCode}", StackTrace.current);
      }
    } catch (e, stackTrace) {
      print("💥 Exception in fetchSubordinates: $e");
      state = AsyncValue.error("Failed to connect to server: $e", stackTrace);
    }
  }


}

Future<void> applyHierarchySelection(
    WidgetRef ref,
    Subordinate sub,
    List<Subordinate> history,
    ) async {
  // 🧭 Build full hierarchy path (e.g. [DIV123, ASM045, MDD003, DEAL100])
  final fullPath = [...history.map((h) => h.code), sub.code];

  // ✅ Update hierarchySelectionProvider → used for restoration and tracking
  ref.read(hierarchySelectionProvider.notifier).state = HierarchySelection(
    pathCodes: fullPath,
    activeCode: sub.code,
    activePosition: sub.position,
  );

  // ✅ Update SalesFilterProvider → used by dashboard and API calls
  ref.read(salesFilterProvider.notifier).updateSubordinates(fullPath);
  ref.read(salesFilterProvider.notifier).updateSubordinate(sub.code);

  // ✅ Also store the currently selected hierarchy info
  // (so getApiFilters() will include "code" and "position")
  ref.read(salesFilterProvider.notifier).updateHierarchy(
    HierarchySelection(
      pathCodes: fullPath,
      activeCode: sub.code,
      activePosition: sub.position,
    ),
  );

  // 🌀 Optional: Immediately trigger subordinate fetch if your UI depends on it
  final filter = ref.read(salesFilterProvider);
  await ref.read(subordinatesProvider.notifier).fetchSubordinates(
    filterType: filter.selectedType, // "value" or "volume"
    startDate: filter.startDate,
    endDate: filter.endDate,
    parentCode: fullPath.isNotEmpty ? fullPath.last : null,
  );

  print(
    "✅ Hierarchy applied → activeCode=${sub.code}, "
        "activePosition=${sub.position}, "
        "path=${fullPath.join(' > ')}",
  );
}



// ✅ Register the provider
final subordinatesProvider =
StateNotifierProvider<SubordinatesNotifier, AsyncValue<Map<String, List<Subordinate>>>>(
      (ref) => SubordinatesNotifier(ref),
);
