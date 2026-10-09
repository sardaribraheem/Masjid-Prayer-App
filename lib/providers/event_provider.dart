import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../repositories/event_repository.dart';

/// ChangeNotifier provider for events data.
/// Wraps EventRepository and provides reactive state for the UI.
class EventProvider extends ChangeNotifier {
  final EventRepository _repository = EventRepository();

  StreamSubscription<List<Event>>? _streamSub;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get events filtered by masjid ID
  List<Event> getEventsByMasjid(String masjidId) {
    return _events.where((e) => e.masjidId == masjidId).toList();
  }

  /// Public feed should only show approved events.
  List<Event> getApprovedEventsByMasjid(String masjidId) {
    return _events
        .where((e) => e.masjidId == masjidId && e.isApproved)
        .toList();
  }

  /// Admin review queue for pending approvals.
  List<Event> getPendingEventsByMasjid(String masjidId) {
    return _events
        .where((e) => e.masjidId == masjidId && e.status == EventStatus.pending)
        .toList();
  }

  /// Load events from Firestore for a specific masjid
  Future<void> loadEvents(
    String masjidId, {
    bool includePending = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await _repository.getEvents(
        masjidId,
        includePending: includePending,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Listen to real-time updates for events. Cancels any prior subscription
  /// (tab switching recreates pages) and returns the new subscription so the
  /// caller can cancel it in dispose().
  StreamSubscription<List<Event>> subscribeToEvents(String masjidId) {
    _streamSub?.cancel();
    final sub = _repository
        .getEventsStream(masjidId)
        .listen(
          (events) {
            _events = events;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
    _streamSub = sub;
    return sub;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  /// Add a new event
  Future<bool> addEvent(Event event) async {
    final success = await _repository.addEvent(event);
    if (success) {
      // Also sync to AppData for backward compatibility
      AppData.allEvents.add(event);
      notifyListeners();
    }
    return success;
  }

  /// Update an existing event
  Future<bool> updateEvent(String masjidId, Event event) async {
    final success = await _repository.updateEvent(masjidId, event);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Change an event’s moderation state.
  Future<bool> updateEventStatus(
    String masjidId,
    String eventId,
    EventStatus status,
  ) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) {
      return false;
    }

    final updated = _events[index].copyWith(status: status);
    final success = await _repository.updateEvent(masjidId, updated);
    if (success) {
      _events[index] = updated;
      notifyListeners();
    }
    return success;
  }

  /// Delete an event
  Future<bool> deleteEvent(String masjidId, String eventId) async {
    final success = await _repository.deleteEvent(masjidId, eventId);
    if (success) {
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    }
    return success;
  }
}
