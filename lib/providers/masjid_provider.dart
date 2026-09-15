import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/distance_utils.dart';

/// Provides masjid list, selected masjid state, and location-aware sorting.
/// Wraps FirebaseService and AppData to provide reactive masjid state.
class MasjidProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();

  List<Masjid> _allMasjids = [];
  Masjid? _selectedMasjid;
  bool _isLoading = false;
  String? _error;
  double? _userLatitude;
  double? _userLongitude;
  String _searchQuery = '';

  List<Masjid> get allMasjids => _allMasjids;
  Masjid? get selectedMasjid => _selectedMasjid;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;

  /// Get filtered masjids based on search query
  List<Masjid> get filteredMasjids {
    if (_searchQuery.isEmpty) return _allMasjids;
    final query = _searchQuery.toLowerCase();
    return _allMasjids
        .where(
          (m) =>
              m.name.toLowerCase().contains(query) ||
              m.location.toLowerCase().contains(query),
        )
        .toList();
  }

  set searchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Load all masjids from Firestore
  Future<void> loadMasjids() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allMasjids = await _firebaseService.getAllMasjids();
      if (_allMasjids.isEmpty) {
        // Fallback to AppData cached masjids
        _allMasjids = List.from(AppData.allMasjids);
      }
      _sortByDistance();
    } catch (e) {
      // Fallback to AppData
      _allMasjids = List.from(AppData.allMasjids);
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch masjids sorted by user location
  Future<void> loadMasjidsWithLocation(double latitude, double longitude) async {
    _userLatitude = latitude;
    _userLongitude = longitude;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allMasjids = await _firebaseService.getMasjidsSortedByDistance(
        latitude,
        longitude,
      );
      if (_allMasjids.isEmpty) {
        _allMasjids = List.from(AppData.allMasjids);
        _sortByDistance();
      }
    } catch (e) {
      _allMasjids = List.from(AppData.allMasjids);
      _sortByDistance();
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a masjid
  Future<void> selectMasjid(Masjid masjid) async {
    _selectedMasjid = masjid;
    AppData.selectedMasjid = masjid;
    AppData.selectedMasjidId = masjid.id;
    await _storageService.saveSelectedMasjidId(masjid.id);
    notifyListeners();
  }

  /// Restore previously selected masjid
  Future<bool> restoreSelection() async {
    final selectedId = _storageService.getSelectedMasjidId();
    if (selectedId == null) return false;

    try {
      final masjid = await _firebaseService.getMasjidById(selectedId);
      if (masjid != null) {
        _selectedMasjid = masjid;
        AppData.selectedMasjid = masjid;
        AppData.selectedMasjidId = masjid.id;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Try local fallback
      for (var m in AppData.allMasjids) {
        if (m.id == selectedId) {
          _selectedMasjid = m;
          AppData.selectedMasjid = m;
          AppData.selectedMasjidId = m.id;
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  /// Sort internal list by distance from user
  void _sortByDistance() {
    if (_userLatitude == null || _userLongitude == null) return;

    for (var masjid in _allMasjids) {
      if (masjid.latitude != null && masjid.longitude != null) {
        masjid.distanceFromUser = DistanceUtils.calculateDistance(
          _userLatitude!,
          _userLongitude!,
          masjid.latitude!,
          masjid.longitude!,
        );
      }
    }

    _allMasjids.sort(
      (a, b) =>
          (a.distanceFromUser ?? double.infinity)
              .compareTo(b.distanceFromUser ?? double.infinity),
    );
  }
}
