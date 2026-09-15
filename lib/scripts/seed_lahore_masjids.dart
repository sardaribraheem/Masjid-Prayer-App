/// Standalone seed script for populating Lahore masjid data.
///
/// This is NOT part of the app — it's a one-time script to seed the Firestore
/// database with masjid existence data (name, area, city, coordinates).
/// Prayer times are intentionally left BLANK — the masjid's Imam enters them
/// after claiming their masjid through the verification workflow.
///
/// How to run:
///   1. Build the script: `dart compile kernel lib/scripts/seed_lahore_masjids.dart`
///   2. Or import into main.dart temporarily and call seedLahoreMasjids()
///
/// Data source: Google Maps Places API for "mosques in Lahore, Pakistan"
///
/// Known areas in Lahore with masjids:
/// - Model Town, Gulberg, Johar Town, Defence, DHA, Cantt
/// - Iqbal Town, Garden Town, Township, Bahria Town
/// - Wapda Town, Samanabad, Mughalpura, Ichhra
/// - Anarkali, Shahdara, Mozang, Kaiser Town

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_data.dart';

/// List of known Lahore masjids (representative sample).
/// In production, replace with results from Google Maps Places API.
const List<Map<String, dynamic>> _lahoreMasjids = [
  {
    'name': 'Masjid-e-Khizra',
    'location': 'Model Town, Lahore',
    'username': '',
    'latitude': 31.4898,
    'longitude': 74.3296,
  },
  {
    'name': 'Badshahi Masjid',
    'location': 'Walled City, Lahore',
    'username': '',
    'latitude': 31.5882,
    'longitude': 74.3100,
  },
  {
    'name': 'Masjid-e-Aisha',
    'location': 'Gulberg, Lahore',
    'username': '',
    'latitude': 31.5188,
    'longitude': 74.3567,
  },
  {
    'name': 'Jamia Masjid Gulshan-e-Iqbal',
    'location': 'Johar Town, Lahore',
    'username': '',
    'latitude': 31.3950,
    'longitude': 74.2792,
  },
  {
    'name': 'Jamia Masjid DHA Phase 5',
    'location': 'DHA Phase 5, Lahore',
    'username': '',
    'latitude': 31.4672,
    'longitude': 74.4053,
  },
  {
    'name': 'Data Darbar Mosque',
    'location': 'Bhati Gate, Lahore',
    'username': '',
    'latitude': 31.5752,
    'longitude': 74.3150,
  },
  {
    'name': 'Jamia Masjid Iqbal Town',
    'location': 'Iqbal Town, Lahore',
    'username': '',
    'latitude': 31.5142,
    'longitude': 74.2722,
  },
  {
    'name': 'Jamia Masjid Garden Town',
    'location': 'Garden Town, Lahore',
    'username': '',
    'latitude': 31.4930,
    'longitude': 74.3269,
  },
  {
    'name': 'Jamia Masjid Township',
    'location': 'Township, Lahore',
    'username': '',
    'latitude': 31.4440,
    'longitude': 74.3150,
  },
  {
    'name': 'Jamia Masjid Bahria Town',
    'location': 'Bahria Town, Lahore',
    'username': '',
    'latitude': 31.3590,
    'longitude': 74.2130,
  },
  {
    'name': 'Jamia Masjid Wapda Town',
    'location': 'Wapda Town, Lahore',
    'username': '',
    'latitude': 31.4190,
    'longitude': 74.3060,
  },
  {
    'name': 'Mohammadi Masjid',
    'location': 'Ichhra, Lahore',
    'username': '',
    'latitude': 31.5300,
    'longitude': 74.3270,
  },
  {
    'name': 'Jamia Masjid Samanabad',
    'location': 'Samanabad, Lahore',
    'username': '',
    'latitude': 31.5250,
    'longitude': 74.3030,
  },
  {
    'name': 'Jamia Masjid Mughalpura',
    'location': 'Mughalpura, Lahore',
    'username': '',
    'latitude': 31.5550,
    'longitude': 74.3550,
  },
  {
    'name': 'Jamia Masjid Shahdara',
    'location': 'Shahdara, Lahore',
    'username': '',
    'latitude': 31.6150,
    'longitude': 74.2890,
  },
  {
    'name': 'Jamia Masjid Anarkali',
    'location': 'Anarkali, Lahore',
    'username': '',
    'latitude': 31.5600,
    'longitude': 74.3100,
  },
  {
    'name': 'Jamia Masjid Cantt',
    'location': 'Lahore Cantt, Lahore',
    'username': '',
    'latitude': 31.5000,
    'longitude': 74.3900,
  },
  {
    'name': 'Masjid-e-Nabawwi Gulberg',
    'location': 'Gulberg II, Lahore',
    'username': '',
    'latitude': 31.5220,
    'longitude': 74.3650,
  },
  {
    'name': 'Jamia Masjid Mozang',
    'location': 'Mozang, Lahore',
    'username': '',
    'latitude': 31.5430,
    'longitude': 74.3180,
  },
  {
    'name': 'Masjid Quba',
    'location': 'Defence Road, Lahore',
    'username': '',
    'latitude': 31.4550,
    'longitude': 74.2800,
  },
];

/// Seeds the Firestore database with Lahore masjids.
/// Call this once from main.dart or a standalone script.
///
/// @param force If true, clears existing masjids first.
Future<void> seedLahoreMasjids({bool force = false}) async {
  final firestore = FirebaseFirestore.instance;
  final masjidsRef = firestore.collection('masjids');

  if (force) {
    // Clear existing masjids
    final existing = await masjidsRef.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
    print('Cleared ${existing.docs.length} existing masjids');
  }

  int count = 0;
  for (final data in _lahoreMasjids) {
    final masjid = Masjid(
      name: data['name'] as String,
      location: data['location'] as String,
      username: data['username'] as String? ?? '',
      prayerTimes: [
        PrayerTime(name: 'Fajr', time: ''),
        PrayerTime(name: 'Dhuhr', time: ''),
        PrayerTime(name: 'Asr', time: ''),
        PrayerTime(name: 'Maghrib', time: ''),
        PrayerTime(name: 'Isha', time: ''),
      ],
      jummahTime: '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );

    try {
      await masjidsRef.add(masjid.toJson());
      count++;
    } catch (e) {
      print('Error adding ${masjid.name}: $e');
    }
  }

  print('Seeded $count Lahore masjids successfully');

  // Create a composite index hint for distance-based queries
  print('');
  print('IMPORTANT: Create a Firestore composite index for masjids:');
  print('  Collection: masjids');
  print('  Fields: location (ascending), name (ascending)');
  print('  Or run: firebase deploy --only firestore:indexes');
}

/// For Google Maps Places API integration (future):
///
/// 1. Get a Google Maps API key
/// 2. Use the Places API Text Search:
///    https://maps.googleapis.com/maps/api/place/textsearch/json
///      ?query=mosques+in+Lahore+Pakistan
///      &key=YOUR_API_KEY
///
/// 3. Parse response for: name, formatted_address, geometry/location
/// 4. Map to the _lahoreMasjids format above
/// 5. Call seedLahoreMasjids()
