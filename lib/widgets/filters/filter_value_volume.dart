import 'package:flutter/material.dart';

class FilterValueVolume extends StatefulWidget {
  final Function(String) onTypeChange;
  final double fontSize;

  FilterValueVolume({required this.onTypeChange, required this.fontSize});

  @override
  _FilterValueVolumeState createState() => _FilterValueVolumeState();
}

class _FilterValueVolumeState extends State<FilterValueVolume> {
  String selectedType = 'Value';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio(
              value: 'Value',
              groupValue: selectedType,
              activeColor: Color(0xFF005bfe),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
                widget.onTypeChange(value!);
              },
            ),
            Text("Value", style: TextStyle(fontSize: widget.fontSize * 0.9)),
            SizedBox(width: 10),
            Radio(
              value: 'Volume',
              groupValue: selectedType,
              activeColor: Color(0xFFff3d02),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
                widget.onTypeChange(value!);
              },
            ),
            Text("Volume", style: TextStyle(fontSize: widget.fontSize * 0.9)),
          ],
        ),
      ],
    );
  }
}
