import 'package:flutter/material.dart';

class FilterSubordinates extends StatefulWidget {
  @override
  _FilterSubordinatesState createState() => _FilterSubordinatesState();
}

class _FilterSubordinatesState extends State<FilterSubordinates> {
  String selectedPosition = "ALL"; // Default selected
  Map<String, bool> dropdownState = {}; // Track dropdown visibility

  final List<String> positions = ["ALL", "ASM", "ZSM", "MDD", "TSE", "Dealer"];
  final List<Map<String, dynamic>> dummyData = List.generate(10, (index) => {
    "name": index % 2 == 0 ? "Varun Bansal" : "Other ZSM",
    "position": index % 2 == 0 ? "ZSM" : "ASM",
    "id": "JPR${index + 1}",
    "mtd": "24.58K",
    "lmtd": "33.23K",
    "growth": index % 2 == 0 ? (index + 1) * 2.5 : -(index + 1) * 1.8,
  });



  void toggleDropdown(String position) {
    setState(() {
      dropdownState.forEach((key, value) {
        dropdownState[key] = false; // Close all other dropdowns
      });
      dropdownState[position] = !(dropdownState[position] ?? false); // Toggle the clicked one
    });
  }


  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.035;

    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Detect taps outside
      onTap: () {
        setState(() {
          dropdownState.forEach((key, value) {
            dropdownState[key] = false; // Close all dropdowns on outside tap
          });
        });
      },
      child: Column(
        children: [
          // Positions Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, spreadRadius: 2),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: positions.map((position) {
                return GestureDetector(
                  onTap: () {
                    if (position != "ALL") toggleDropdown(position);
                  },
                  child: Text(
                    position,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: position == "ALL" ? FontWeight.bold : FontWeight.w500,
                      color: position == "ALL" ? Colors.orange : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 2),

          // Dropdowns
          Column(
            children: positions.where((pos) => pos != "ALL").map((position) {
              if (dropdownState[position] ?? false) {
                return _buildDropdown(position, fontSize);
              }
              return SizedBox.shrink();
            }).toList(),
          ),
        ],
      ),
    );


  }

  Widget _buildDropdown(String position, double fontSize) {
    List<Map<String, dynamic>> filteredData =
    dummyData.where((entry) => entry["position"] == position).toList();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, spreadRadius: 2),
        ],
      ),
      child: Container(
        height: 200, // Set height for scrollability
        child: SingleChildScrollView(
          child: Column(
            children: filteredData.map((entry) {
              return GestureDetector(
                onTap: () {
                  print("Clicked on ${entry["name"]} for full report"); // Placeholder for future navigation
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white, // Light background for contrast
                    borderRadius: BorderRadius.circular(8),
                    // border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12), // rgba(0, 0, 0, 0.12)
                        offset: Offset(0, 1), // 0px 1px
                        blurRadius: 1, // 3px
                        spreadRadius: 0, // No spread
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.24), // rgba(0, 0, 0, 0.24)
                        offset: Offset(0, 1), // 0px 1px
                        blurRadius: 2, // 2px
                        spreadRadius: 0, // No spread
                      ),
                    ],


                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _tableText(entry["name"], fontSize, Colors.black),
                          _tableText("MTD SO", fontSize * 0.9, Colors.black54),
                          _tableText("LMTD SO", fontSize * 0.9, Colors.black54),
                          _tableText("%Gwth", fontSize * 0.9, Colors.black54),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Data Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _tableText(entry["id"], fontSize, Colors.black),
                          _tableText(entry["mtd"], fontSize, Color(0xFF005bfe)), // MTD (Blue)
                          _tableText(entry["lmtd"], fontSize, Color(0xFFff3d02)), // LMTD (Orange)
                          _tableText(
                            "${entry["growth"].toStringAsFixed(2)}%",
                            fontSize,
                            entry["growth"] > 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }



  Widget _headerText(String text, double fontSize) {
    return Text(text, style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.bold, color: Colors.black54));
  }

  Widget _tableText(String text, double fontSize, Color color) {
    return Text(text, style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.w500, color: color));
  }
}
