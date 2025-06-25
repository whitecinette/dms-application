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
  String? selectedStatus;
  DateTimeRange? selectedDateRange;
  int page = 1;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool showAttendance = true;

  // Leave filters:
  String? leaveSelectedStatus;
  DateTimeRange? leaveSelectedDateRange;

  List<Map<String, dynamic>> attendanceData = [];
  List<Map<String, dynamic>> leaveData = [];
  bool isLeaveLoading = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          hasMore) {
        _fetchAttendanceData();
      }
    });
  }

  Future<void> _fetchAttendanceData({bool reset = false}) async {
    if (!showAttendance) return;

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

    try {
      final newData = await ApiService.getEmployeeAttendance(
        status: selectedStatus != null && selectedStatus != "All"
            ? selectedStatus
            : null,
        startDate: selectedDateRange?.start,
        endDate: selectedDateRange?.end,
        page: page,
      );

      setState(() {
        if (newData.isEmpty) {
          hasMore = false;
        } else {
          attendanceData.addAll(newData);
          page++;
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchLeaveData({bool reset = false}) async {
    if (showAttendance) return;

    if (reset) {
      setState(() {
        leaveData.clear();
      });
    }

    setState(() {
      isLeaveLoading = true;
    });
    try {
      final data = await ApiService.getRequestedLeaves(
        fromDate: leaveSelectedDateRange != null
            ? leaveSelectedDateRange!.start.toIso8601String()
            : null,
        toDate: leaveSelectedDateRange != null
            ? leaveSelectedDateRange!.end.toIso8601String()
            : null,
        status: leaveSelectedStatus != null && leaveSelectedStatus != "All"
            ? leaveSelectedStatus
            : null,
      );
      setState(() {
        leaveData = data;
      });
    } catch (e) {
      print('Error fetching leave data: $e');
    } finally {
      setState(() {
        isLeaveLoading = false;
      });
    }
  }

  void _filterLeaveByStatus(String? status) {
    setState(() {
      leaveSelectedStatus = status;
    });
    _fetchLeaveData(reset: true);
  }

  void _filterByStatus(String? status) {
    setState(() {
      selectedStatus = status;
    });
    _fetchAttendanceData(reset: true);
  }

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: selectedDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() => selectedDateRange = picked);
      _fetchAttendanceData(reset: true);
    }
  }

  void _pickLeaveDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: leaveSelectedDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() => leaveSelectedDateRange = picked);
      _fetchLeaveData(reset: true);
    }
  }

  void _clearFilters() {
    setState(() {
      selectedDateRange = null;
      selectedStatus = null;
    });
    _fetchAttendanceData(reset: true);
  }

  void _clearLeaveFilters() {
    setState(() {
      leaveSelectedDateRange = null;
      leaveSelectedStatus = null;
    });
    _fetchLeaveData(reset: true);
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  String formatDateString(String date) =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal());
  String formatTime(String time) =>
      DateFormat('hh:mm a').format(DateTime.parse(time).toLocal());

  Color _getStatusColor(String? status) {
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

  Widget _buildLeaveFilterUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickLeaveDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            leaveSelectedDateRange == null
                                ? "Select Date Range"
                                : "${formatDate(leaveSelectedDateRange!.start)} - ${formatDate(leaveSelectedDateRange!.end)}",
                            style: TextStyle(
                              fontSize: 16,
                              color: leaveSelectedDateRange == null ? Colors.grey.shade600 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (leaveSelectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => leaveSelectedDateRange = null);
                    _fetchLeaveData(reset: true);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: leaveSelectedStatus ?? "All",
                  decoration: InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                  items: ["All", "pending", "approved", "rejected"]
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value == "All") value = null;
                    _filterLeaveByStatus(value);
                  },
                ),
              ),
              if (leaveSelectedStatus != null || leaveSelectedDateRange != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: ElevatedButton.icon(
                    onPressed: _clearLeaveFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text("Clear Filters"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList() {
    if (isLeaveLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (leaveData.isEmpty) {
      return const Center(child: Text("No leave requests found."));
    }
    return ListView.builder(
      itemCount: leaveData.length,
      itemBuilder: (context, index) => LeaveCard(leave: leaveData[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: () {
              if (showAttendance) {
                _fetchAttendanceData(reset: true);
              } else {
                _fetchLeaveData(reset: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!showAttendance) {
                      setState(() => showAttendance = true);
                      _fetchAttendanceData(reset: true);
                    }
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: showAttendance
                          ? Colors.blue.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        color: showAttendance ? Colors.blue : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (showAttendance) {
                      setState(() => showAttendance = false);
                      _fetchLeaveData(reset: true);
                    }
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: !showAttendance
                          ? Colors.blue.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Leave',
                      style: TextStyle(
                        color: !showAttendance ? Colors.blue : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (showAttendance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Date filter
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    selectedDateRange == null
                                        ? "Select Date Range"
                                        : "${formatDate(selectedDateRange!.start)} - ${formatDate(selectedDateRange!.end)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedDateRange == null
                                          ? Colors.grey.shade600
                                          : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selectedDateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          onPressed: () {
                            setState(() => selectedDateRange = null);
                            _fetchAttendanceData(reset: true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Attendance Status filter
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus ?? "All",
                          decoration: InputDecoration(
                            labelText: "Status",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                          ),
                          items: ["All", "Present", "Absent", "Half Day", "Pending"]
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value == "All") value = null;
                            _filterByStatus(value);
                          },
                        ),
                      ),
                      if (selectedStatus != null || selectedDateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear),
                            label: const Text("Clear Filters"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            _buildLeaveFilterUI(),

          Expanded(
            child: showAttendance
                ? ListView.builder(
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
                return Column(
                  children: [
                    PunchInCard(
                      item: item,
                      formatDate: formatDateString,
                      formatTime: formatTime,
                      getStatusColor: _getStatusColor,
                    ),
                    PunchOutCard(
                      item: item,
                      formatDate: formatDateString,
                      formatTime: formatTime,
                    ),
                  ],
                );
              },
            )
                : _buildLeaveList(),
          ),
        ],
      ),
    );
  }
}

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  const LeaveCard({super.key, required this.leave});

  String formatDate(String date) =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal());

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type: ${leave['leaveType']?.toString().toUpperCase() ?? 'LEAVE'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("From: ${formatDate(leave['fromDate'])}"),
            Text("To: ${formatDate(leave['toDate'])}"),
            // const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Reason: ${leave['reason'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(leave['status'] ?? ''),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  leave['status'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(leave['status'] ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

class PunchInCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(String) formatDate;
  final String Function(String) formatTime;
  final Color Function(String?) getStatusColor;

  const PunchInCard({
    required this.item,
    required this.formatDate,
    required this.formatTime,
    required this.getStatusColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(item['date']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: item['punchInImage'] != null
                      ? NetworkImage(item['punchInImage'])
                      : const AssetImage("assets/images/placeholder.png")
                  as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Time: ${item['punchIn'] != null ? formatTime(item['punchIn']) : 'N/A'}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(item['punchInCode'] ?? 'N/A'),
                      Text(item['punchInName'] ?? 'N/A'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: getStatusColor(item['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['status'] ?? '',
                      style: TextStyle(
                        color: getStatusColor(item['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PunchOutCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(String) formatDate;
  final String Function(String) formatTime;

  const PunchOutCard({
    required this.item,
    required this.formatDate,
    required this.formatTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(item['date']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: item['punchOutImage'] != null
                      ? NetworkImage(item['punchOutImage'])
                      : const AssetImage("assets/images/placeholder.png")
                  as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Time: ${item['punchOut'] != null ? formatTime(item['punchOut']) : 'N/A'}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(item['punchOutCode'] ?? 'N/A'),
                      Text(item['punchOutName'] ?? 'N/A'),
                      Text("Hours Worked: ${item['hoursWorked'] ?? 'N/A'}"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
