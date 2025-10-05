import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Data model for remembering hierarchy path
class HierarchySelection {
  final List<String> pathCodes; // e.g. ["DIV001", "ASM002", "MDD003"]
  final String activeCode;      // e.g. "MDD003"
  final String activePosition;  // e.g. "mdd"

  HierarchySelection({
    required this.pathCodes,
    required this.activeCode,
    required this.activePosition,
  });
}

// ✅ Global state provider
final hierarchySelectionProvider =
StateProvider<HierarchySelection?>((ref) => null);
