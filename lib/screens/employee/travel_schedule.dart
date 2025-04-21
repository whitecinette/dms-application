import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelScheduleScreen extends StatefulWidget {
  @override
  _TravelScheduleScreenState createState() => _TravelScheduleScreenState();
}

class _TravelScheduleScreenState extends State<TravelScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  String? fromLocation;
  String? toLocation;
  DateTime? travelDate;
  DateTime? returnDate;
  String? purpose;
  String? transportMode;

  final List<String> transportModes = [
    'Car', 'Bus', 'Train', 'Flight', 'Bike', 'Other',
  ];

  Future<void> _selectDate(BuildContext context, bool isTravelDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isTravelDate ? travelDate ?? DateTime.now() : returnDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        isTravelDate ? travelDate = picked : returnDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    return date == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(date);
  }

  void handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (fromLocation == null || fromLocation!.trim().isEmpty ||
          toLocation == null || toLocation!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter both From and To locations"), backgroundColor: Colors.red),
        );
        return;
      }

      if (travelDate == null || returnDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select both travel and return dates"), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        FocusScope.of(context).unfocus();

        // await ApiService.scheduleTravel(
        //   fromLocation: fromLocation!.trim(),
        //   toLocation: toLocation!.trim(),
        //   travelDate: travelDate!,
        //   returnDate: returnDate!,
        //   transportMode: transportMode,
        //   purpose: purpose,
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Travel Scheduled Successfully ✅")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextInput(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (val) => val!.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isTravelDate) {
    return InkWell(
      onTap: () => _selectDate(context, isTravelDate),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        child: Text(_formatDate(date)),
      ),
    );
  }

  Widget _buildTravelForm() {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _buildSectionTitle("From → To"),
                Row(
                  children: [
                    Expanded(child: _buildTextInput("From", (val) => fromLocation = val)),
                    SizedBox(width: 12),
                    Expanded(child: _buildTextInput("To", (val) => toLocation = val)),
                  ],
                ),
                _buildSectionTitle("Dates"),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker("Travel Date", travelDate, true)),
                    SizedBox(width: 12),
                    Expanded(child: _buildDatePicker("Return Date", returnDate, false)),
                  ],
                ),
                _buildSectionTitle("Mode of Transport"),
                DropdownButtonFormField<String>(
                  value: transportMode,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  hint: Text("Select Mode (Optional)"),
                  items: transportModes.map((mode) {
                    return DropdownMenuItem(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (val) => setState(() => transportMode = val),
                ),
                _buildSectionTitle("Purpose"),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Please enter purpose of travel",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => purpose = val,
                ),
                _buildSectionTitle("Map Preview"),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 180,
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(Icons.map_outlined, size: 60, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: handleSubmit,
              icon: Icon(Icons.send_rounded),
              label: Text("Confirm Travel"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Travel Scheduler"),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Schedule Travel"),
              Tab(text: "My Schedule"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTravelForm(),
            Center(
              child: Text("My Schedule Screen", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
