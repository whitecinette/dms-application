// lib/screens/employee/sales_dashboard.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllAttendanceScreen extends StatelessWidget {
  final List<Map<String, dynamic>> attendance = [
    {
      "_id": "67d7c623b9643f02b62a3d5f",
      "code": "RAJF0000001",
      "date": "2025-03-17T00:00:00.000Z",
      "punchIn": "2025-03-17T06:50:08.000Z",
      "status": "Pending",
      "punchInImage": "https://res.cloudinary.com/dmjtisnc9/image/upload/v1742194210/gpunchInImage/esjrfuxqmxkktdul7gnu.jpg",
      "name": "Anshu Mishra",
    },
    {
      "_id": "67d7c65cb9643f02b62a3ee1",
      "code": "RAJF001262",
      "date": "2025-03-17T00:00:00.000Z",
      "punchIn": "2025-03-17T06:51:05.000Z",
      "status": "Pending",
      "punchInImage": "https://res.cloudinary.com/dmjtisnc9/image/upload/v1742194267/gpunchInImage/iahtnvlwta6rf0u3xfiw.jpg",
      "name": "Hemant Sharma",
    },
  ];

  String formatDate(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  String formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Attendance")),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: attendance.length,
        itemBuilder: (context, index) {
          final item = attendance[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(item["punchInImage"]),
                radius: 25,
              ),
              title: Text(item["name"], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Code: ${item["code"]}"),
                  Text("Date: ${formatDate(item["date"])}"),
                  Text("Punch In: ${formatTime(item["punchIn"])}"),
                  Text("Status: ${item["status"]}"),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
