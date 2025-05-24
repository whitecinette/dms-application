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
  DateTime? startDate;
  DateTime? endDate;
  int page = 1;
  bool isLoadingMore = false;
  bool hasMore = true;

  List<Map<String, dynamic>> attendanceData = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          hasMore) {
        _fetchAttendanceData();
      }
    });
  }

  Future<void> _fetchAttendanceData({bool reset = false}) async {
    if (reset) {
      setState(() {
        page = 1;
        attendanceData.clear();
        hasMore = true;
      });
    }

    setState(() {
      isLoadingMore = true;
    });

    final newData = await ApiService.getEmployeeAttendance(
      status: selectedStatus != null && selectedStatus != "All" ? selectedStatus : null,
      startDate: startDate,
      endDate: endDate,
      page: page,
    );

    setState(() {
      if (newData.isEmpty) {
        hasMore = false;
      } else {
        attendanceData.addAll(newData);
        page++;
      }
      isLoadingMore = false;
    });
  }

  void _filterByStatus(String? status) {
    setState(() {
      selectedStatus = status;
    });
    _fetchAttendanceData(reset: true);
  }

  String formatDate(String date) =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal());

  String formatTime(String time) =>
      DateFormat('hh:mm a').format(DateTime.parse(time).toLocal());

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Approved":
      case "Present":
        return Colors.green;
      case "Absent":
      case "Rejected":
        return Colors.red;
      case "Half Day":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchAttendanceData(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔁 Toggle Buttons for Punch In / Punch Out
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => showPunchIn = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: showPunchIn
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                          child: Text(
                            "Punch In",
                            style: TextStyle(
                              color:
                              showPunchIn ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => showPunchIn = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !showPunchIn
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                          child: Text(
                            "Punch Out",
                            style: TextStyle(
                              color: !showPunchIn
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 🔍 Status Dropdown Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus ?? "All",
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                        items: ["All", "Present", "Absent", "Half Day",
                          "Pending"]
                            .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                            .toList(),
                        onChanged: _filterByStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => selectedStatus = null);
                        _fetchAttendanceData(reset: true);
                      },
                    )
                  ],
                ),

                const SizedBox(height: 12),

                // 📆 Date Pickers Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Start Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : "Select",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "End Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : "Select",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          startDate = null;
                          endDate = null;
                        });
                        _fetchAttendanceData(reset: true);
                      },
                    )
                  ],
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _fetchAttendanceData(reset: true),
                    child: const Text("Apply Filters"),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: attendanceData.isEmpty && isLoadingMore
                ? ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => ShimmerPlaceholder(),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: attendanceData.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == attendanceData.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = attendanceData[index];

                return AttendanceCard(
                  item: item,
                  showPunchIn: showPunchIn,
                  formatDate: formatDate,
                  formatTime: formatTime,
                  getStatusColor: _getStatusColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// COMPONENT: Shimmer placeholder
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 120),
      ),
    );
  }
}

// COMPONENT: Attendance Card
class AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showPunchIn;
  final String Function(String) formatDate;
  final String Function(String) formatTime;
  final Color Function(String) getStatusColor;

  const AttendanceCard({
    required this.item,
    required this.showPunchIn,
    required this.formatDate,
    required this.formatTime,
    required this.getStatusColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDate(item['date']),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(item['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item['status'],
                      style: TextStyle(
                          color: getStatusColor(item['status']),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (showPunchIn)
              _buildPunchRow(
                imageUrl: item['punchInImage'],
                label: 'Punch In',
                time: item['punchIn'],
                code: item['punchInCode'],
                location: item['punchInName'],
                formatTime: formatTime,
              )
            else
              _buildPunchRow(
                imageUrl: item['punchOutImage'],
                label: 'Punch Out',
                time: item['punchOut'],
                code: item['punchOutCode'],
                location: item['punchOutName'],
                formatTime: formatTime,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text("Hours Worked: ${item['hoursWorked'] ?? 'N/A'}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchRow({
    required String? imageUrl,
    required String label,
    required String? time,
    required String? code,
    required String? location,
    required String Function(String) formatTime,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: imageUrl != null
              ? NetworkImage(imageUrl)
              : const AssetImage("assets/images/placeholder.png") as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$label: ${time != null ? formatTime(time) : 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("Code: ${code ?? 'N/A'}"),
              Text("Location: ${location ?? 'N/A'}"),
            ],
          ),
        ),
      ],
    );
  }
}
