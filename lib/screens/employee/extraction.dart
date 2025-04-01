import 'package:flutter/material.dart';
import '../../widgets/add_extraction_step_one.dart';

class ExtractionScreen extends StatefulWidget {
  @override
  _ExtractionScreenState createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  final List<String> tableHeaders = [
    "dealer_code",
    "product_name",
    "product_code",
    "product_category",
    "price",
    "quantity",
    "total",
    "segment",
  ];

  final List<Map<String, dynamic>> dummyData = [
    {
      "dealer_code": "D001",
      "product_name": "Galaxy A14",
      "product_code": "SM-A146BZKE",
      "product_category": "Smartphone",
      "price": 13999,
      "quantity": 5,
      "total": 69995,
      "segment": "10-15K"
    },
    {
      "dealer_code": "D002",
      "product_name": "Tab S6 Lite",
      "product_code": "SM-P613NZAA",
      "product_category": "Tablet",
      "price": 26999,
      "quantity": 2,
      "total": 53998,
      "segment": "25-30K"
    },
    {
      "dealer_code": "D003",
      "product_name": "Galaxy Watch 5",
      "product_code": "SM-R900NZ",
      "product_category": "Wearable",
      "price": 28999,
      "quantity": 1,
      "total": 28999,
      "segment": "20-30K"
    },
  ];

  List<Map<String, dynamic>> filteredData = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredData = dummyData;
    searchController.addListener(_filterData);
  }

  void _filterData() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredData = dummyData.where((row) {
        return row.values
            .map((value) => value.toString().toLowerCase())
            .any((value) => value.contains(query));
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _beautifyHeader(String header) {
    return header
        .replaceAll("_", " ")
        .split(" ")
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Extraction")),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.fromLTRB(10, 10, 10, 80), // padding for button
            child: Column(
              children: [
                // 🔍 Search bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 10),

                // 📊 Table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Color(0xFFE0E0E0)),
                        columnSpacing: 20,
                        columns: tableHeaders
                            .map((header) => DataColumn(
                          label: Text(
                            _beautifyHeader(header),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                            .toList(),
                        rows: filteredData
                            .map((row) => DataRow(
                          cells: tableHeaders
                              .map((header) => DataCell(Text("${row[header]}")))
                              .toList(),
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ➕ Sticky Add Button
          Positioned(
            bottom: 20,
            right: 10,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // <-- important
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    expand: false,
                    builder: (context, scrollController) {
                      return AddExtractionStep1(scrollController: scrollController); // 👈 pass scrollController
                    },
                  ),
                );
              },

              icon: Icon(Icons.add, color: Colors.white), // make icon white
              label: Text(
                "Add New",
                style: TextStyle(color: Colors.white), // 👈 white text
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // 👈 reduced radius
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              ),
            ),

          ),
        ],
      ),
    );
  }

  void _openAddExtractionForm(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false, // ⬅️ Don't expand over entire screen unless needed
          initialChildSize: 0.95, // ⬅️ Starts almost full height
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AddExtractionStep1(scrollController: scrollController);
          },
        );
      },
    );
  }




}
