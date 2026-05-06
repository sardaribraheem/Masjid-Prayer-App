import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Service for handling location permissions and fetching user location
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Request location permission from user
  /// Returns true if permission is granted
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        // User has permanently denied permission, open app settings
        await Geolocator.openLocationSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  /// Returns Position with latitude and longitude
  Future<Position?> getUserLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Request permission if not already granted
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Get the distance between two locations using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c;

    return distance;
  }

  static double _toRad(double degree) {
    return degree * (math.pi / 180);
  }
}
