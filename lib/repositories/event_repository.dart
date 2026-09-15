import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';

/// Repository for Event CRUD operations in Firestore.
/// Events are stored as a subcollection under each masjid document.
class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a stream of events for a specific masjid
  Stream<List<Event>> getEventsStream(String masjidId) {
    return _firestore
        .collection('masjids')
        .doc(masjidId)
        .collection('events')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromJson(doc.data()))
          .toList();
    });
  }

  /// Fetch events once
  Future<List<Event>> getEvents(String masjidId) async {
    try {
      final snapshot = await _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('events')
          .orderBy('eventDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => Event.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  /// Add a new event to a masjid's subcollection
  Future<bool> addEvent(Event event) async {
    try {
      await _firestore
          .collection('masjids')
          .doc(event.masjidId)
          .collection('events')
          .add(event.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding event: $e');
      return false;
    }
  }

  /// Update an existing event
  Future<bool> updateEvent(String masjidId, Event event) async {
    try {
      await _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('events')
          .doc(event.id)
          .update(event.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String masjidId, String eventId) async {
    try {
      await _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('events')
          .doc(eventId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }
}
