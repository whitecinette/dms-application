import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<dynamic> salaryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSalaries();
  }

  Future<void> fetchSalaries() async {
    try {
      final response = await ApiService.getAllSalaries();
      setState(() {
        salaryData = response['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching salaries: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payroll Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : salaryData.isEmpty
          ? const Center(child: Text('No salary data available.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: salaryData.length,
        itemBuilder: (context, index) {
          final salary = salaryData[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salary['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow('Employee Code', salary['code']),
                  _buildDetailRow('Base Salary', '₹${salary['baseSalary']}'),
                  _buildDetailRow('Net Salary', '₹${salary['netSalary']}'),
                  _buildDetailRow('Absent Days', '${salary['absentDays']}'),
                  _buildDetailRow('Half Days', '${salary['halfDays']}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Calculate Salary logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Calculating salary for ${salary['name']}...',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('Calculate Salary'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
