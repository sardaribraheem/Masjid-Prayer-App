import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/app_data.dart';
import '../models/prayer_reminder.dart';
import '../services/prayer_notification_service.dart';
import '../services/prayer_reminder_store.dart';

enum PrayerReminderStatus {
  off,
  scheduled,
  permissionsNeeded,
  noMasjid,
  noTimes,
  unsupported,
  error,
}

class PrayerReminderProvider extends ChangeNotifier {
  final PrayerReminderStore _store;
  final PrayerNotificationGateway _gateway;
  final Stream<Masjid?> Function(String id) _masjidStream;
  final DateTime Function() _now;
  late PrayerReminderPreferences _preferences;
  StreamSubscription<Masjid?>? _subscription;
  String? _subscriptionId;
  String? _boundId;
  Masjid? _masjid;
  String _locale;
  Future<void> _queue = Future.value();
  int _jobs = 0;
  bool _disposed = false;
  bool _configured = false;
  int _tapRevision = 0;
  int _scheduledCount = 0;
  PrayerReminderStatus _status = PrayerReminderStatus.off;
  String? _errorKey;

  PrayerReminderProvider({
    required PrayerReminderStore store,
    required PrayerNotificationGateway gateway,
    required Stream<Masjid?> Function(String) masjidStream,
    DateTime Function()? now,
    String locale = 'en',
  }) : _store = store,
       _gateway = gateway,
       _masjidStream = masjidStream,
       _now = now ?? DateTime.now,
       _locale = locale {
    _preferences = _store.loadPrayerReminders();
    if (!supported) _status = PrayerReminderStatus.unsupported;
    _gateway.onTap = () {
      _tapRevision++;
      _notify();
    };
  }
  bool get supported => _gateway.supported;
  bool get enabled => _preferences.enabled;
  int get leadMinutes => _preferences.leadMinutes;
  bool get busy => _jobs > 0;
  int get scheduledCount => _scheduledCount;
  int get tapRevision => _tapRevision;
  PrayerReminderStatus get status => _status;
  String? get errorKey => _errorKey;
  String? get masjidName =>
      _locale == 'ur' && (_masjid?.nameUrdu.isNotEmpty ?? false)
      ? _masjid!.nameUrdu
      : _masjid?.name;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Serialize cancellation and scheduling so rapid mosque/timetable changes
  /// cannot leave two sets of reminders behind.
  Future<bool> _perform(
    Future<bool> Function() action, {
    bool rollback = true,
  }) {
    _jobs++;
    _notify();
    final job = _queue
        .then((_) async {
          if (_disposed) return false;
          _errorKey = null;
          try {
            return await action();
          } catch (error) {
            debugPrint('Prayer reminder operation failed: $error');
            _errorKey = 'reminder_failed';
            if (rollback) {
              _status = PrayerReminderStatus.error;
              _scheduledCount = 0;
              try {
                if (supported) await _gateway.cancelReminders();
              } catch (_) {
                /* Retry on resume. */
              }
            }
            return false;
          } finally {
            _notify();
          }
        })
        .whenComplete(() {
          _jobs--;
          _notify();
        });
    _queue = job.then<void>((_) {});
    return job;
  }

  Future<bool> configure(Masjid? masjid, String locale) {
    final id = masjid?.id;
    if (_configured && id == _boundId && locale == _locale) {
      if (!enabled) _masjid = masjid;
      return Future.value(true);
    }
    _configured = true;
    if (id != _boundId || !enabled) _masjid = masjid;
    _boundId = id;
    _locale = locale;
    return refresh();
  }

