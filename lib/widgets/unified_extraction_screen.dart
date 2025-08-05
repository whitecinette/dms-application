import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config.dart';
import '../../services/auth_service.dart';
import '../../providers/extraction_form_provider.dart';

class UnifiedExtractionScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UnifiedExtractionScreen> createState() => _UnifiedExtractionScreenState();
}

class _UnifiedExtractionScreenState extends ConsumerState<UnifiedExtractionScreen> {
  Map<String, dynamic>? selectedDealer;
  List<Map<String, dynamic>> dealers = [];
  List<String> brands = [];
  List<String> selectedBrands = [];
  Map<String, List<Map<String, dynamic>>> brandProducts = {}; // brand -> products
  Map<String, int> productQuantities = {};
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String? openedBrand;


  @override
  void initState() {
    super.initState();
    fetchDealers();
    fetchBrands();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDealers() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get-dealers"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          dealers = List<Map<String, dynamic>>.from(data['dealers']);
        });
      }
    } catch (e) {
      print("Dealer fetch error: $e");
    }
  }


  Future<void> fetchBrands() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get-unique-brands"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        final allBrands = List<String>.from(data['brands']);
        setState(() {
          brands = allBrands;
          selectedBrands = allBrands;
        });

        for (final brand in allBrands) {
          await fetchProductsForBrand(brand);
        }
      }
    } catch (e) {
      print("Brand fetch error: $e");
    }
  }

  Future<void> fetchProductsForBrand(String brand) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.backendUrl}/user/get-products-by-brand?brand=$brand"),
        headers: {"Content-Type": "application/json"},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          brandProducts[brand] = List<Map<String, dynamic>>.from(data['products']);
        });
      }
    } catch (e) {
      print("Product fetch error for $brand: $e");
    }
  }

  void _updateQuantity(Map<String, dynamic> product, int delta) {
    final id = product["_id"];
    final currentQty = productQuantities[id] ?? 0;
    final newQty = currentQty + delta;

    setState(() {
      if (newQty > 0) {
        productQuantities[id] = newQty;
      } else {
        productQuantities.remove(id);
      }
    });
  }

  int getTotalUnits() {
    return productQuantities.values.fold(0, (a, b) => a + b);
  }

  double getTotalValue() {
    double total = 0;
    for (var brand in selectedBrands) {
      final products = brandProducts[brand] ?? [];
      for (var p in products) {
        final qty = productQuantities[p["_id"]] ?? 0;
        total += qty * (p["price"] ?? 0);
      }
    }
    return total;
  }

  Map<String, double> getBrandWiseTotals() {
    Map<String, double> result = {};
    for (var brand in selectedBrands) {
      double subtotal = 0;
      final products = brandProducts[brand] ?? [];
      for (var p in products) {
        final qty = productQuantities[p["_id"]] ?? 0;
        subtotal += qty * (p["price"] ?? 0);
      }
      result[brand] = subtotal;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = getTotalUnits();
    final totalValue = getTotalValue();
    final brandTotals = getBrandWiseTotals();

    return Scaffold(
      appBar: AppBar(
        title: Text("New Extraction"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedBrands.clear();
                brandProducts.clear();
                productQuantities.clear();
                openedBrand = null;
              });
              Navigator.pop(context);
            },
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
          )
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Dealer Selection
            Text("Select Dealer", style: TextStyle(fontWeight: FontWeight.bold)),
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return dealers;
                return dealers.where((d) =>
                d['name'].toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    d['code'].toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (option) => "${option['name']} (${option['code']})",
              onSelected: (dealer) => setState(() => selectedDealer = dealer),
              fieldViewBuilder: (context, controller, focusNode, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Search dealer by name/code',
                  ),
                );
              },
            ),
            if (selectedDealer != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text("Selected: ${selectedDealer!['name']} (${selectedDealer!['code']})"),
              ),


            /// Totals at Top
            SizedBox(height: 20),
            Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 6),
            Text("Total Units: $totalUnits"),
            Text("Total Value: ₹${totalValue.toStringAsFixed(2)}"),
            SizedBox(height: 20),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            /// Brand Dropdown Buttons (new horizontal position)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedBrands.map((brand) {
                  final products = brandProducts[brand] ?? [];
                  final totalQty = products.fold<int>(
                    0, (sum, p) => sum + (productQuantities[p["_id"]] ?? 0),
                  );
                  final totalVal = products.fold<double>(
                    0, (sum, p) => sum + ((productQuantities[p["_id"]] ?? 0) * (p["price"] ?? 0)),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: openedBrand == brand ? Colors.blue : Colors.grey.shade200,
                        foregroundColor: openedBrand == brand ? Colors.white : Colors.black87,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          openedBrand = openedBrand == brand ? null : brand;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(brand, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Text("₹${totalVal.toStringAsFixed(0)} / $totalQty units",
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),


            /// Products by Brand
            /// Products of Opened Brand Only
            if (openedBrand != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: (brandProducts[openedBrand!] ?? [])
                          .where((product) => product.values.any(
                            (v) => v.toString().toLowerCase().contains(searchQuery),
                      ))
                          .length,
                      itemBuilder: (context, index) {
                        final filtered = (brandProducts[openedBrand!] ?? []).where((product) {
                          if (searchQuery.isEmpty) return true;
                          return product.values.any((v) =>
                              v.toString().toLowerCase().contains(searchQuery));
                        }).toList();

                        final product = filtered[index];
                        final qty = productQuantities[product["_id"]] ?? 0;

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Color(0xFFF1F1FA),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product["product_name"] ?? "", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Code: ${product["product_code"] ?? ''}", style: TextStyle(fontSize: 12)),
                                    Text("₹ ${product["price"]}", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () => _updateQuantity(product, -1),
                                  ),
                                  Text("$qty", style: TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () => _updateQuantity(product, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),



            Divider(height: 30),



            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedDealer == null || totalUnits == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a dealer and add products.")),
                    );
                    return;
                  }

                  final allProducts = brandProducts.entries.expand((entry) {
                    return entry.value.where((p) => productQuantities[p["_id"]] != null).map((p) {
                      final qty = productQuantities[p["_id"]]!;
                      return {
                        "brand": p["brand"],
                        "product_name": p["product_name"],
                        "model_code": p["model_code"],
                        "price": p["price"],
                        "segment": p["segment"],
                        "product_code": p["product_code"],
                        "quantity": qty,
                        "amount": qty * p["price"],
                        "product_category": p["product_category"]
                      };
                    });
                  }).toList();

                  final payload = {
                    "dealer": selectedDealer!["code"],
                    "products": allProducts,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Extraction saved successfully.")),
                      );
                      Navigator.pop(context);
                    } else {
                      throw Exception("Failed");
                    }
                  } catch (e) {
                    print("Submit error: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Something went wrong. Please try again.")),
                    );
                  }
                },
                child: Text("Submit Extraction"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
