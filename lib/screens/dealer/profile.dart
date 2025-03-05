import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';

class ProfileDealerScreen extends StatefulWidget {
  @override
  _ProfileDealerScreenState createState() => _ProfileDealerScreenState();
}

class _ProfileDealerScreenState extends State<ProfileDealerScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await ApiService.getUserDetails();
      setState(() {
        userDetails = response['user'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dealer Profile")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : _buildProfileDetails(),
    );
  }

  Widget _buildProfileDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildEditableField("Status", userDetails?['status']),
          _buildEditableField("Role", userDetails?['role']),
          _buildEditableField("City", userDetails?['city']),
          _buildEditableField("Cluster", userDetails?['cluster']),
          _buildEditableField("Address", userDetails?['address']),
          _buildEditableField("Category", userDetails?['category']),
          _buildEditableField("Shop Anniversary", userDetails?['shop_anniversary']),
          _buildEditableField("Credit Limit", "₹${userDetails?['credit_limit']}"),
          SizedBox(height: 20),
          _buildOwnerDetails(),
          SizedBox(height: 20),
          _buildExpandableSection("Family Information", _buildFamilyDetails()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userDetails?['name'] ?? "Dealer Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Code: ${userDetails?['code'] ?? "N/A"}", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            // Handle edit functionality
          },
        ),
      ],
    );
  }

  Widget _buildOwnerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Owner Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Divider(),
        _buildEditableField("Owner Name", userDetails?['owner_details']['name']),
        _buildEditableField("Phone", userDetails?['owner_details']['phone']),
        _buildEditableField("Email", userDetails?['owner_details']['email']),
        _buildEditableField("Birth Date", userDetails?['owner_details']['birth_date']),
      ],
    );
  }

  Widget _buildFamilyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableField("Father's Name", userDetails?['owner_details']['family_info']['father_name']),
        _buildEditableField("Father's Birthday", userDetails?['owner_details']['family_info']['father_bday']),
        _buildEditableField("Mother's Name", userDetails?['owner_details']['family_info']['mother_name']),
        _buildEditableField("Mother's Birthday", userDetails?['owner_details']['family_info']['mother_bday']),
        _buildEditableField("Spouse Name", userDetails?['owner_details']['family_info']['spouse_name']),
        _buildEditableField("Spouse Birthday", userDetails?['owner_details']['family_info']['spouse_bday']),
        _buildEditableField("Wedding Anniversary", userDetails?['owner_details']['family_info']['wedding_anniversary']),
      ],
    );
  }

  Widget _buildEditableField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value ?? "Not Available",
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        children: [Padding(padding: EdgeInsets.all(16.0), child: content)],
      ),
    );
  }
}
