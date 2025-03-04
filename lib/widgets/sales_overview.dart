import 'package:flutter/material.dart';

class SalesOverview extends StatelessWidget {
  const SalesOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery
        .of(context)
        .size
        .width * 0.035; // Responsive font size
    double boxHeight = 70; // Set uniform box height

    return Column(
      children: [
        _buildRow(fontSize, boxHeight, "MTD Sell In", "LMTD Sell In", "Growth%", "45.78K", "56.67L", 12.45),
        SizedBox(height: 4),
        _buildRow(fontSize, boxHeight, "MTD Sell Out", "LMTD Sell Out", "Growth%", "67.89K", "48.21L", -8.32)
      ],
    );
  }

  Widget _buildRow(double fontSize, double height, String title1, String title2,
      String title3,
      String value1, String value2, double growth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBox(
            fontSize, height, title1, value1.toString(), Color(0xFF005bfe)),
        // MTD (Blue)
        SizedBox(width: 10),
        _buildBox(
            // fontSize, height, title2, value2.toString(), Color(0xFF005bfe)),
            fontSize, height, title2, value2.toString(), Colors.orange),

    // LMTD (Orange)
        SizedBox(width: 10),
        _buildBox(fontSize, height, title3, "${growth.toStringAsFixed(2)}%",
            growth > 0 ? Colors.green : Colors.red),
        // Growth %
      ],
    );
  }


  Widget _buildBox(double fontSize, double height, String title, String value,
      [Color? valueColor]) {
    return Expanded(

      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        // Adjusted padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          // Light border
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Align text to the left
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Label (Gray Color, Smaller Font)
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize * 0.75, // Decreased label size
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C757D), // Gray color for labels
              ),
            ),
            SizedBox(height: 8),

            // Value (Bigger Font, Dynamic Color)
            Expanded( // Values expand to take remaining space
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 2, // Increased size for value
                  // fontWeight: title.contains("Growth") ? FontWeight.bold : FontWeight.w400, // Bold only for Growth%
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Roboto', // Sleek, modern font (optional)
                  color: valueColor ?? Colors.black, // Dynamic color
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