  Future<void> _listen() async {
    final id = enabled && supported ? _boundId : null;
    if (id == _subscriptionId && _subscription != null) return;
    await _subscription?.cancel();
    _subscription = null;
    _subscriptionId = id;
    if (id == null) return;
    _subscription = _masjidStream(id).listen(
      (data) {
        if (_disposed || id != _boundId || !enabled) return;
        final previous = _fingerprint(_masjid);
        _masjid = data;
        if (_fingerprint(data) != previous) unawaited(refresh());
      },
      onError: (Object error) {
        if (_disposed || id != _boundId) return;
        unawaited(
          _perform(() async {
            if (_disposed || id != _boundId || !enabled) return true;
            await _subscription?.cancel();
            _subscription = null;
            await _gateway.cancelReminders();
            _scheduledCount = 0;
            _status = PrayerReminderStatus.error;
            _errorKey = 'reminder_sync_failed';
            return false;
          }),
        );
      },
    );
  }

  String _fingerprint(Masjid? masjid) => jsonEncode(
    masjid == null
        ? null
        : {
            'id': masjid.id,
            'name': masjid.name,
            'nameUrdu': masjid.nameUrdu,
            'times': masjid.prayerTimes
                .map((prayer) => prayer.toJson())
                .toList(),
            'jummah': masjid.jummahTime,
          },
  );

  Future<bool> _reconcile() async {
    _scheduledCount = 0;
    if (!supported) {
      _status = PrayerReminderStatus.unsupported;
      return true;
    }
    await _listen();
    await _gateway.cancelReminders();
    if (!enabled) {
      _status = PrayerReminderStatus.off;
      return true;
    }
    final permissions = await _gateway.permissions();
    if (!permissions.granted) {
      _status = PrayerReminderStatus.permissionsNeeded;
      return false;
    }
    final masjid = _masjid;
    if (masjid == null || masjid.id.isEmpty) {
      _status = PrayerReminderStatus.noMasjid;
      return true;
    }
    final location = await _gateway.deviceTimezone();
    final plan = buildPrayerReminders(
      masjid: masjid,
      now: tz.TZDateTime.from(_now(), location),
      leadMinutes: leadMinutes,
    );
    if (plan.isEmpty) {
      _status = PrayerReminderStatus.noTimes;
      return true;
    }
    await _gateway.schedule(plan, masjid, leadMinutes, _locale);
    final pending = await _gateway.pendingIds();
    if (!plan.every((reminder) => pending.contains(reminder.id))) {
      throw StateError('Android did not retain all scheduled reminders');
    }
    _scheduledCount = plan.length;
    _status = PrayerReminderStatus.scheduled;
    return true;
  }

  Future<bool> refresh() => _perform(_reconcile);

  Future<bool> setEnabled(bool value) => _perform(() async {
    if (!supported) {
      _status = PrayerReminderStatus.unsupported;
      return false;
    }
    if (value && !(await _gateway.permissions(request: true)).granted) {
      await _gateway.cancelReminders();
      _scheduledCount = 0;
      _status = PrayerReminderStatus.permissionsNeeded;
      return false;
    }
    final next = _preferences.copyWith(enabled: value);
    await _store.savePrayerReminders(next);
    _preferences = next;
    return _reconcile();
  });
  Future<bool> setLeadMinutes(int minutes) {
    if (minutes < 1 || minutes > 60) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    return _perform(() async {
      final next = _preferences.copyWith(leadMinutes: minutes);
      await _store.savePrayerReminders(next);
      _preferences = next;
      return _reconcile();
    });
  }

  Future<bool> testReminder() => _perform(() async {
    if (!supported || !enabled || !(await _gateway.permissions()).granted) {
      _status = supported
          ? PrayerReminderStatus.permissionsNeeded
          : PrayerReminderStatus.unsupported;
      return false;
    }
    await _gateway.scheduleTest(_locale);
    return true;
  }, rollback: false);
  Future<bool> openNotificationSettings() => _perform(() async {
    await _gateway.openNotificationSettings();
    return true;
  }, rollback: false);
  @override
  void dispose() {
    _disposed = true;
    _gateway.onTap = null;
    _subscription?.cancel();
    // OS schedules survive closing the app; disabling reminders cancels them.
    super.dispose();
  }
}
