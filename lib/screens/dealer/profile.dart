import 'package:dms_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileDealerScreen extends StatefulWidget {
  @override
  _ProfileDealerScreenState createState() => _ProfileDealerScreenState();
}

class _ProfileDealerScreenState extends State<ProfileDealerScreen> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  String errorMessage = "";
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;

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

  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await ApiService.editUser(userDetails!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e"), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dealer Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveUserDetails();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildEditableField("Status", 'status'),
            _buildEditableField("Role", 'role'),
            _buildEditableField("City", 'city'),
            _buildEditableField("Cluster", 'cluster'),
            _buildEditableField("Address", 'address'),
            _buildEditableField("Category", 'category'),
            _buildEditableField("Shop Anniversary", 'shop_anniversary'),
            _buildEditableField("Credit Limit", 'credit_limit'),
            SizedBox(height: 20),
            _buildOwnerDetails(),
            SizedBox(height: 20),
            _buildExpandableSection("Family Information", _buildFamilyDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(userDetails?['name'] ?? "Dealer Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Code: ${userDetails?['code'] ?? "N/A"}", style: TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEditableField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: userDetails?[key]?.toString() ?? "Not Available",
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              readOnly: !isEditing,
              onChanged: (value) => userDetails?[key] = value,
            ),
          ),
          if (isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Owner Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Divider(),
        _buildEditableField("Owner Name", 'owner_details.name'),
        _buildEditableField("Phone", 'owner_details.phone'),
        _buildEditableField("Email", 'owner_details.email'),
        _buildEditableField("Birth Date", 'owner_details.birth_date'),
      ],
    );
  }

  Widget _buildFamilyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableField("Father's Name", 'owner_details.family_info.father_name'),
        _buildEditableField("Father's Birthday", 'owner_details.family_info.father_bday'),
        _buildEditableField("Mother's Name", 'owner_details.family_info.mother_name'),
        _buildEditableField("Mother's Birthday", 'owner_details.family_info.mother_bday'),
        _buildEditableField("Spouse Name", 'owner_details.family_info.spouse_name'),
        _buildEditableField("Spouse Birthday", 'owner_details.family_info.spouse_bday'),
        _buildEditableField("Wedding Anniversary", 'owner_details.family_info.wedding_anniversary'),
      ],
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
