import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';

/// Repository for Event CRUD operations in Firestore.
/// Events are stored as a subcollection under each masjid document.
class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _query(
    String masjidId, {
    bool includePending = false,
    bool upcomingOnly = false,
    String? statusFilter,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('masjids')
        .doc(masjidId)
        .collection('events');
    if (!includePending) {
      query = query.where('status', isEqualTo: 'approved');
    } else if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    if (upcomingOnly) {
      final now = DateTime.now();
      query = query.where(
        'eventDate',
        isGreaterThanOrEqualTo: DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String(),
      );
    }
    return query
        .orderBy('eventDate', descending: false)
        .orderBy(FieldPath.documentId);
  }

  /// Get a stream of events for a specific masjid
  Stream<List<Event>> getEventsStream(
    String masjidId, {
    bool upcomingOnly = false,
  }) {
    return _query(
      masjidId,
      upcomingOnly: upcomingOnly,
    ).limit(31).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  /// Fetch events once
  Future<List<Event>> getEvents(
    String masjidId, {
    bool includePending = false,
    bool upcomingOnly = false,
    String? statusFilter,
    Event? after,
  }) async {
    try {
      var query = _query(
        masjidId,
        includePending: includePending,
        upcomingOnly: upcomingOnly,
        statusFilter: statusFilter,
      );
      if (after != null) {
        query = query.startAfter([after.eventDate.toIso8601String(), after.id]);
      }
      final snapshot = await query.limit(31).get();
      return snapshot.docs
          .map((doc) => Event.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      rethrow;
    }
  }

  /// Add a new event to a masjid's subcollection
  Future<bool> addEvent(Event event) async {
    try {
      final doc = _firestore
          .collection('masjids')
          .doc(event.masjidId)
          .collection('events')
          .doc();
      await doc.set({...event.toJson(), 'id': doc.id});
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
