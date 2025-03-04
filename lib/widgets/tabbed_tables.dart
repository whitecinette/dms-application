import 'package:flutter/material.dart';

class TabbedTables extends StatefulWidget {
  @override
  _TabbedTablesState createState() => _TabbedTablesState();
}

class _TabbedTablesState extends State<TabbedTables> {
  String activeTab = "Segment"; // Default active tab

  final List<String> tabs = ["Segment", "Channel", "Model"];

  final Map<String, dynamic> tableData = {
    "headers": [
      "Segment/Channel",
      "Target",
      "MTD",
      "LMTD",
      "Pending",
      "ADS",
      "Req. ADS",
      "% Growth",
      "FTD",
      "% Contribution"
    ],
    "Segment": [
      {
        "Segment/Channel": "SIS PLUS",
        "Target": 0,
        "MTD": 25,
        "LMTD": 53,
        "Pending": -25,
        "ADS": "6.25",
        "Req. ADS": "0.00",
        "% Growth": "-52.83",
        "FTD": 2,
        "% Contribution": "14.53"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
      {
        "Segment/Channel": "STAR DCM",
        "Target": 0,
        "MTD": 0,
        "LMTD": -1,
        "Pending": 0,
        "ADS": "0.00",
        "Req. ADS": "0.00",
        "% Growth": "-100.00",
        "FTD": 0,
        "% Contribution": "0.00"
      },
    ],
    "Channel": [
      {
        "Segment/Channel": "Online",
        "Target": 10,
        "MTD": 5,
        "LMTD": 8,
        "Pending": 5,
        "ADS": "3.00",
        "Req. ADS": "2.00",
        "% Growth": "-37.50",
        "FTD": 1,
        "% Contribution": "25.00"
      },
    ],
    "Model": [
      {
        "Segment/Channel": "Galaxy S22",
        "Target": 50,
        "MTD": 30,
        "LMTD": 20,
        "Pending": 20,
        "ADS": "7.50",
        "Req. ADS": "5.00",
        "% Growth": "50.00",
        "FTD": 3,
        "% Contribution": "60.00"
      },
    ]
  };

  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.035;

    return Column(
      children: [
        // Tabs
        Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, spreadRadius: 2),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tabs.map((tab) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    activeTab = tab;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: activeTab == tab ? Colors.blue : Colors.transparent,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: activeTab == tab ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 10),

        // Table
        _buildTable(tableData["headers"], tableData[activeTab], fontSize),
      ],
    );
  }

  Widget _buildTable(List<String> headers, List<Map<String, dynamic>> data, double fontSize) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          // Scrollable Table
          SizedBox(
            height: 300, // Fixed height for vertical scroll
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Enable vertical scroll
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scroll
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 50,
                  dataRowHeight: 45,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: headers.map((header) {
                    return DataColumn(
                      label: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          header,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  rows: data.map((row) {
                    return DataRow(
                      cells: headers.map((header) {
                        return DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              row[header].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontSize * 0.85,
                                fontWeight: header == headers.first
                                    ? FontWeight.bold // First column bold
                                    : FontWeight.normal,
                                color: header == "% Growth"
                                    ? (double.parse(row[header].toString()) > 0
                                    ? Colors.green
                                    : Colors.red) // Color growth percentage
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}
