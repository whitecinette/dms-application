import 'package:flutter/material.dart';

class FilterValueVolume extends StatefulWidget {
  final String selectedType;
  final Function(String) onTypeChange;
  final double fontSize;

  FilterValueVolume({
    required this.onTypeChange,
    required this.fontSize,
    required this.selectedType,
  });

  @override
  _FilterValueVolumeState createState() => _FilterValueVolumeState();
}

class _FilterValueVolumeState extends State<FilterValueVolume> {
  late String selectedType;

  @override
  void initState() {
    super.initState();
    selectedType = widget.selectedType; // Sync with parent initially
  }

  @override
  void didUpdateWidget(covariant FilterValueVolume oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If parent updates `selectedType`, update state
    if (widget.selectedType != oldWidget.selectedType) {
      setState(() {
        selectedType = widget.selectedType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio(
              value: 'value',  // API requires lowercase
              groupValue: selectedType.toLowerCase(), // Ensure lowercase for consistency
              activeColor: Color(0xFF005bfe),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
                widget.onTypeChange(value!);
              },
            ),
            Text(
              "Value",
              style: TextStyle(
                fontSize: widget.fontSize * 0.9,
                fontWeight: selectedType == 'value' ? FontWeight.bold : FontWeight.normal,
                color: selectedType == 'value' ? Color(0xFF005bfe) : Colors.black,
              ),
            ),
            SizedBox(width: 10),
            Radio(
              value: 'volume',  // API requires lowercase
              groupValue: selectedType.toLowerCase(), // Ensure lowercase for consistency
              activeColor: Color(0xFFff3d02),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
                widget.onTypeChange(value!);
              },
            ),
            Text(
              "Volume",
              style: TextStyle(
                fontSize: widget.fontSize * 0.9,
                fontWeight: selectedType == 'volume' ? FontWeight.bold : FontWeight.normal,
                color: selectedType == 'volume' ? Color(0xFFff3d02) : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
