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
  final List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

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
      String startDate = getFormattedDate(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
      String endDate = getFormattedDate(DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)));

      final response = await ApiService.getWeeklyBeatMappingSchedule(startDate, endDate);
      setState(() {
        scheduleData = response['data'] != null && response['data'].isNotEmpty ? response['data'][0]['schedule'] : {};
        selectedDay = weekdays.firstWhere((day) => scheduleData.containsKey(day), orElse: () => "Mon");
        allDealers = scheduleData[selectedDay] ?? [];
        filteredDealers = List.from(allDealers);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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

  Future<void> _markDoneWithLocation(Map<String, dynamic> dealer) async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied")));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double employeeLat = position.latitude;
      double employeeLong = position.longitude;

      double dealerLat = dealer['latitude'];
      double dealerLong = dealer['longitude'];
      double distance = Geolocator.distanceBetween(employeeLat, employeeLong, dealerLat, dealerLong);

      if (distance <= 100) { // Check if within 100 meters
        await ApiService.updateWeeklyBeatMappingStatusWithProximity(
            dealer['scheduleId'], dealer['code'], 'done', employeeLat, employeeLong
        );
        setState(() {
          dealer['status'] = 'done';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dealer marked as done!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You are too far from the dealer location")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
                      color: selectedDay == day ? Colors.blue : Colors.grey[300],
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  ? Center(child: Text("No dealers found for $selectedDay."))
                  : ListView.builder(
                itemCount: filteredDealers.length,
                itemBuilder: (context, index) {
                  final dealer = filteredDealers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: dealer['status'] == 'done' ? Colors.green : Colors.orange,
                        child: Icon(
                          dealer['status'] == 'done' ? Icons.check : Icons.pending,
                          color: Colors.white,
                        ),
                      ),
                      title: Text("${dealer['name'] ?? "Unknown Dealer"}"),
                      subtitle: Text("Code: ${dealer['code']}"),
                      trailing: dealer['status'] == 'pending'
                          ? ElevatedButton(
                        onPressed: () => _markDoneWithLocation(dealer),
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
