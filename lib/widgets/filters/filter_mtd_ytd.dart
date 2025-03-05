import 'package:flutter/material.dart';

class FilterMTDYTD extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChange;
  final double fontSize; // Responsive font size

  FilterMTDYTD({required this.onFilterChange, required this.fontSize, required this.selectedFilter});



  @override
  _FilterMTDYTDState createState() => _FilterMTDYTDState();
}

class _FilterMTDYTDState extends State<FilterMTDYTD> {
  String selectedFilter = 'MTD';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio(
              value: 'MTD',
              groupValue: widget.selectedFilter,

              activeColor: Color(0xFF005bfe),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
                widget.onFilterChange(value!);
              },
            ),
            Text("MTD", style: TextStyle(fontSize: widget.fontSize * 0.9)),
            SizedBox(width: 10),
            // Radio(
            //   value: 'YTD',
            //   groupValue: selectedFilter,
            //   activeColor: Color(0xFFff3d02),
            //   onChanged: (value) {
            //     setState(() {
            //       selectedFilter = value!;
            //     });
            //     widget.onFilterChange(value!);
            //   },
            // ),
            // Text("YTD", style: TextStyle(fontSize: widget.fontSize * 0.9)),
          ],
        ),
      ],
    );
  }
}
