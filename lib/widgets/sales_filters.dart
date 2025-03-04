import 'package:flutter/material.dart';
import 'filters/filter_mtd_ytd.dart';
import 'filters/filter_value_volume.dart';

class SalesFilters extends StatelessWidget {
  final Function(String) onFilterChange;
  final Function(String) onTypeChange;

  SalesFilters({required this.onFilterChange, required this.onTypeChange});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // Responsive width
    double fontSize = screenWidth * 0.035; // Dynamic font size

    return Container(
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 6), // Reduced top & bottom padding

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          // 30% Space for MTD/YTD
          Expanded(
            flex: 3, // 30% width
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterMTDYTD(onFilterChange: onFilterChange, fontSize: fontSize),
            ),
          ),

          // Pipe separator
          Text("|",
            style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),

          // 70% Space for Pipe + Value/Volume
          Expanded(
            flex: 7, // 70% width
            child: Align(
              alignment: Alignment.centerRight,
              child: FilterValueVolume(onTypeChange: onTypeChange, fontSize: fontSize),
            ),
          ),
        ],
      ),


    );
  }
}
