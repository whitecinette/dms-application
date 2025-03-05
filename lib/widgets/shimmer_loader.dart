import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: screenHeight, // Fullscreen
      color: Colors.white,
      child: SingleChildScrollView( // Prevent overflow with scrolling
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Placeholder
              _shimmerBox(width: screenWidth * 0.84, height: 25),
              SizedBox(height: 20),

              // Filters Row (Ensuring Responsiveness)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _shimmerBox(width: screenWidth * 0.25, height: 40), // Filter 1
                    SizedBox(width: 10),
                    _shimmerBox(width: screenWidth * 0.24, height: 40), // Filter 2
                    SizedBox(width: 10),
                    _shimmerBox(width: screenWidth * 0.3, height: 40), // Filter 3
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Dashboard Stats (MTD, LMTD, Growth)
              Row(
                children: [
                  Expanded(child: _shimmerBox(width: double.infinity, height: 70)),
                  SizedBox(width: 10),
                  Expanded(child: _shimmerBox(width: double.infinity, height: 70)),
                  SizedBox(width: 10),
                  Expanded(child: _shimmerBox(width: double.infinity, height: 70)),
                ],
              ),

              SizedBox(height: 20),

              // Graph Placeholder
              _shimmerBox(width: double.infinity, height: 150),
              SizedBox(height: 20),

              // Table Placeholder (Scrollable for Overflow Fix)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: List.generate(8, (index) => _buildTableRow(screenWidth)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTableRow(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          _shimmerBox(width: screenWidth * 0.15, height: 20), // Column 1
          SizedBox(width: 10),
          _shimmerBox(width: screenWidth * 0.25, height: 20), // Column 2
          SizedBox(width: 10),
          _shimmerBox(width: screenWidth * 0.2, height: 20), // Column 3
          SizedBox(width: 10),
          _shimmerBox(width: screenWidth * 0.15, height: 20), // Column 4
          SizedBox(width: 10),
          _shimmerBox(width: screenWidth * 0.15, height: 20), // Column 5
        ],
      ),
    );
  }
}
