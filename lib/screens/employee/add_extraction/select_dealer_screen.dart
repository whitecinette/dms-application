// lib/screens/employee/add_extraction/select_dealer_screen.dart

import 'package:flutter/material.dart';
import 'package:dms_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectDealerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onDealerSelected;

  SelectDealerScreen({required this.onDealerSelected});

  @override
  _SelectDealerScreenState createState() => _SelectDealerScreenState();
}

class _SelectDealerScreenState extends State<SelectDealerScreen> {
  List<Map<String, dynamic>> allDealers = [];
  List<Map<String, dynamic>> filteredDealers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchDealers();
  }

  Future<void> fetchDealers() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("{{backend_url}}/user/get-dealers"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          allDealers = List<Map<String, dynamic>>.from(data['dealers']);
          filteredDealers = allDealers;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch dealers");
      }
    } catch (e) {
      print("❌ Dealer fetch error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() {
      searchQuery = value;
      filteredDealers = allDealers
          .where((dealer) =>
      dealer['name'].toLowerCase().contains(value.toLowerCase()) ||
          dealer['code'].toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Dealer")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Search dealer by name or code",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDealers.length,
              itemBuilder: (context, index) {
                final dealer = filteredDealers[index];
                return ListTile(
                  title: Text(dealer['name']),
                  subtitle: Text(dealer['code']),
                  onTap: () {
                    widget.onDealerSelected(dealer);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
