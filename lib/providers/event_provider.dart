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
  int _generation = 0;
  String? _masjidId;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool _includePending = false;
  bool _upcomingOnly = false;
  String? _statusFilter;

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
    String? statusFilter,
  }) async {
    final generation = ++_generation;
    _masjidId = masjidId;
    _includePending = includePending;
    _statusFilter = statusFilter;
    _upcomingOnly = false;
    _streamSub?.cancel();
    _loadingMore = false;
    _events = [];
    _hasMore = false;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final page = await _repository.getEvents(
        masjidId,
        includePending: includePending,
        statusFilter: statusFilter,
      );
      if (generation != _generation) return;
      _hasMore = page.length > 30;
      _events = page.take(30).toList();
      _error = null;
    } catch (e) {
      if (generation != _generation) return;
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Listen to real-time updates for events. Cancels any prior subscription
  /// (tab switching recreates pages) and returns the new subscription so the
  /// caller can cancel it in dispose().
  StreamSubscription<List<Event>> subscribeToEvents(
    String masjidId, {
    bool upcomingOnly = false,
  }) {
    final generation = ++_generation;
    _masjidId = masjidId;
    _includePending = false;
    _statusFilter = null;
    _upcomingOnly = upcomingOnly;
    _events = [];
    _hasMore = false;
    _loadingMore = false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    _streamSub?.cancel();
    final sub = _repository
        .getEventsStream(masjidId, upcomingOnly: upcomingOnly)
        .listen(
          (events) {
            if (generation != _generation) return;
            _events = events.take(30).toList();
            _hasMore = events.length > 30;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (generation != _generation) return;
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
    _streamSub = sub;
    return sub;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _masjidId == null || _events.isEmpty) {
      return;
    }
    // Older pages are a point-in-time view. Stop the head listener while
    // browsing them so a new head snapshot cannot silently discard pages.
    _streamSub?.cancel();
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.getEvents(
        _masjidId!,
        after: _events.last,
        includePending: _includePending,
        statusFilter: _statusFilter,
        upcomingOnly: _upcomingOnly,
      );
      if (generation != _generation) return;
      _hasMore = page.length > 30;
      final ids = _events.map((item) => item.id).toSet();
      _events.addAll(page.take(30).where((item) => !ids.contains(item.id)));
      _error = null;
    } catch (error) {
      if (generation == _generation) _error = error.toString();
    } finally {
      if (generation == _generation) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
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
