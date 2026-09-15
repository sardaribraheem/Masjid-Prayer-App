import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Provides location state with loading/error handling.
/// Wraps LocationService in a reactive ChangeNotifier.
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _position;
  bool _isLoading = false;
  bool _permissionGranted = false;
  String? _error;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;
  String? get error => _error;
  double? get latitude => _position?.latitude;
  double? get longitude => _position?.longitude;

  /// Request location permission and get current location
  Future<bool> requestLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        _permissionGranted = false;
        _error = 'Location permission denied';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _permissionGranted = true;
      final position = await _locationService.getUserLocation();
      if (position != null) {
        _position = position;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Unable to get location';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if location permission is already granted
  Future<bool> checkPermission() async {
    final granted = await _locationService.isLocationPermissionGranted();
    _permissionGranted = granted;
    notifyListeners();
    return granted;
  }

  /// Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
