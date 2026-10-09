import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';

/// Repository for Masjid CRUD and claim request operations in Firestore.
class MasjidRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all masjids
  Future<List<Masjid>> getAllMasjids() async {
    try {
      final snapshot = await _firestore.collection('masjids').get();
      return snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching masjids: $e');
      return [];
    }
  }

  /// Fetch a masjid by ID
  Future<Masjid?> getMasjidById(String masjidId) async {
    try {
      final doc = await _firestore.collection('masjids').doc(masjidId).get();
      if (doc.exists) {
        return Masjid.fromFirestore(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching masjid: $e');
      return null;
    }
  }

  /// Register a new masjid
  Future<bool> registerMasjid(Masjid masjid) async {
    try {
      await _firestore.collection('masjids').add(masjid.toJson());
      return true;
    } catch (e) {
      debugPrint('Error registering masjid: $e');
      return false;
    }
  }

  /// Update a masjid's data
  Future<bool> updateMasjid(String masjidId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating masjid: $e');
      return false;
    }
  }

  /// Assign an imam to a masjid (after claim approval)
  Future<bool> assignImam(String masjidId, String imamUid) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).update({
        'verifiedImamId': imamUid,
        'verificationStatus': 'verified',
      });
      return true;
    } catch (e) {
      debugPrint('Error assigning imam: $e');
      return false;
    }
  }

  /// Submit a claim request for a masjid
  Future<bool> submitClaimRequest({
    required String masjidId,
    required String imamUid,
    required String imamName,
    required String imamEmail,
  }) async {
    try {
      await _firestore.collection('claimRequests').add({
        'masjidId': masjidId,
        'imamUid': imamUid,
        'imamName': imamName,
        'imamEmail': imamEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting claim: $e');
      return false;
    }
  }

  /// Submit a request to register a NEW masjid (not in DB yet)
  Future<bool> submitNewMasjidRequest({
    required String imamUid,
    required String imamName,
    required String imamEmail,
    required String masjidName,
    required String masjidLocation,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _firestore.collection('claimRequests').add({
        'masjidId': null,
        'imamUid': imamUid,
        'imamName': imamName,
        'imamEmail': imamEmail,
        'masjidName': masjidName,
        'masjidLocation': masjidLocation,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'pending',
        'type': 'new_masjid',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting new masjid request: $e');
      return false;
    }
  }

  /// Get all pending claim requests for super admin
  Future<List<ClaimRequest>> getClaimRequests() async {
    try {
      final snapshot = await _firestore
          .collection('claimRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ClaimRequest.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching claim requests: $e');
      rethrow;
    }
  }

  /// Atomically review a pending request and assign its applicant.
  Future<bool> approveClaim(String requestId) async {
    try {
      final reviewer = FirebaseAuth.instance.currentUser;
      if (reviewer == null) return false;
      await _firestore.runTransaction((transaction) async {
        final claimRef = _firestore.collection('claimRequests').doc(requestId);
        final claim = await transaction.get(claimRef);
        if (!claim.exists || claim.data()?['status'] != 'pending') {
          throw StateError('This request has already been reviewed.');
        }
        final request = ClaimRequest.fromJson(claim.data()!, claim.id);
        final userRef = _firestore.collection('users').doc(request.imamUid);
        final user = await transaction.get(userRef);
        if (!user.exists) {
          throw StateError('Applicant account no longer exists.');
        }
        final masjidRef = _firestore
            .collection('masjids')
            .doc(request.masjidId ?? requestId);
        final masjidDoc = await transaction.get(masjidRef);
        final applicantData = user.data()!;
        if (applicantData['deletionRequestedAt'] != null) {
          throw StateError('Applicant account is being deleted.');
        }
        if (applicantData['role'] == 'imam' ||
            applicantData['role'] == 'admin') {
          if (applicantData['masjidId'] != masjidRef.id) {
            throw StateError('Transfer the existing manager assignment first.');
          }
        }
        String masjidName;
        if (request.isNewMasjidRequest) {
          if (masjidDoc.exists ||
              request.masjidName == null ||
              request.masjidLocation == null) {
            throw StateError('New masjid request is invalid.');
          }
          masjidName = request.masjidName!;
          transaction.set(
            masjidRef,
            Masjid(
              name: masjidName,
              location: request.masjidLocation!,
              username: request.imamEmail,
              creatorUid: request.imamUid,
              authorizedImamUids: [request.imamUid],
              isVerified: true,
              latitude: request.latitude,
              longitude: request.longitude,
              prayerTimes: [
                'Fajr',
                'Dhuhr',
                'Asr',
                'Maghrib',
                'Isha',
              ].map((name) => PrayerTime(name: name, time: '')).toList(),
            ).toJson(),
          );
        } else {
          if (!masjidDoc.exists) throw StateError('Masjid no longer exists.');
          masjidName = masjidDoc.data()!['name'] as String;
          transaction.update(masjidRef, {
            'authorizedImamUids': FieldValue.arrayUnion([request.imamUid]),
            'isVerified': true,
          });
        }
        transaction.update(userRef, {
          'role': UserRole.imam.value,
          'verificationStatus': VerificationStatus.approved.value,
          'eventPermission': EventPermission.full.value,
          'masjidId': masjidRef.id,
          'masjidName': masjidName,
        });
        transaction.update(claimRef, {
          'status': 'approved',
          'approvedMasjidId': masjidRef.id,
          'reviewedByUid': reviewer.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error approving claim: $e');
      return false;
    }
  }

  Future<bool> rejectClaim(String requestId) async {
    try {
      final reviewer = FirebaseAuth.instance.currentUser;
      if (reviewer == null) return false;
      await _firestore.collection('claimRequests').doc(requestId).update({
        'status': 'rejected',
        'reviewedByUid': reviewer.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting claim: $e');
      return false;
    }
  }
}

/// Claim request model
class ClaimRequest {
  final String id;
  final String? masjidId;
  final String imamUid;
  final String imamName;
  final String imamEmail;
  final String status; // pending, approved, rejected
  final String? masjidName;
  final String? masjidLocation;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  ClaimRequest({
    required this.id,
    this.masjidId,
    required this.imamUid,
    required this.imamName,
    required this.imamEmail,
    required this.status,
    this.masjidName,
    this.masjidLocation,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  bool get isNewMasjidRequest => masjidId == null;

  factory ClaimRequest.fromJson(Map<String, dynamic> json, String docId) {
    return ClaimRequest(
      id: docId,
      masjidId: json['masjidId'] as String?,
      imamUid: json['imamUid'] as String? ?? '',
      imamName: json['imamName'] as String? ?? '',
      imamEmail: json['imamEmail'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      masjidName: json['masjidName'] as String?,
      masjidLocation: json['masjidLocation'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
