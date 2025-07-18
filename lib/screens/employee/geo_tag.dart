import 'dart:io';
import 'dart:async';
import 'package:siddhaconnect/services/api_service.dart';
import 'package:siddhaconnect/services/location_service.dart';
import 'package:siddhaconnect/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class GeoTagScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<GeoTagScreen> createState() => _GeoTagScreenState();
}

class _GeoTagScreenState extends ConsumerState<GeoTagScreen> {
  List<Map<String, dynamic>> dealers = [];
  List<Map<String, dynamic>> filteredDealers = [];
  String? selectedDealer;
  File? _image;
  bool _isSubmitting = false;
  bool _isLoadingDealers = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        LocationService(ref).getLocation(),
        fetchDealers(),
      ]);
    });
    _searchController.addListener(_filterDealers);
  }

  void _filterDealers() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredDealers = dealers.where((dealer) {
          final name = dealer['name'].toString().toLowerCase();
          final code = dealer['code'].toString().toLowerCase();
          return name.contains(query) || code.contains(query);
        }).toList();
      });
    });
  }

  Future<void> fetchDealers() async {
    setState(() => _isLoadingDealers = true);
    try {
      final fetchedDealers = await ApiService.getDealersByEmployee();
      setState(() {
        dealers = fetchedDealers;
        filteredDealers = dealers;
      });
    } catch (error) {
      CustomPopup.showPopup(context, "Error", "Error fetching dealers: ${error.toString()}", isSuccess: false);
    } finally {
      setState(() => _isLoadingDealers = false);
    }
  }

  Future<void> _updateGeoTag() async {
    if (selectedDealer == null || _image == null) {
      CustomPopup.showPopup(context, "Error", "Please select a dealer and capture an image.", isSuccess: false);
      return;
    }

    final coordinates = ref.read(coordinatesProvider).split(", ");
    if (coordinates.length != 2) {
      CustomPopup.showPopup(context, "Error", "Location not available. Please try again.", isSuccess: false);
      return;
    }

    final latitude = double.tryParse(coordinates[0]);
    final longitude = double.tryParse(coordinates[1]);

    if (latitude == null || longitude == null) {
      CustomPopup.showPopup(context, "Error", "Invalid location data. Please try again.", isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.updateGeotag(
        code: selectedDealer!,
        latitude: latitude,
        longitude: longitude,
        imageFile: _image!,
      );

      CustomPopup.showPopup(context, "Success", "✅ Geotag updated successfully!");

      setState(() {
        _isSubmitting = false;
        _image = null;
        selectedDealer = null;
      });
    } catch (error) {
      setState(() => _isSubmitting = false);
      CustomPopup.showPopup(context, "Error", "❌ Error updating geotag: ${error.toString()}", isSuccess: false);
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _image = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final address = ref.watch(addressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("GeoTag Screen")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: "Search or Select Dealer",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),

            if (filteredDealers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredDealers.length,
                    itemBuilder: (context, index) {
                      final dealer = filteredDealers[index];
                      return ListTile(
                        title: Text(dealer['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Code: ${dealer['code']}"),
                            Text(
                              "${dealer['status'] ?? 'PENDING'}",
                              style: TextStyle(
                                color: dealer['status'] == 'DONE' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedDealer = dealer['code'];
                            _searchController.text = dealer['name'];
                            filteredDealers = [];
                          });

                          _searchFocusNode.unfocus();
                        },
                      );

                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ref.watch(addressProvider),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )

                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () async {
                      await LocationService(ref).getLocation();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_image != null)
              Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(_image!, height: 200),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : (_image == null ? _pickImage : _updateGeoTag),
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Icon(
                    _image == null ? Icons.camera_alt : Icons.check_circle),
                label: Text(_image == null ? "Click Picture" : "Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
