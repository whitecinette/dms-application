import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  late double _width;
  late double _height;

  Responsive(this.context) {
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
  }

  double width(double value) {
    return _width * (value / 375); // 375 is the base width for reference
  }

  double height(double value) {
    return _height * (value / 812); // 812 is the base height for reference
  }

  double fontSize(double value) {
    return _width * (value / 375);
  }

  bool isMobile() => _width < 600;
  bool isTablet() => _width >= 600 && _width < 1024;
  bool isDesktop() => _width >= 1024;
}
