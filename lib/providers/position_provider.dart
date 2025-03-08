import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config.dart'; // Ensure correct import

class PositionNotifier extends StateNotifier<AsyncValue<List<String>>> {
  PositionNotifier() : super(const AsyncValue.loading()) {
    fetchPositions();
  }

  Future<void> fetchPositions() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get/actor-types-hierarchy/default_sales_flow"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          List<String> positions = ["ALL", ...data["data"]];
          state = AsyncValue.data(positions);
        } else {
          state = AsyncValue.error("Failed to load positions", StackTrace.current); // ✅ Fix
        }
      } else {
        state = AsyncValue.error("Error: ${response.statusCode}", StackTrace.current); // ✅ Fix
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error("Failed to connect to server", stackTrace); // ✅ Fix
    }
  }
}

// ✅ Register the provider
final positionProvider = StateNotifierProvider<PositionNotifier, AsyncValue<List<String>>>(
      (ref) => PositionNotifier(),
);
