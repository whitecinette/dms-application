import 'dart:convert';
import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool showPunchIn = true;
  String? selectedStatus;
  List<String> statusOptions = [
    "All",
    "Pending",
    "Present",
    "Absent",
    "Half Day",
    "Approved",
    "Rejected",
  ];

  late Future<List<Map<String, dynamic>>> attendanceFuture;

  @override
  void initState() {
    super.initState();
    attendanceFuture = ApiService.getEmployeeAttendance();
  }

  void _filterByStatus(String? status) {
    setState(() {
      selectedStatus = status;
      attendanceFuture = ApiService.getEmployeeAttendance(
        status: status != null && status != "All" ? status : null,
      );
    });
  }

  String formatDate(String date) {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
  }

  String formatTime(String time) {
    return DateFormat('hh:mm a').format(DateTime.parse(time));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance")),
      body: Column(
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showPunchIn = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showPunchIn ? Colors.blue : Colors.grey[300],
                    ),
                    child: Text(
                      "Punch In",
                      style: TextStyle(
                        color: showPunchIn ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showPunchIn = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showPunchIn ? Colors.blue : Colors.grey[300],
                    ),
                    child: Text(
                      "Punch Out",
                      style: TextStyle(
                        color: !showPunchIn ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedStatus ?? "All",
              decoration: const InputDecoration(
                labelText: "Filter by Status",
                border: OutlineInputBorder(),
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                _filterByStatus(value);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Data
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: attendanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show shimmer while loading
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date & status shimmer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(width: 100, height: 16, color: Colors.white),
                                    Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Punch in/out shimmer
                                Row(
                                  children: [
                                    CircleAvatar(radius: 30, backgroundColor: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(width: 120, height: 14, color: Colors.white),
                                          const SizedBox(height: 6),
                                          Container(width: 100, height: 12, color: Colors.white),
                                          const SizedBox(height: 6),
                                          Container(width: 150, height: 12, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Hours worked shimmer
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 20, color: Colors.grey[400]),
                                    const SizedBox(width: 6),
                                    Container(width: 120, height: 12, color: Colors.white),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Something went wrong. Please try again.",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final data = snapshot.data;

                if (data == null || data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          selectedStatus == null || selectedStatus == "All"
                              ? "No attendance records found."
                              : "No records found for status: $selectedStatus",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDate(item['date']),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item['status'] == "Pending" ? Colors.orange[100] : Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['status'],
                                    style: TextStyle(
                                      color: item['status'] == "Pending" ? Colors.orange[800] : Colors.green[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Punch In or Out
                            if (showPunchIn)
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(item['punchInImage']),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Punch In: ${formatTime(item['punchIn'])}",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        Text("Code: ${item['punchInCode'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
                                        Text("Location: ${item['punchInName']}", style: TextStyle(color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: item['punchOutImage'] != null
                                        ? NetworkImage(item['punchOutImage'])
                                        : const AssetImage("assets/images/placeholder.png") as ImageProvider,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Punch Out: ${item['punchOut'] != null ? formatTime(item['punchOut']) : 'Not yet'}",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        Text("Code: ${item['punchOutCode'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
                                        Text("Location: ${item['punchOutName'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 10),

                            // Hours Worked
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  "Hours Worked: ${item['hoursWorked']}",
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
