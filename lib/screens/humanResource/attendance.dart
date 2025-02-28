import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, String>> attendanceRequests = [
    {"name": "John Doe", "date": "27 Feb", "time": "10:00 AM", "status": "Present"},
    {"name": "Jane Smith", "date": "27 Feb", "time": "10:30 AM", "status": "Leave"},
    {"name": "Alice Brown", "date": "27 Feb", "time": "11:00 AM", "status": "Absent"},
    {"name": "Bob Johnson", "date": "27 Feb", "time": "11:30 AM", "status": "Overtime"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AttendanceCard(title: "All"),
                  AttendanceCard(title: "Leave"),
                  AttendanceCard(title: "Absent"),
                  AttendanceCard(title: "Present"),
                  AttendanceCard(title: "Overtime"),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceRequests.length,
                itemBuilder: (context, index) {
                  final request = attendanceRequests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttendanceApprovalCard(
                      name: request["name"]!,
                      date: request["date"]!,
                      time: request["time"]!,
                      tag: request["status"]!,
                      onApprove: () {
                        print("${request["name"]} Approved");
                      },
                      onReject: () {
                        print("${request["name"]} Rejected");
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final String title;

  const AttendanceCard({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 35,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AttendanceApprovalCard extends StatelessWidget {
  final String name;
  final String date;
  final String time;
  final String tag;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const AttendanceApprovalCard({
    Key? key,
    required this.name,
    required this.date,
    required this.time,
    required this.tag,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: Text("Approve", style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: onReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: Text("Reject", style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
