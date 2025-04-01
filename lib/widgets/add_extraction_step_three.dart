import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config.dart';
import '../../services/auth_service.dart';
import '../../providers/extraction_form_provider.dart';

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
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _updateQuantity(product, -1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(Icons.remove, size: 18),
                                  ),
                                ),
                                Text(
                                  '${productQuantities[product["_id"]] ?? 0}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () => _updateQuantity(product, 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(Icons.add, size: 18),
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
