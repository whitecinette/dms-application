import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subordinates_provider.dart';
import 'package:dms_app/widgets/shimmer_loader.dart';

class FilterSubordinates extends ConsumerStatefulWidget {
  @override
  _FilterSubordinatesState createState() => _FilterSubordinatesState();
}

class _FilterSubordinatesState extends ConsumerState<FilterSubordinates> {
  String? selectedCode; // Track selected subordinate
  String? selectedPosition; // Track current position

  @override
  Widget build(BuildContext context) {
    final subordinatesState = ref.watch(subordinatesProvider);

    return subordinatesState.when(
      data: (subordinatesMap) {
        List<String> positions = subordinatesMap.keys.toList();

        return Column(
          children: [
            // ✅ Styled Positions Row (Now Like a Toggle Bar)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow scrolling if many positions
              child: Row(
                children: positions.map((position) {
                  bool isSelected = position == selectedPosition;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPosition = position;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      margin: EdgeInsets.only(right: 10), // Spacing between buttons
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black87 : Colors.white, // Dark for selected
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Color(0xFF42A5F5), // Border color
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            position.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black, // White text for selected
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 6), // Space between text and checkmark
                            Icon(Icons.check, size: 14, color: Colors.white),
                          ]
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 10),

            // ✅ Dropdown of Subordinates
            if (selectedPosition != null && subordinatesMap[selectedPosition] != null)
              _buildDropdown(subordinatesMap[selectedPosition]!),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()), // ✅ Show loader
      error: (err, _) => Center(child: Text("Error: $err")), // ✅ Show error
    );
  }

  Widget _buildDropdown(List<Subordinate> subordinates) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.3, // ✅ 30vh Fixed Height
        child: SingleChildScrollView(
          child: Column(
            children: subordinates.map((sub) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCode = sub.code;
                  });

                  // ✅ Fetch next-level subordinates dynamically
                  ref.read(subordinatesProvider.notifier)
                      .fetchSubordinatesByCode(selectedPosition!, sub.code);
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: selectedCode == sub.code
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12),
                        offset: Offset(0, 1),
                        blurRadius: 1,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.24),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _headerText(sub.code, 12), // Code
                          _headerText("MTD SO", 12),
                          _headerText("LMTD SO", 12),
                          _headerText("%Gwth", 12),
                        ],
                      ),
                      SizedBox(height: 4),

                      // ✅ Data Row (Fixed Width for Name)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120.0, // ✅ Fixed Width for Name
                            child: Text(
                              sub.name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                              maxLines: 2, // ✅ Wrap text to next line if long
                              overflow: TextOverflow.visible, // ✅ Ensures visibility of full name
                            ),
                          ),
                          _valueText("${sub.mtdSellOut}", 14, Colors.blue),
                          _valueText("${sub.lmtdSellOut}", 14, Colors.orange),
                          _valueText(
                            "${sub.sellOutGrowth}%",
                            14,
                            double.parse(sub.sellOutGrowth) > 0 ? Colors.green : Colors.red,
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

// ✅ Utility Widgets for Styling
  Widget _headerText(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize*0.8,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    );
  }

  Widget _valueText(String text, double fontSize, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
