import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sales_filter_provider.dart';

class FilterValueVolume extends ConsumerWidget {
  final double fontSize;

  FilterValueVolume({required this.fontSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(salesFilterProvider).selectedType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio(
              value: 'value',
              groupValue: selectedType,
              activeColor: Color(0xFF005bfe),
              onChanged: (value) {
                ref.read(salesFilterProvider.notifier).updateType(value!);
              },
            ),

            Text(
              "Value",
              style: TextStyle(
                fontSize: fontSize * 0.9,
                fontWeight: selectedType == 'value' ? FontWeight.bold : FontWeight.normal,
                color: selectedType == 'value' ? Color(0xFF005bfe) : Colors.black,
              ),
            ),
            SizedBox(width: 10),
            Radio(
              value: 'volume',
              groupValue: selectedType,
              activeColor: Color(0xFFff3d02),
              onChanged: (value) {
                ref.read(salesFilterProvider.notifier).updateType(value!);
              },
            ),
            Text(
              "Volume",
              style: TextStyle(
                fontSize: fontSize * 0.9,
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
