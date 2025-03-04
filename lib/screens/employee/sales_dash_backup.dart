import 'package:flutter/material.dart';

class SalesDashboard extends StatefulWidget {
  @override
  _SalesDashboardState createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  String selectedRadioValue = "MTD"; // Default selected radio value
  DateTime? startDate = DateTime(2025, 2, 1); // Default start date
  DateTime? endDate = DateTime(2025, 3, 1); // Default end date
  String selectedFilter = "All"; // Default filter option

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales Dashboard")),
      body: SingleChildScrollView(  // Wrap with scroll to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Box with radio buttons
              Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),  // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRadioTile("MTD"),
                    Container(height: 30, width: 1, color: Colors.grey), // Separator
                    _buildRadioTile("Value"),
                    _buildRadioTile("Volume"),
                  ],
                ),
              ),
              SizedBox(height: 10),  // Reduced space between boxes

              // Date selection row
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDatePicker("Start Date", startDate, isStartDate: true),
                    _buildDatePicker("End Date", endDate, isStartDate: false),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Sales data boxes
              GridView.count(
                crossAxisCount: 3,  // 3 columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true, // Prevent unnecessary scroll
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildDataCard("MTD Sell in Value", "34.66 L"),
                  _buildDataCard("LMTD Sell in Value", "--"),
                  _buildDataCard("Growth %", "NaN%"),
                  _buildDataCard("MTD Sell out Value", "76.91 L"),
                  _buildDataCard("LMTD Sell out Value", "--"),
                  _buildDataCard("Growth %", "NaN%"),
                ],
              ),
              SizedBox(height: 20),

              // Buttons (All and Dealer) aligned to the left
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildFilterButton("All"),
                  SizedBox(width: 10),
                  _buildFilterButton("Dealer"),
                ],
              ),
              SizedBox(height: 20),

              // Scrollable horizontal row with boxes like Segment, Channel, Model, etc.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,  // Horizontal scroll
                child: Row(
                  children: [
                    _buildScrollableBox("Segment"),
                    _buildScrollableBox("Channel"),
                    _buildScrollableBox("Model"),
                    _buildScrollableBox("Region"),
                    _buildScrollableBox("Salesperson"),
                    _buildScrollableBox("Customer"),
                    // Add more boxes as needed
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Table with segment-wise target and MTD values
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,  // Horizontal scroll for the table
                child: DataTable(
                  columns: [
                    DataColumn(label: Text("Segment")),
                    DataColumn(label: Text("Target Value")),
                    DataColumn(label: Text("MTD Value")),
                    DataColumn(label: Text("Growth")),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(Text("Segment 1")),
                      DataCell(Text("50 L")),
                      DataCell(Text("45 L")),
                      DataCell(Text("10%")),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Segment 2")),
                      DataCell(Text("60 L")),
                      DataCell(Text("50 L")),
                      DataCell(Text("5%")),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Segment 3")),
                      DataCell(Text("70 L")),
                      DataCell(Text("55 L")),
                      DataCell(Text("15%")),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Segment 4")),
                      DataCell(Text("80 L")),
                      DataCell(Text("75 L")),
                      DataCell(Text("2%")),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title) {
    return Row(
      children: [
        Radio<String>(
          value: title,
          groupValue: selectedRadioValue,
          onChanged: (String? value) {
            setState(() {
              selectedRadioValue = value!;
            });
          },
        ),
        Text(title, style: TextStyle(fontSize: 12)),  // Smaller text size
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, {required bool isStartDate}) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate!,
          firstDate: DateTime(2020),
          lastDate: DateTime(2025),
        );
        if (pickedDate != null) {
          setState(() {
            if (isStartDate) {
              startDate = pickedDate;
            } else {
              endDate = pickedDate;
            }
          });
        }
      },
      child: Row(
        children: [
          Text(
            "${selectedDate!.day} ${_monthToString(selectedDate.month)} ${selectedDate.year}",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }

  String _monthToString(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _buildDataCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(8),  // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),  // Smaller text size
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),  // Slightly bigger text size
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title) {
    bool isActive = selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),  // Adjusted padding for smaller button
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.blue),  // Smaller text size
        ),
      ),
    );
  }

  // Scrollable box for Segment, Channel, Model, etc.
  Widget _buildScrollableBox(String title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }
}
