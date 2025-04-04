import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config.dart';
import '../../services/auth_service.dart';
import '../../providers/extraction_form_provider.dart';
import '../services/auth_gate.dart';
import '../screens/employee/extraction.dart';

class AddExtractionStep3 extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String brand; // ✅ Add this line

  AddExtractionStep3({
    required this.scrollController,
    required this.brand, // ✅ Add this line
  });

  @override
  _AddExtractionStep3State createState() => _AddExtractionStep3State();
}


class _AddExtractionStep3State extends ConsumerState<AddExtractionStep3> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, int> productQuantities = {};
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product.values.any((value) =>
            value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> fetchProducts() async {
    try {
      final brand = widget.brand; // ✅ Use widget value directly
      print("🔥 Fetching productssss for brand: $brand");


      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/get-products-by-brand?brand=$brand"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          products = List<Map<String, dynamic>>.from(data["products"]);
          filteredProducts = products;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      print("❌ Product fetch error: $e");
      setState(() => isLoading = false);
    }
  }


  void _updateQuantity(Map<String, dynamic> product, int delta) {
    final notifier = ref.read(extractionFormProvider.notifier);
    final id = product["_id"];
    final currentQty = productQuantities[id] ?? 0;
    final newQty = currentQty + delta;

    setState(() {
      if (newQty > 0) {
        productQuantities[id] = newQty;
        final newProduct = {...product, "quantity": newQty};
        notifier.setSelectedProducts(
          [
            ...ref.read(extractionFormProvider).selectedProducts
                .where((p) => p["_id"] != id),
            newProduct
          ],
        );
      } else {
        productQuantities.remove(id);
        notifier.setSelectedProducts(
          ref.read(extractionFormProvider)
              .selectedProducts
              .where((p) => p["_id"] != id)
              .toList(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedProducts = ref.watch(extractionFormProvider).selectedProducts;
    final totalUnits = selectedProducts.fold<int>(
      0,
          (sum, product) => sum + (product["quantity"] as int? ?? 0),
    );


    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // 👈 Solid background
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20), // 👈 Adjust this value as needed
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search products...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: widget.scrollController,
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final qty = productQuantities[product["_id"]] ?? 0;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0X33BBBCE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        // 🧾 Main Product Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product["brand"] ?? "", style: TextStyle(fontSize: 14)),
                            Text(product["product_name"] ?? "", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(product["product_code"] ?? "", style: TextStyle(fontSize: 12)),
                            Text("₹ ${product["price"]}", style: TextStyle(fontSize: 12)),
                          ],
                        ),

                        // 🔖 Category Tag – Top Right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0x33BFC0FF), // light orange
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product["product_category"] ?? "",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),

                        // ➖➕ Quantity Selector – Bottom Right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _updateQuantity(product, -1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(Icons.remove, size: 20),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '${productQuantities[product["_id"]] ?? 0}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _updateQuantity(product, 1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(Icons.add, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                  );


                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: $totalUnits units",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final formState = ref.read(extractionFormProvider);
                    final notifier = ref.read(extractionFormProvider.notifier);

                    if (formState.dealer == null || formState.selectedProducts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please select dealer and at least one product")),
                      );
                      return;
                    }

                    final payload = {
                      "dealer": formState.dealer!["code"],
                      "products": formState.selectedProducts.map((p) => {
                        "brand": p["brand"],
                        "product_name": p["product_name"],
                        "model_code": p["model_code"],
                        "price": p["price"],
                        "segment": p["segment"],
                        "product_code": p["product_code"],
                        "quantity": p["quantity"],
                        "amount": p["quantity"] * p["price"],
                        "product_category": p["product_category"]
                      }).toList()
                    };

                    try {
                      final token = await AuthService.getToken();
                      final res = await http.post(
                        Uri.parse("${Config.backendUrl}/user/extraction-record/add"),
                        headers: {
                          "Authorization": "Bearer $token",
                          "Content-Type": "application/json",
                        },
                        body: jsonEncode(payload),
                      );

                      final data = jsonDecode(res.body);
                      if (data["success"]) {
                        notifier.clearForm();

                        Navigator.of(context).popUntil((route) => route.isFirst);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => ExtractionScreen()),
                              (route) => false,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data["message"] ?? "Extraction added successfully")),
                        );
                      } else {
                        throw Exception(data["message"] ?? "Failed");
                      }
                    } catch (e) {
                      print("❌ Error submitting extraction: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Something went wrong. Please try again.")),
                      );
                    }
                  },
                  child: Text("Submit"),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
