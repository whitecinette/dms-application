import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the data for the multi-step extraction form
class ExtractionFormState {
  final Map<String, dynamic>? dealer; // Selected dealer
  final String? brand; // Selected brand
  final List<Map<String, dynamic>> selectedProducts; // Selected product(s)

  ExtractionFormState({
    this.dealer,
    this.brand,
    this.selectedProducts = const [],
  });

  ExtractionFormState copyWith({
    Map<String, dynamic>? dealer,
    String? brand,
    List<Map<String, dynamic>>? selectedProducts,
  }) {
    return ExtractionFormState(
      dealer: dealer ?? this.dealer,
      brand: brand ?? this.brand,
      selectedProducts: selectedProducts ?? this.selectedProducts,
    );
  }
}

/// Notifier to manage extraction form state
class ExtractionFormNotifier extends StateNotifier<ExtractionFormState> {
  ExtractionFormNotifier() : super(ExtractionFormState());

  /// Set selected dealer
  void setDealer(Map<String, dynamic> dealer) {
    print("✅ Dealer selected: $dealer");
    state = state.copyWith(dealer: dealer);
  }

  /// Set selected brand
  void setBrand(String brand) {
    print("✅ Brand selected: $brand");
    state = state.copyWith(brand: brand);
  }

  /// Set selected products
  void setSelectedProducts(List<Map<String, dynamic>> products) {
    print("✅ Products selected: $products");
    state = state.copyWith(selectedProducts: products);
  }

  /// Reset the form
  void clearForm() {
    print("🧹 Form cleared");
    state = ExtractionFormState();
  }
}

/// Global provider for extraction form state
final extractionFormProvider =
StateNotifierProvider<ExtractionFormNotifier, ExtractionFormState>(
        (ref) => ExtractionFormNotifier());
