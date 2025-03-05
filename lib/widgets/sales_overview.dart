import 'package:dms_app/utils/global_fucntions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Import config file for backend URL

class SalesOverview extends StatefulWidget {
  final String filterType; // Accepts 'value' or 'volume'
  final String startDate;
  final String endDate;
  final String token; // Bearer token for API

  const SalesOverview({
    Key? key,
    required this.filterType,
    required this.startDate,
    required this.endDate,
    required this.token,
  }) : super(key: key);

  @override
  _SalesOverviewState createState() => _SalesOverviewState();
}

class _SalesOverviewState extends State<SalesOverview> {
  Map<String, dynamic>? salesData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchSalesData();
  }

  @override
  void didUpdateWidget(SalesOverview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If filter type or date range changes, re-fetch data
    if (widget.filterType != oldWidget.filterType ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      fetchSalesData();
    }
  }


  Future<void> fetchSalesData() async {
    final url = '${Config.backendUrl}/user/sales-data/dashboard/metrics/self';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "filter_type": widget.filterType.toLowerCase(), // Ensure lowercase
          "start_date": widget.startDate,
          "end_date": widget.endDate,
        }),

      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse["success"]) {
          setState(() {
            salesData = decodedResponse["data"];
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
          });
        }
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.035;
    double boxHeight = 70;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (hasError || salesData == null) {
      return Center(
        child: Text("Error loading data", style: TextStyle(color: Colors.red)),
      );
    }

    return Column(
      children: [
        _buildRow(
          fontSize,
          boxHeight,
          "MTD Sell In",
          "LMTD Sell In",
          "Growth%",
          formatIndianNumber(salesData!["mtd_sell_in"]), // Apply formatting here
          formatIndianNumber(salesData!["lmtd_sell_in"]), // Apply formatting here
          double.parse(salesData!["sell_in_growth"].toString()),
        ),
        SizedBox(height: 4),
        _buildRow(
          fontSize,
          boxHeight,
          "MTD Sell Out",
          "LMTD Sell Out",
          "Growth%",
          formatIndianNumber(salesData!["mtd_sell_out"]), // Apply formatting here
          formatIndianNumber(salesData!["lmtd_sell_out"]), // Apply formatting here
          double.parse(salesData!["sell_out_growth"].toString()),
        ),
      ],
    );
  }

  Widget _buildRow(double fontSize, double height, String title1, String title2, String title3,
      String value1, String value2, double growth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBox(fontSize, height, title1, value1, Color(0xFF005bfe)), // MTD (Blue)
        SizedBox(width: 10),
        _buildBox(fontSize, height, title2, value2, Colors.orange), // LMTD (Orange)
        SizedBox(width: 10),
        _buildBox(fontSize, height, title3, "${growth.toStringAsFixed(2)}%",
            growth > 0 ? Colors.green : Colors.red), // Growth %
      ],
    );
  }

  Widget _buildBox(double fontSize, double height, String title, String value, [Color? valueColor]) {
    return Expanded(
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize * 0.75,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C757D),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 2,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Roboto',
                  color: valueColor ?? Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
