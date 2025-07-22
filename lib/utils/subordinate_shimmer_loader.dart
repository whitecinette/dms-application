import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SubordinatePositionShimmer extends StatelessWidget {
  final int rows;

  const SubordinatePositionShimmer({super.key, this.rows = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (rowIndex) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(6, (index) {
              return Container(
                width: 90,
                height: 36,
                margin: const EdgeInsets.only(right: 10),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
