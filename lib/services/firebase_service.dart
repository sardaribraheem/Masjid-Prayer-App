import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/app_data.dart';

/// Service class for all Firebase Firestore operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late FirebaseFirestore _firestore;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  /// Initialize Firebase
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web platform Firebase initialization
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDf62La3ntI8rvL8SQqv7GH69pRqfFU4h8',
          authDomain: 'masjid-prayer-app-49f50.firebaseapp.com',
          projectId: 'masjid-prayer-app-49f50',
          storageBucket: 'masjid-prayer-app-49f50.firebasestorage.app',
          messagingSenderId: '493201204446',
          appId: '1:493201204446:web:811c50faa61c1b51b30e4f',
        ),
      );
    } else {
      // Mobile platforms will use FirebaseOptions from google-services.json / GoogleService-Info.plist
      await Firebase.initializeApp();
    }
    _firestore = FirebaseFirestore.instance;

    // Set Firestore settings for better performance
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Fetch all masjids from Firestore
  Future<List<Masjid>> getAllMasjids() async {
    try {
      final snapshot = await _firestore.collection('masjids').get();
      return snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching masjids: $e');
      return [];
    }
  }

  /// Get a specific masjid by ID
  Future<Masjid?> getMasjidById(String masjidId) async {
    try {
      final doc = await _firestore.collection('masjids').doc(masjidId).get();
      if (doc.exists) {
        return Masjid.fromFirestore(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching masjid: $e');
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
    return _firestore
        .collection('masjids')
        .doc(masjidId)
        .snapshots()
        .map((snapshot) {
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
      final snapshot = await _firestore.collection('masjids').get();
      final masjids = snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList();

      // Import the distance calculation function
      // Calculate distance for each masjid
      for (var masjid in masjids) {
        if (masjid.latitude != null && masjid.longitude != null) {
          masjid.distanceFromUser = _calculateDistance(
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
      print('Error fetching masjids sorted by distance: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  /// Authenticate admin - check username and password
  Future<Masjid?> authenticateAdmin(String username, String password) async {
    try {
      final snapshot = await _firestore
          .collection('masjids')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Masjid.fromFirestore(snapshot.docs[0].data(), snapshot.docs[0].id);
      }
      return null;
    } catch (e) {
      print('Error authenticating admin: $e');
      return null;
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
      print('Error registering masjid: $e');
      return false;
    }
  }

  /// Update prayer times for a masjid
  Future<bool> updatePrayerTimes(
      String masjidId, List<PrayerTime> prayerTimes) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).update({
        'prayerTimes': prayerTimes.map((p) => p.toJson()).toList(),
        'lastUpdated': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error updating prayer times: $e');
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
      print('Error updating Jummah time: $e');
      return false;
    }
  }

  /// Delete a masjid (admin only)
  Future<bool> deleteMasjid(String masjidId) async {
    try {
      await _firestore.collection('masjids').doc(masjidId).delete();
      return true;
    } catch (e) {
      print('Error deleting masjid: $e');
      return false;
    }
  }

  /// Initialize sample data in Firestore (for testing)
  Future<void> initializeSampleData() async {
    try {
      final masjidsRef = _firestore.collection('masjids');

      // Check if data already exists
      final snapshot = await masjidsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Sample data already exists');
        return;
      }

      // Add sample masjids with geographic coordinates
      // Using sample coordinates (e.g., Karachi, Pakistan)
      final sampleMasjids = [
        Masjid(
          name: 'Central Masjid',
          location: 'Downtown',
          username: 'admin1',
          password: 'pass123',
          prayerTimes: [
            PrayerTime(name: 'Fajr', time: '5:30 AM'),
            PrayerTime(name: 'Dhuhr', time: '12:45 PM'),
            PrayerTime(name: 'Asr', time: '3:30 PM'),
            PrayerTime(name: 'Maghrib', time: '6:15 PM'),
            PrayerTime(name: 'Isha', time: '7:45 PM'),
          ],
          jummahTime: '1:00 PM',
          latitude: 24.8607,
          longitude: 67.0011,
        ),
        Masjid(
          name: 'New Mosque',
          location: 'Uptown',
          username: 'admin2',
          password: 'pass456',
          prayerTimes: [
            PrayerTime(name: 'Fajr', time: '5:25 AM'),
            PrayerTime(name: 'Dhuhr', time: '12:50 PM'),
            PrayerTime(name: 'Asr', time: '3:35 PM'),
            PrayerTime(name: 'Maghrib', time: '6:20 PM'),
            PrayerTime(name: 'Isha', time: '7:50 PM'),
          ],
          jummahTime: '1:15 PM',
          latitude: 24.8620,
          longitude: 67.0150,
        ),
        Masjid(
          name: 'Green Valley Mosque',
          location: 'Eastside',
          username: 'admin3',
          password: 'pass789',
          prayerTimes: [
            PrayerTime(name: 'Fajr', time: '5:35 AM'),
            PrayerTime(name: 'Dhuhr', time: '12:40 PM'),
            PrayerTime(name: 'Asr', time: '3:25 PM'),
            PrayerTime(name: 'Maghrib', time: '6:10 PM'),
            PrayerTime(name: 'Isha', time: '7:40 PM'),
          ],
          jummahTime: '12:45 PM',
          latitude: 24.8500,
          longitude: 67.0300,
        ),
      ];

      for (var masjid in sampleMasjids) {
        await masjidsRef.add(masjid.toJson());
      }

      print('Sample data initialized successfully');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
}
