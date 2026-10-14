import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_reminder.dart';
import '../models/app_data.dart';
import '../l10n/app_translations.dart';

class ReminderPermissions {
  final bool notifications;
  final bool exactAlarms;
  const ReminderPermissions({
    required this.notifications,
    required this.exactAlarms,
  });
  bool get granted => notifications && exactAlarms;
}

/// Injectable native boundary: tests exercise scheduling decisions separately
/// from Android alarm delivery, which requires a real device.
abstract class PrayerNotificationGateway {
  bool get supported;
  VoidCallback? onTap;
  Future<ReminderPermissions> permissions({bool request = false});
  Future<tz.Location> deviceTimezone();
  Future<void> cancelReminders();
  Future<void> schedule(
    List<PrayerReminder> reminders,
    Masjid masjid,
    int leadMinutes,
    String locale,
  );
  Future<Set<int>> pendingIds();
  Future<void> scheduleTest(String locale);
  Future<void> openNotificationSettings();
}

class AndroidPrayerNotificationService extends PrayerNotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  static const channelId = 'prayer_reminders_v1';
  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _initialize() => _initializing ??= _initializePlugin();
  Future<void> _initializePlugin() async {
    try {
      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_prayer_notification'),
        ),
        onDidReceiveNotificationResponse: (_) => onTap?.call(),
      );
      if (initialized != true) {
        throw StateError('Notification initialization failed');
      }
      await _android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Prayer reminders',
          description: 'Reminders before the selected masjid prayer times',
          importance: Importance.high,
        ),
      );
      tzdata.initializeTimeZones();
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  @override
  Future<ReminderPermissions> permissions({bool request = false}) async {
    if (!supported) {
      return const ReminderPermissions(
        notifications: false,
        exactAlarms: false,
      );
    }
    await _initialize();
    var notifications = await _android.areNotificationsEnabled() == true;
    if (request && !notifications) {
      await _android.requestNotificationsPermission();
      notifications = await _android.areNotificationsEnabled() == true;
    }
    var exact = await _android.canScheduleExactNotifications() == true;
    if (request && notifications && !exact) {
      await _android.requestExactAlarmsPermission();
      exact = await _android.canScheduleExactNotifications() == true;
    }
    final channels = await _android.getNotificationChannels();
    final channelEnabled = !(channels ?? []).any(
      (channel) =>
          channel.id == channelId && channel.importance == Importance.none,
    );
    return ReminderPermissions(
      notifications: notifications && channelEnabled,
      exactAlarms: exact,
    );
  }

  @override
  Future<tz.Location> deviceTimezone() async {
    await _initialize();
    final timezone = await FlutterTimezone.getLocalTimezone();
    return tz.getLocation(timezone.identifier);
  }

  @override
  Future<void> cancelReminders() async {
    if (!supported) return;
    await _initialize();
    for (final id in prayerReminderIds) {
      await _plugin.cancel(id: id);
    }
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Prayer reminders',
      channelDescription: 'Reminders before the selected masjid prayer times',
      icon: 'ic_prayer_notification',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
  );
  @override
  Future<void> schedule(
    List<PrayerReminder> reminders,
    Masjid masjid,
    int leadMinutes,
    String locale,
  ) async {
    await _initialize();
    final translations = AppTranslations(locale: locale);
    final masjidName = locale == 'ur' && masjid.nameUrdu.isNotEmpty
        ? masjid.nameUrdu
        : masjid.name;
    for (final reminder in reminders) {
      final prayer = translations.t(reminder.prayerName.toLowerCase());
      final title = translations
          .t('reminder_title')
          .replaceAll('{prayer}', prayer)
          .replaceAll('{minutes}', '$leadMinutes');
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: title,
        body: '$masjidName · ${reminder.prayerTime}',
        scheduledDate: reminder.remindAt,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'prayer:${masjid.id}',
      );
    }
  }

  @override
  Future<Set<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests())
          .where((request) => prayerReminderIds.contains(request.id))
          .map((request) => request.id)
          .toSet();
  @override
  Future<void> scheduleTest(String locale) async {
    final location = await deviceTimezone();
    final translations = AppTranslations(locale: locale);
    await _plugin.zonedSchedule(
      id: prayerReminderTestId,
      title: translations.t('reminder_test_title'),
      body: translations.t('reminder_test_body'),
      scheduledDate: tz.TZDateTime.now(
        location,
      ).add(const Duration(minutes: 1)),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> openNotificationSettings() async {
    if (supported) {
      await const MethodChannel(
        'masjid_app/reminder_settings',
      ).invokeMethod<void>('openNotifications');
    }
  }
}
