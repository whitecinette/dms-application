import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/extraction_form_provider.dart';
import '../../services/auth_service.dart';
import '../../config.dart';
import 'add_extraction_step_three.dart';

class AddExtractionStep2 extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  AddExtractionStep2({required this.scrollController});

  @override
  _AddExtractionStep2State createState() => _AddExtractionStep2State();
}

class _AddExtractionStep2State extends ConsumerState<AddExtractionStep2> {
  List<String> brands = [];
  bool isLoading = true;
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get-unique-brands"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          brands = List<String>.from(data['brands']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch brands");
      }
    } catch (e) {
      print("Error fetching brands: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formNotifier = ref.read(extractionFormProvider.notifier);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.95, // Almost full screen
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Brand",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return brands;
                    return brands.where((brand) =>
                        brand.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (brand) {
                    setState(() => selectedBrand = brand);
                    formNotifier.setBrand(brand);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Search brand...',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                if (selectedBrand != null) ...[
                  SizedBox(height: 20),
                  Text("Selected Brand: $selectedBrand"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final brand = ref.read(extractionFormProvider).brand ?? '';

                      Navigator.pop(context); // Close Step 2 modal

                      final notifier = ref.read(extractionFormProvider.notifier);

                      final result = await showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        backgroundColor: Colors.white,
                        builder: (context) => AddExtractionStep3(
                          scrollController: ScrollController(), // ✅ FIXED: define it here
                          brand: brand,
                        ),
                      );

                      if (result != true) {
                        notifier.setSelectedProducts([]); // 👈 Clear on swipe-down cancel
                      }
                    },

                    child: Text("Next"),
                  ),




                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

}
