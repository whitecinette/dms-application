import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../config.dart';
import '../providers/extraction_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_extraction_step_two.dart';

class AddExtractionStep1 extends ConsumerStatefulWidget {

  final ScrollController scrollController;
  AddExtractionStep1({required this.scrollController});

  @override
  _AddExtractionStep1State createState() => _AddExtractionStep1State();
}


class _AddExtractionStep1State extends ConsumerState<AddExtractionStep1> {

  List<Map<String, dynamic>> dealers = [];
  Map<String, dynamic>? selectedDealer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDealers();
  }

  Future<void> fetchDealers() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${Config.backendUrl}/user/get-dealers"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          dealers = List<Map<String, dynamic>>.from(data['dealers']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch dealers");
      }
    } catch (e) {
      print("Error fetching dealers: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step 1: Select Dealer'),
        automaticallyImplyLeading: false, // Removes default back arrow
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
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
              Text("Select Dealer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return dealers;
                  return dealers.where((dealer) =>
                  dealer['name'].toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                      dealer['code'].toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                displayStringForOption: (option) => "${option['name']} (${option['code']})",
                onSelected: (dealer) {
                  setState(() {
                    selectedDealer = dealer;
                  });
                  ref.read(extractionFormProvider.notifier).setDealer(dealer);
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Search Dealer by name/code',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              if (selectedDealer != null) ...[
                SizedBox(height: 20),
                Text("Selected Dealer: ${selectedDealer!['name']} (${selectedDealer!['code']})"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      context: context,
                      builder: (context) {
                        return AddExtractionStep2(scrollController: ScrollController());
                      },
                    );
                  },
                  child: Text("Next"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

}
