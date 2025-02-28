import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Providers
final coordinatesProvider = StateProvider<String>((ref) => "Fetching location...");
final isLoadingProvider = StateProvider<bool>((ref) => false);

class LocationService {
  final WidgetRef ref;
  LocationService(this.ref);

  Future<void> getLocation() async {
    ref.read(isLoadingProvider.notifier).state = true;
    try {
      Position position = await _determinePosition();
      log("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      // Update Riverpod state
      ref.read(coordinatesProvider.notifier).state =
      "Lat: ${position.latitude}, Long: ${position.longitude}";
    } catch (e) {
      ref.read(coordinatesProvider.notifier).state = "Error: $e";
      log("Location error: $e");
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions denied");
      }
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
