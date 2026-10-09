import 'package:flutter/material.dart';
import '../repositories/masjid_repository.dart';
import '../models/app_data.dart';

/// Provider for masjid claim workflow state.
/// Handles claim requests, new masjid registration requests.
class MasjidClaimProvider extends ChangeNotifier {
  final MasjidRepository _repository = MasjidRepository();

  List<ClaimRequest> _pendingRequests = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<ClaimRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Load pending claim requests (super admin only)
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingRequests = await _repository.getClaimRequests();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submit claim for an existing masjid
  Future<bool> claimMasjid({
    required String masjidId,
    required String imamUid,
    required String imamName,
    required String imamEmail,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _repository.submitClaimRequest(
        masjidId: masjidId,
        imamUid: imamUid,
        imamName: imamName,
        imamEmail: imamEmail,
      );

      if (success) {
        _successMessage = 'Claim request submitted successfully';
      } else {
        _error = 'Failed to submit claim request';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit request to register a new masjid
  Future<bool> registerNewMasjid({
    required String imamUid,
    required String imamName,
    required String imamEmail,
    required String masjidName,
    required String masjidLocation,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _repository.submitNewMasjidRequest(
        imamUid: imamUid,
        imamName: imamName,
        imamEmail: imamEmail,
        masjidName: masjidName,
        masjidLocation: masjidLocation,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        _successMessage = 'Masjid registration request submitted';
      } else {
        _error = 'Failed to submit registration request';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Approve a claim request (super admin)
  Future<bool> approveRequest(String requestId) async {
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();
    final success = await _repository.approveClaim(requestId);
    if (success) _pendingRequests.removeWhere((r) => r.id == requestId);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> rejectRequest(String requestId) async {
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();
    final success = await _repository.rejectClaim(requestId);
    if (success) _pendingRequests.removeWhere((r) => r.id == requestId);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Get filtered masjids matching a search query (for claim flow)
  List<Masjid> searchMasjids(List<Masjid> allMasjids, String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allMasjids
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.location.toLowerCase().contains(q),
        )
        .toList();
  }
}
