import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Providers
final coordinatesProvider = StateProvider<String>((ref) => "location");
final addressProvider = StateProvider<String>((ref) => "Fetching address...");
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
      "${position.latitude}, ${position.longitude}";

      // Fetch address based on coordinates
      await getAddress(position.latitude, position.longitude);

    } catch (e) {
      ref.read(coordinatesProvider.notifier).state = "Error: $e";
      ref.read(addressProvider.notifier).state = "Error fetching address";
      log("Location error: $e");
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.name}, ${place.locality}, ${place.subAdministrativeArea}";
        ref.read(addressProvider.notifier).state = address;
      } else {
        ref.read(addressProvider.notifier).state = "Location not found";
      }
    } catch (e) {
      ref.read(addressProvider.notifier).state = "Error fetching address";
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

