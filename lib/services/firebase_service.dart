import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/app_data.dart';
import '../utils/distance_utils.dart';

/// Service class for all Firebase Firestore operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late FirebaseFirestore _firestore;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  /// Initialize Firebase from native Android configuration, web options, or
  /// explicit debug-only local emulator options. Other native launch targets
  /// require their own reviewed project configuration.
  Future<void> initialize() async {
    if (kReleaseMode && const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      throw StateError('Emulator mode is unavailable in release builds.');
    }
    // On Android, google-services.json auto-initializes Firebase via the
    // native GoogleServices plugin before Dart runs, so Firebase.apps
    // may appear empty while the native default app already exists.
    // A second call to initializeApp then throws [core/duplicate-app].
    // We guard with a try-catch so the app works regardless.
    try {
      await Firebase.initializeApp(
        options: const bool.fromEnvironment('USE_FIREBASE_EMULATORS')
            ? const FirebaseOptions(
                apiKey: 'demo-api-key',
                appId: '1:123:web:demo',
                messagingSenderId: '123',
                projectId: 'demo-masjid-rules',
              )
            : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? null
            : DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) rethrow;
      // Firebase already initialized — safe to continue.
    }
    _firestore = FirebaseFirestore.instance;

    if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      if (kReleaseMode) {
        throw StateError('Emulator mode is unavailable in release builds.');
      }
      _firestore.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      _firestore.settings = const Settings(persistenceEnabled: false);
      return;
    }
    // Set Firestore settings for better performance
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 40 * 1024 * 1024,
    );
  }

  /// Fetch all masjids from Firestore
  Future<List<Masjid>> getAllMasjids() async {
    try {
      final snapshot = await _firestore
          .collection('masjids')
          .get()
          .timeout(const Duration(seconds: 15));
      return snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching masjids: $e');
      rethrow;
    }
  }

  /// Get a specific masjid by ID
  Future<Masjid?> getMasjidById(String masjidId) async {
    try {
      final doc = await _firestore
          .collection('masjids')
          .doc(masjidId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return Masjid.fromFirestore(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching masjid: $e');
      return null;
    }
  }

  /// Stream of all masjids for real-time updates
  Stream<List<Masjid>> getMasjidsStream() {
    return _firestore.collection('masjids').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of a specific masjid for real-time prayer time updates
  Stream<Masjid?> getMasjidStream(String masjidId) {
    return _firestore.collection('masjids').doc(masjidId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return Masjid.fromFirestore(snapshot.data() ?? {}, snapshot.id);
      }
      return null;
    });
  }

  /// Get all masjids sorted by distance from user's location
  /// userLat and userLon are the user's coordinates
  Future<List<Masjid>> getMasjidsSortedByDistance(
    double userLat,
    double userLon,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('masjids')
          .get()
          .timeout(const Duration(seconds: 15));
      final masjids = snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();

      // Import the distance calculation function
      // Calculate distance for each masjid
      for (var masjid in masjids) {
        if (masjid.latitude != null && masjid.longitude != null) {
          masjid.distanceFromUser = DistanceUtils.calculateDistance(
            userLat,
            userLon,
            masjid.latitude!,
            masjid.longitude!,
          );
        }
      }

      // Sort by distance (closest first)
      masjids.sort((a, b) {
        final distA = a.distanceFromUser ?? double.infinity;
        final distB = b.distanceFromUser ?? double.infinity;
        return distA.compareTo(distB);
      });

      return masjids;
    } catch (e) {
      debugPrint('Error fetching masjids sorted by distance: $e');
      return [];
    }
  }

  /// Register a new masjid
  Future<bool> registerMasjid(Masjid masjid) async {
    try {
      // Check if username already exists
      final existing = await _firestore
          .collection('masjids')
          .where('username', isEqualTo: masjid.username)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Username already exists');
      }

      // Add new masjid to Firestore
      await _firestore.collection('masjids').add(masjid.toJson());
      return true;
    } catch (e) {
      debugPrint('Error registering masjid: $e');
      return false;
    }
  }

  /// Update prayer times for a masjid
  Future<bool> updatePrayerTimes(
    String masjidId,
    List<PrayerTime> prayerTimes,
  ) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).update({
        'prayerTimes': prayerTimes.map((p) => p.toJson()).toList(),
        'lastUpdated': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating prayer times: $e');
      return false;
    }
  }

  /// Update Jummah time for a masjid
  Future<bool> updateJummahTime(String masjidId, String jummahTime) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).update({
        'jummah': jummahTime,
        'lastUpdated': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating Jummah time: $e');
      return false;
    }
  }

  /// Delete a masjid (admin only)
  Future<bool> deleteMasjid(String masjidId) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting masjid: $e');
      return false;
    }
  }
}
