import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates

class FilterDateRange extends StatefulWidget {
  final Function(DateTime, DateTime) onDateChange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  FilterDateRange({
    required this.onDateChange,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  _FilterDateRangeState createState() => _FilterDateRangeState();
}

class _FilterDateRangeState extends State<FilterDateRange> {

  @override
  void initState() {
    super.initState();
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
  }

  DateTime? startDate;
  DateTime? endDate;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && picked.isAfter(endDate!)) {
            endDate = null; // Optional: reset endDate if start is after end
          }
        } else {
          endDate = picked;
        }
      });

      if (startDate != null && endDate != null) {
        widget.onDateChange(startDate!, endDate!);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.035; // Responsive font size

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Start Date Selector
          GestureDetector(
            onTap: () => _selectDate(context, true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Start Date",
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.orange)),
                Text(
                  startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : "Select Date",
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Pipe Separator
          Text("|", style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.bold, color: Colors.black)),

          // End Date Selector
          GestureDetector(
            onTap: () => _selectDate(context, false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("End Date",
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.orange)),
                Text(
                  endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : "Select Date",
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
