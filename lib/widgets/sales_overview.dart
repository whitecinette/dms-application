import 'package:dms_app/utils/global_fucntions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../widgets/shimmer_loader.dart';
import '../providers/sales_filter_provider.dart';

class SalesOverview extends ConsumerStatefulWidget {
  final String token;

  const SalesOverview({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _SalesOverviewState createState() => _SalesOverviewState();
}

class _SalesOverviewState extends ConsumerState<SalesOverview> {
  Map<String, dynamic>? salesData;
  bool isLoading = true;
  bool hasError = false;

  SalesFilterState? previousFilters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentFilters = ref.watch(salesFilterProvider);

    if (previousFilters == null || !_isSameFilter(currentFilters, previousFilters!)) {
      previousFilters = currentFilters;
      fetchSalesData(currentFilters);
    }
  }

  bool _isSameFilter(SalesFilterState a, SalesFilterState b) {
    return a.selectedType == b.selectedType &&
        a.startDate == b.startDate &&
        a.endDate == b.endDate &&
        a.selectedSubordinate == b.selectedSubordinate &&
        _listEquals(a.selectedSubordinateCodes, b.selectedSubordinateCodes);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    return sortedA.every((element) => sortedB.contains(element));
  }

  Future<void> fetchSalesData(SalesFilterState filterState) async {
    final url = '${Config.backendUrl}/user/sales-data/dashboard/metrics/self';

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final body = filterState.getApiFilters();
      print("🔍 Sending Filters to API: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
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
      print("❌ API Error: $e");
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
      return Center(child: ShimmerLoader());
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
          formatIndianNumber(salesData!["mtd_sell_in"]),
          formatIndianNumber(salesData!["lmtd_sell_in"]),
          double.parse(salesData!["sell_in_growth"].toString()),
        ),
        SizedBox(height: 4),
        _buildRow(
          fontSize,
          boxHeight,
          "MTD Sell Out",
          "LMTD Sell Out",
          "Growth%",
          formatIndianNumber(salesData!["mtd_sell_out"]),
          formatIndianNumber(salesData!["lmtd_sell_out"]),
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
        _buildBox(fontSize, height, title1, value1, Color(0xFF005bfe)),
        SizedBox(width: 3),
        _buildBox(fontSize, height, title2, value2, Colors.orange),
        SizedBox(width: 3),
        _buildBox(fontSize, height, title3, "${growth.toStringAsFixed(1)}%",
            growth > 0 ? Colors.green : Colors.red),
      ],
    );
  }

  Widget _buildBox(double fontSize, double height, String title, String value, [Color? valueColor]) {
    return Expanded(
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: constraints.maxWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize * 0.75,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6C757D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
