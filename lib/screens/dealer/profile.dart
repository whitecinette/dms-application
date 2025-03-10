import 'package:dms_app/services/api_service.dart';
import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';

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
      // print("API Response: $response");  // Debugging line
      setState(() {
        userDetails = response['user'];
        // print("User Details After Parsing: $userDetails"); // Debugging line

        if (userDetails == null) {
          errorMessage = "User data is empty!";
        } else {
          // Ensure family_info and children exist
          userDetails!['owner_details'] ??= {};
          userDetails!['owner_details']['family_info'] ??= {};
          userDetails!['owner_details']['family_info']['children'] ??= [];
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching user details: $e";
        isLoading = false;
      });
    }
  }



  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ApiService.editUser(userDetails!);
        CustomPopup.showPopup(context, "Success", "Profile updated successfully!");
      } catch (e) {
        CustomPopup.showPopup(context, "Error", "Failed to update profile: $e");
      } finally {
        setState(() {
          isEditing = false;
        });
      }
    }
  }


  Widget _buildFamilyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableField("Spouse Name", 'owner_details.family_info.spouse_name'),
        _buildEditableField("Spouse Birth Date", 'owner_details.family_info.spouse_bday'),
        _buildEditableField("Father Name", 'owner_details.family_info.father_name'),
        _buildEditableField("Father Birth Date", 'owner_details.family_info.father_bday'),
        _buildEditableField("Mother Name", 'owner_details.family_info.mother_name'),
        _buildEditableField("Mother Birth Date", 'owner_details.family_info.mother_bday'),
        _buildEditableField("Wedding Anniversary", 'owner_details.family_info.wedding_anniversary'),

      ],
    );
  }


  void _addChild() {
    setState(() {
      userDetails!['owner_details'] ??= {};
      userDetails!['owner_details']['family_info'] ??= {};
      userDetails!['owner_details']['family_info']['children'] ??= [];
      userDetails!['owner_details']['family_info']['children'].add({"name": "", "birth_date": ""});
    });
  }


  void _removeChild(int index) {
    setState(() {
      userDetails!['owner_details']?['family_info']['children'].removeAt(index);
    });
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
    if (userDetails == null || userDetails!.isEmpty) {
      return Center(child: Text("No data available"));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            // _buildEditableField("Status", 'status'),
            _buildEditableField("Role", 'role'),
            _buildEditableField("City", 'city'),
            _buildEditableField("Cluster", 'cluster'),
            _buildEditableField("Address", 'address'),
            _buildEditableField("Shop Anniversary", 'shop_anniversary'),
            _buildEditableField("Credit Limit", 'credit_limit'),
            _buildOwnerDetails(),
            _buildExpandableSection("Family Information", _buildFamilyDetails()),
            _buildExpandableSection("Children", _buildChildrenDetails()),
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
    dynamic value = _getNestedFieldValue(userDetails, key) ?? "Not Available";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        readOnly: !isEditing,
        onChanged: (newValue) {
          setState(() {
            _updateNestedField(userDetails!, key, newValue);
          });
        },
      ),
    );
  }

  dynamic _getNestedFieldValue(Map<String, dynamic>? data, String key) {
    List<String> keys = key.split('.');
    dynamic value = data;
    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return null;
      }
    }
    return value;
  }

  void _updateNestedField(Map<String, dynamic> data, String key, dynamic value) {
    List<String> keys = key.split('.');
    Map<String, dynamic> current = data;
    for (int i = 0; i < keys.length - 1; i++) {
      if (current[keys[i]] == null || !(current[keys[i]] is Map<String, dynamic>)) {
        current[keys[i]] = {};
      }
      current = current[keys[i]];
    }
    current[keys.last] = value;
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

  Widget _buildChildrenDetails() {
    List<dynamic>? children = userDetails?['owner_details']?['family_info']?['children'];

    if (children == null || children.isEmpty) {
      return isEditing
          ? Column(
        children: [
          Text("No children data available."),
          ElevatedButton(onPressed: _addChild, child: Text("Add Child")),
        ],
      )
          : Text("No children data available.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(children.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: children[index]['name'] ?? "",
                    decoration: InputDecoration(labelText: "Child Name"),
                    readOnly: !isEditing,
                    onChanged: (value) {
                      if (isEditing) {
                        setState(() {
                          userDetails!['owner_details']['family_info']['children'][index]['name'] = value;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: children[index]['birth_date'] ?? "",
                    decoration: InputDecoration(labelText: "Birth Date"),
                    readOnly: !isEditing,
                    onChanged: (value) {
                      if (isEditing) {
                        setState(() {
                          userDetails!['owner_details']['family_info']['children'][index]['birth_date'] = value;
                        });
                      }
                    },
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeChild(index),
                  ),
              ],
            ),
          );
        }),
        if (isEditing)
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _addChild,
              child: Text("Add Child"),
            ),
          ),
      ],
    );
  }




  Widget _buildExpandableSection(String title, Widget content) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        children: [Padding(padding: EdgeInsets.all(16.0), child: content)],
      ),
    );
  }
}