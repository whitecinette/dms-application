import 'package:dms_app/utils/custom_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dms_app/services/api_service.dart';

class BeatMappingScreen extends StatefulWidget {
  @override
  _BeatMappingScreenState createState() => _BeatMappingScreenState();
}

class _BeatMappingScreenState extends State<BeatMappingScreen> {
  Map<String, dynamic> scheduleData = {};
  List<dynamic> filteredDealers = [];
  List<dynamic> allDealers = [];
  bool isLoading = true;
  String selectedDay = "Mon";
  String searchQuery = "";
  final List<String> weekdays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun"
  ];

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  String getFormattedDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchSchedules() async {
    try {
      String startDate = getFormattedDate(
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
      String endDate = getFormattedDate(
          DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)));

      final response =
          await ApiService.getWeeklyBeatMappingSchedule(startDate, endDate);
      setState(() {
        if (response['data'] != null && response['data'].isNotEmpty) {
          scheduleData = response['data'][0]['schedule'];

          // Assign scheduleId to each dealer in scheduleData
          String scheduleId = response['data'][0]['_id']; // Extract schedule ID
          scheduleData.forEach((day, dealers) {
            for (var dealer in dealers) {
              dealer['scheduleId'] =
                  scheduleId; // Assign scheduleId to each dealer
            }
          });

          selectedDay = weekdays.firstWhere(
              (day) => scheduleData.containsKey(day),
              orElse: () => "Mon");
          allDealers = scheduleData[selectedDay] ?? [];
          filteredDealers = List.from(allDealers);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching schedules: $e");
    }
  }

  void updateSelectedDay(String day) {
    setState(() {
      selectedDay = day;
      allDealers = scheduleData[day] ?? [];
      filterDealers();
    });
  }

  void filterDealers() {
    setState(() {
      filteredDealers = allDealers.where((dealer) {
        return dealer['name'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _markDoneWithLocation(Map<String, dynamic>? dealer) async {
    // Check if dealer data exists
    if (dealer == null) {
      CustomPopup.showPopup(
          context, "Error", "No dealer data available for today.",
          isSuccess: false);

      return;
    }

    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        CustomPopup.showPopup(
            context, "Permission Denied", "Location permission is required.",
            isSuccess: false);

        return;
      }

      // Get current employee location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double employeeLat = position.latitude;
      double employeeLong = position.longitude;

      // Extract latitude and longitude from dealer object
      double? dealerLat;
      double? dealerLong;

      try {
        if (dealer['latitude'] != null) {
          dealerLat = (dealer['latitude'] is num)
              ? (dealer['latitude'] as num).toDouble()
              : (dealer['latitude'] is Map<String, dynamic> &&
                      dealer['latitude']['\$numberDecimal'] != null)
                  ? double.tryParse(
                      dealer['latitude']['\$numberDecimal'].toString())
                  : double.tryParse(dealer['latitude'].toString());
        }

        if (dealer['longitude'] != null) {
          dealerLong = (dealer['longitude'] is num)
              ? (dealer['longitude'] as num).toDouble()
              : (dealer['longitude'] is Map<String, dynamic> &&
                      dealer['longitude']['\$numberDecimal'] != null)
                  ? double.tryParse(
                      dealer['longitude']['\$numberDecimal'].toString())
                  : double.tryParse(dealer['longitude'].toString());
        }

        if (dealerLat == null || dealerLong == null) {
          throw FormatException("Dealer location data is missing or invalid");
        }
      } catch (error) {
        print("Error converting latitude/longitude: $error");
        CustomPopup.showPopup(context, "Invalid Data",
            "Dealer location data is missing or incorrect.",
            isSuccess: false);

        return;
      }

      // Calculate distance
      double distance = Geolocator.distanceBetween(
          employeeLat, employeeLong, dealerLat, dealerLong);

      if (distance <= 100) {
        // Check if within 100 meters

        if (dealer['scheduleId'] == null || dealer['code'] == null) {
          print("Error: scheduleId or code is null.");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text("Error: Required data missing (scheduleId or code).")));
          return;
        }

        await ApiService.updateWeeklyBeatMappingStatusWithProximity(
            dealer['scheduleId'],
            dealer['code'],
            'done',
            employeeLat,
            employeeLong);

        setState(() {
          dealer['status'] = 'done';
        });

        CustomPopup.showPopup(
            context, "Success", "Dealer marked as done successfully!");
      } else {
        CustomPopup.showPopup(
            context, "Too Far", "You are too far from the dealer location.",
            isSuccess: false);
      }
    } catch (e) {
      CustomPopup.showPopup(context, "Error", "An error occurred: $e",
          isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Beat Mapping")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) {
                return GestureDetector(
                  onTap: () => updateSelectedDay(day),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          selectedDay == day ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: selectedDay == day ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "Search Dealers...",
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterDealers();
                });
              },
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredDealers.isEmpty
                      ? Center(
                          child: Text("No dealers found for $selectedDay."))
                      : ListView.builder(
                          itemCount: filteredDealers.length,
                          itemBuilder: (context, index) {
                            final dealer = filteredDealers[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: dealer['status'] == 'done'
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    dealer['status'] == 'done'
                                        ? Icons.check
                                        : Icons.pending,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                    "${dealer['name'] ?? "Unknown Dealer"}"),
                                subtitle: Text("Code: ${dealer['code']}"),
                                trailing: dealer['status'] == 'pending'
                                    ? ElevatedButton(
                                        onPressed: () =>
                                            _markDoneWithLocation(dealer),
                                        child: Text("Mark Done"),
                                      )
                                    : Text(
                                        dealer['status'].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
