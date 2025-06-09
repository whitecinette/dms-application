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
  void _resetForm() {
    setState(() {
      leaveType = null;
      fromDate = null;
      toDate = null;
      reason = '';
      isHalfDay = false;
      attachmentUrl = null;
      fileName = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _pickFromDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: fromDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => fromDate = picked);
    } catch (e) {
      CustomPopup.showPopup(context, "Error", "Failed to pick From Date.", isSuccess: false);
    }
  }

  Future<void> _pickToDate() async {
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

    _formKey.currentState!.save();

    final formData = {
      'leaveType': leaveType,
      'fromDate': fromDate!.toIso8601String(),
      'toDate': toDate!.toIso8601String(),
      'reason': reason,
      'attachmentUrl': attachmentUrl,
      'isHalfDay': isHalfDay,
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

      Navigator.of(context).pop(); // Close loading spinner

      CustomPopup.showPopup(
        parentContext,
        'Success',
        response['message'] ?? 'Leave request submitted successfully',
        isSuccess: true,
      );

      await Future.delayed(Duration(milliseconds: 700));
      Navigator.of(parentContext).pop(); // Close LeaveForm dialog

      widget.onSubmit(formData);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop(); // Close loading spinner if open

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Leave Type'),
                isExpanded: true,
                value: leaveType,
                items: leaveTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => leaveType = val),
                validator: (val) => val == null || val.isEmpty ? 'Please select leave type' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                decoration: _inputDecoration('From Date').copyWith(
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: fromDate == null ? '' : "${fromDate!.day}/${fromDate!.month}/${fromDate!.year}",
                ),
                onTap: _pickFromDate,
              ),
              SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                decoration: _inputDecoration('To Date').copyWith(
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: toDate == null ? '' : "${toDate!.day}/${toDate!.month}/${toDate!.year}",
                ),
                onTap: _pickToDate,
              ),
              SizedBox(height: 16),

              TextFormField(
                maxLines: 3,
                decoration: _inputDecoration('Reason'),
                onSaved: (val) => reason = val?.trim() ?? '',
                validator: (val) => val == null || val.trim().isEmpty ? 'Reason is required' : null,
              ),
              SizedBox(height: 16),
              //
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: OutlinedButton.icon(
              //     icon: Icon(Icons.attach_file, size: 20),
              //     label: Text(
              //       fileName != null ? fileName! : 'Add Attachment (Optional)',
              //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              //     ),
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: Colors.black87,
              //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              //       side: BorderSide(color: Colors.grey.shade400),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //     ),
              //     onPressed: () async {
              //       try {
              //         FilePickerResult? result = await FilePicker.platform.pickFiles(
              //           allowMultiple: false,
              //           type: FileType.custom,
              //           allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'doc', 'docx'],
              //         );
              //         if (result != null && result.files.single.path != null) {
              //           setState(() {
              //             attachmentUrl = result.files.single.path!;
              //             fileName = path.basename(attachmentUrl!);
              //           });
              //         } else {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             SnackBar(content: Text('No file selected')),
              //           );
              //         }
              //       } catch (e) {
              //         CustomPopup.showPopup(context, 'Error', 'File selection failed: ${e.toString()}', isSuccess: false);
              //       }
              //     },
              //   ),
              // ),
              // SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
