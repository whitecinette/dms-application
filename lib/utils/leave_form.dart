import 'package:dms_app/services/api_service.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class LeaveForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const LeaveForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _LeaveFormState createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  final _formKey = GlobalKey<FormState>();

  String? leaveType;
  DateTime? fromDate;
  DateTime? toDate;
  String reason = '';
  bool isHalfDay = false;
  String? halfDaySession;
  String? attachmentUrl;
  String? fileName;

  final List<Map<String, String>> leaveTypes = [
    {'label': 'Casual Leave', 'value': 'casual'},
    {'label': 'Sick Leave', 'value': 'sick'},
    {'label': 'Earned Leave', 'value': 'earned'},
    {'label': 'Maternity Leave', 'value': 'maternity'},
    {'label': 'Paternity Leave', 'value': 'paternity'},
    {'label': 'Other', 'value': 'other'},
  ];

  String _formatDate(DateTime dt) {
    return "${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][dt.weekday % 7]}, "
        "${dt.day.toString().padLeft(2, '0')} "
        "${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][dt.month - 1]} "
        "${dt.year}";
  }

  void _resetForm() {
    setState(() {
      leaveType = null;
      fromDate = null;
      toDate = null;
      reason = '';
      isHalfDay = false;
      halfDaySession = null;
      attachmentUrl = null;
      fileName = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _pickFromDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        fromDate = pickedDate;
        if (isHalfDay) toDate = pickedDate;
      });
    }
  }

  Future<void> _pickToDate() async {
    if (isHalfDay) {
      CustomPopup.showPopup(context, "Info", "To Date is same as From Date for Half Day leave.");
      return;
    }

    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: toDate ?? fromDate ?? DateTime.now(),
        firstDate: fromDate ?? DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => toDate = picked);
    } catch (e) {
      CustomPopup.showPopup(context, "Error", "Failed to pick To Date.", isSuccess: false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (fromDate == null || toDate == null) {
      CustomPopup.showPopup(context, "Missing Dates", "Please select both From and To dates.", isSuccess: false);
      return;
    }

    if (fromDate!.isAfter(toDate!)) {
      CustomPopup.showPopup(context, "Invalid Range", "From Date must be before To Date.", isSuccess: false);
      return;
    }

    if (isHalfDay && (halfDaySession == null || halfDaySession!.isEmpty)) {
      CustomPopup.showPopup(context, "Session Required", "Please select a half-day session.", isSuccess: false);
      return;
    }

    _formKey.currentState!.save();

    final formData = {
      'leaveType': leaveType,
      'fromDate': fromDate!.toIso8601String(),
      'toDate': toDate!.toIso8601String(),
      'reason': reason,
      'attachmentUrl': attachmentUrl,
      'isHalfDay': isHalfDay,
      if (isHalfDay) 'halfDaySession': halfDaySession,
    };

    _resetForm();
    final parentContext = context;

    try {
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService.requestLeave(formData);

      Navigator.of(context).pop();

      CustomPopup.showPopup(
        parentContext,
        'Success',
        response['message'] ?? 'Leave request submitted successfully',
        isSuccess: true,
      );

      await Future.delayed(Duration(milliseconds: 1000));
      Navigator.of(context, rootNavigator: true).pop();
      widget.onSubmit(formData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      String errorMsg;

      if (e.toString().contains("SocketException")) {
        errorMsg = "Network error. Please check your connection.";
      } else {
        errorMsg = e.toString();
        if (errorMsg.startsWith("Exception: ")) {
          errorMsg = errorMsg.substring("Exception: ".length);
        }
      }

      CustomPopup.showPopup(
        context,
        'Error',
        errorMsg,
        isSuccess: false,
      );
    }
  }
  int getTotalLeaveDays() {
    if (fromDate == null || toDate == null) return 0;
    return toDate!.difference(fromDate!).inDays + 1;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyleLabel = TextStyle(fontSize: 12, color: Colors.grey[600]);
    final textStyleValue = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final iconSize = 20.0;
    final padding = EdgeInsets.symmetric(horizontal: 14, vertical: 14);
    final radius = BorderRadius.circular(12);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdownField(icon: Icons.grid_view_rounded, label: "Type", value: leaveTypes.firstWhere((e) => e['value'] == leaveType, orElse: () => {'label': 'Select'})['label']!, onTap: () async {
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => ListView(
                    shrinkWrap: true,
                    children: leaveTypes.map((type) => ListTile(
                      title: Text(type['label']!),
                      onTap: () => Navigator.pop(context, type['value']),
                    )).toList(),
                  ),
                );
                if (selected != null) setState(() => leaveType = selected);
              }),
              SizedBox(height: 10),
              TextFormField(
                maxLines: 2,
                decoration: _inputDecoration('Reason'),
                onSaved: (val) => reason = val?.trim() ?? '',
                validator: (val) => val == null || val.trim().isEmpty ? 'Reason is required' : null,
              ),
              SizedBox(height: 10),
              _buildDropdownField(icon: Icons.arrow_forward_ios_rounded, label: "From", value: fromDate != null ? _formatDate(fromDate!) : "Select From Date", onTap: _pickFromDate),
              SizedBox(height: 10),
              _buildDropdownField(icon: Icons.arrow_forward_ios_rounded, label: "To", value: toDate != null ? _formatDate(toDate!) : "Select To Date", onTap: _pickToDate),
              SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Half Day Leave", style: TextStyle(fontSize: 13)),
                value: isHalfDay,
                onChanged: (val) {
                  setState(() {
                    isHalfDay = val ?? false;
                    if (!isHalfDay) halfDaySession = null;
                    if (isHalfDay && fromDate != null) toDate = fromDate;
                  });
                },
              ),
              if (isHalfDay)
                _buildDropdownField(
                  icon: Icons.access_time_rounded,
                  label: "Session",
                  value: halfDaySession != null
                      ? halfDaySession![0].toUpperCase() + halfDaySession!.substring(1)
                      : "Select Session",
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => ListView(
                        shrinkWrap: true,
                        children: ['morning', 'afternoon'].map((session) => ListTile(
                          title: Text(session[0].toUpperCase() + session.substring(1)),
                          onTap: () => Navigator.pop(context, session),
                        )).toList(),
                      ),
                    );
                    if (selected != null) setState(() => halfDaySession = selected);
                  },
                ),

              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    (fromDate != null && toDate != null)
                        ? 'Apply for ${getTotalLeaveDays()} Day${getTotalLeaveDays() > 1 ? 's' : ''} Leave'
                        : 'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
