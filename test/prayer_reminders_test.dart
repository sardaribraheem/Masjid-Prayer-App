import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:masjid_app/l10n/app_localization.dart';
import 'package:masjid_app/models/app_data.dart';
import 'package:masjid_app/models/prayer_reminder.dart';
import 'package:masjid_app/providers/prayer_reminder_provider.dart';
import 'package:masjid_app/services/prayer_notification_service.dart';
import 'package:masjid_app/services/prayer_reminder_store.dart';
import 'package:masjid_app/services/storage_service.dart';
import 'package:masjid_app/widgets/prayer_reminder_settings.dart';

Masjid mosque({
  String id = 'a',
  String fajr = '5:30 AM',
  String? jummah = '1:30 PM',
}) => Masjid(
  id: id,
  name: 'Masjid $id',
  nameUrdu: 'مسجد',
  location: 'Karachi',
  jummahTime: jummah,
  prayerTimes: [
    PrayerTime(name: 'Isha', time: '8:00 PM'),
    PrayerTime(name: 'Sunrise', time: '6:15 AM'),
    PrayerTime(name: 'Dhuhr', time: '1:00 PM'),
    PrayerTime(name: 'Fajr', time: fajr),
    PrayerTime(name: 'Maghrib', time: '6:00 PM'),
    PrayerTime(name: 'Sunset', time: '5:59 PM'),
    PrayerTime(name: 'Asr', time: '4:30 PM'),
  ],
);

class MemoryStore implements PrayerReminderStore {
  PrayerReminderPreferences value;
  bool fail = false;
  MemoryStore([this.value = const PrayerReminderPreferences()]);
  @override
  PrayerReminderPreferences loadPrayerReminders() => value;
  @override
  Future<void> savePrayerReminders(
    PrayerReminderPreferences preferences,
  ) async {
    if (fail) throw StateError('Storage unavailable');
    value = preferences;
  }
}

class FakeNotifications extends PrayerNotificationGateway {
  @override
  bool supported = true;
  ReminderPermissions permission = const ReminderPermissions(
    notifications: true,
    exactAlarms: true,
  );
  int prompts = 0;
  int cancels = 0;
  bool failSchedule = false;
  bool retainAll = true;
  bool failTest = false;
  Completer<void>? scheduleGate;
  List<PrayerReminder> reminders = [];
  final pending = <int>{};
  String? masjidId;
  String? locale;
  @override
  Future<ReminderPermissions> permissions({bool request = false}) async {
    if (request) prompts++;
    return permission;
  }

  @override
  Future<tz.Location> deviceTimezone() async => tz.getLocation('Asia/Karachi');
  @override
  Future<void> cancelReminders() async {
    cancels++;
    pending.clear();
    reminders = [];
    masjidId = null;
  }

  @override
  Future<void> schedule(
    List<PrayerReminder> plan,
    Masjid masjid,
    int leadMinutes,
    String language,
  ) async {
    await scheduleGate?.future;
    reminders = plan;
    masjidId = masjid.id;
    locale = language;
    pending.addAll(plan.map((p) => p.id));
    if (failSchedule) throw StateError('Partial native failure');
    if (!retainAll) pending.remove(plan.first.id);
  }

  @override
  Future<Set<int>> pendingIds() async => Set.of(pending);
  @override
  Future<void> scheduleTest(String language) async {
    if (failTest) throw StateError('Test alarm unavailable');
    pending.add(prayerReminderTestId);
  }

  @override
  Future<void> openNotificationSettings() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final karachi = tz.getLocation('Asia/Karachi');
  List<PrayerReminder> plan({
    Masjid? masjid,
    int lead = 15,
    tz.TZDateTime? now,
  }) => buildPrayerReminders(
    masjid: masjid ?? mosque(),
    leadMinutes: lead,
    now: now ?? tz.TZDateTime(karachi, 2026, 10, 14, 9),
  );

  group('Prayer reminder calendar', () {
    test(
      'five prayers have unique weekly slots; sunrise/sunset are excluded',
      () {
        final reminders = plan();
        expect(reminders, hasLength(35));
        expect(reminders.map((r) => r.id).toSet(), hasLength(35));
        expect(
          reminders.where((r) => ['Sunrise', 'Sunset'].contains(r.prayerName)),
          isEmpty,
        );
        for (final reminder in reminders) {
          expect(prayerReminderIds, contains(reminder.id));
          expect(
            reminder.remindAt.isAfter(tz.TZDateTime(karachi, 2026, 10, 14, 9)),
            isTrue,
          );
          expect(reminder.prayerAt.difference(reminder.remindAt).inMinutes, 15);
        }
      },
    );
    test(
      '20 minutes shifts every trigger by five minutes without changing IDs',
      () {
        final first = {for (final r in plan()) r.id: r};
        for (final r in plan(lead: 20)) {
          expect(r.prayerAt, first[r.id]!.prayerAt);
          expect(first[r.id]!.remindAt.difference(r.remindAt).inMinutes, 5);
        }
      },
    );
    test('Friday replaces Dhuhr with Jummah; six other days retain Dhuhr', () {
      final reminders = plan();
      final jummah = reminders.singleWhere((r) => r.prayerName == 'Jummah');
      expect(jummah.prayerAt.weekday, DateTime.friday);
      expect(jummah.prayerAt.hour, 13);
      expect(jummah.prayerAt.minute, 30);
      expect(reminders.where((r) => r.prayerName == 'Dhuhr'), hasLength(6));
      expect(
        reminders.where(
          (r) =>
              r.prayerName == 'Dhuhr' && r.prayerAt.weekday == DateTime.friday,
        ),
        isEmpty,
      );
    });
    test('unset Jummah falls back to the valid Friday Dhuhr time', () {
      final reminders = plan(masjid: mosque(jummah: 'not set'));
      expect(reminders.where((r) => r.prayerName == 'Jummah'), isEmpty);
      expect(reminders.where((r) => r.prayerName == 'Dhuhr'), hasLength(7));
    });
    test(
      'invalid or missing times are skipped instead of inventing a schedule',
      () {
        expect(plan(masjid: mosque(fajr: '25:00')), hasLength(28));
        final empty = mosque()
          ..prayerTimes = []
          ..jummahTime = null;
        expect(plan(masjid: empty), isEmpty);
        expect(() => plan(lead: 0), throwsArgumentError);
        expect(() => plan(lead: 61), throwsArgumentError);
      },
    );
    test(
      'midnight lead falls on preceding weekday and crosses year boundary',
      () {
        final reminders = plan(
          masjid: mosque(fajr: '00:10'),
          lead: 20,
          now: tz.TZDateTime(karachi, 2026, 12, 31, 23, 40),
        );
        final fajr = reminders.firstWhere((r) => r.prayerName == 'Fajr');
        expect(fajr.prayerAt, tz.TZDateTime(karachi, 2027, 1, 1, 0, 10));
        expect(fajr.remindAt, tz.TZDateTime(karachi, 2026, 12, 31, 23, 50));
        expect(fajr.remindAt.weekday, DateTime.thursday);
      },
    );
    test(
      'already elapsed trigger rolls a calendar week, never a past alarm',
      () {
        final now = tz.TZDateTime(karachi, 2026, 10, 14, 5, 20);
        final sameWeekday = plan(now: now).singleWhere(
          (r) => r.prayerName == 'Fajr' && r.prayerAt.weekday == now.weekday,
        );
        expect(sameWeekday.prayerAt.day, 21);
        expect(sameWeekday.remindAt.hour, 5);
        expect(sameWeekday.remindAt.minute, 15);
      },
    );
    test(
      'week rollover preserves wall time across daylight-saving changes',
      () {
        final ny = tz.getLocation('America/New_York');
        final now = tz.TZDateTime(ny, 2026, 3, 1, 6);
        final sunday = plan(now: now).singleWhere(
          (r) =>
              r.prayerName == 'Fajr' && r.prayerAt.weekday == DateTime.sunday,
        );
        expect(sunday.prayerAt, tz.TZDateTime(ny, 2026, 3, 8, 5, 30));
        expect(sunday.remindAt.hour, 5);
        expect(sunday.remindAt.minute, 15);
        expect(sunday.prayerAt.timeZoneOffset, const Duration(hours: -4));
      },
    );
  });

  group('Device preferences', () {
    test(
      'legacy true toggle does not silently opt users into alarms',
      () async {
        SharedPreferences.setMockInitialValues({'notifications_enabled': true});
        final store = StorageService();
        await store.initialize();
        expect(store.loadPrayerReminders().enabled, isFalse);
        expect(store.loadPrayerReminders().leadMinutes, 15);
      },
    );
    test(
      'enabled and lead time persist together and survive initialization',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = StorageService();
        await store.initialize();
        await store.savePrayerReminders(
          const PrayerReminderPreferences(enabled: true, leadMinutes: 20),
        );
        await store.initialize();
        expect(store.loadPrayerReminders().enabled, isTrue);
        expect(store.loadPrayerReminders().leadMinutes, 20);
      },
    );
    test(
      'corrupt preferences fall back to safe defaults; invalid leads use 15',
      () async {
        SharedPreferences.setMockInitialValues({
          'prayer_reminders_v1': 'invalid JSON',
        });
        final store = StorageService();
        await store.initialize();
        expect(store.loadPrayerReminders().enabled, isFalse);
        expect(
          PrayerReminderPreferences.fromJson({'leadMinutes': 99}).leadMinutes,
          15,
        );
        expect(
          PrayerReminderPreferences.fromJson({'leadMinutes': 0}).leadMinutes,
          15,
        );
      },
    );
  });

  group('Reminder lifecycle', () {
    late MemoryStore store;
    late FakeNotifications gateway;
    late PrayerReminderProvider reminders;
    late Map<String, StreamController<Masjid?>> streams;
    setUp(() {
      store = MemoryStore();
      gateway = FakeNotifications();
      streams = {
        'a': StreamController<Masjid?>.broadcast(),
        'b': StreamController<Masjid?>.broadcast(),
      };
      reminders = PrayerReminderProvider(
        store: store,
        gateway: gateway,
        masjidStream: (id) => streams[id]!.stream,
        now: () => DateTime.utc(2026, 10, 14, 4),
      );
    });
    tearDown(() async {
      reminders.dispose();
      for (final stream in streams.values) {
        await stream.close();
      }
    });
    test(
      'initial off/null state clears old schedules without asking permission',
      () async {
        gateway.pending.add(41010);
        await reminders.configure(null, 'en');
        expect(gateway.pending, isEmpty);
        expect(gateway.prompts, 0);
        expect(reminders.status, PrayerReminderStatus.off);
      },
    );
    test(
      'denied notifications or exact alarms do not enable or report success',
      () async {
        await reminders.configure(mosque(), 'en');
        for (final permission in [
          const ReminderPermissions(notifications: false, exactAlarms: true),
          const ReminderPermissions(notifications: true, exactAlarms: false),
        ]) {
          gateway.permission = permission;
          expect(await reminders.setEnabled(true), isFalse);
          expect(store.value.enabled, isFalse);
          expect(gateway.pending, isEmpty);
          expect(reminders.status, PrayerReminderStatus.permissionsNeeded);
        }
      },
    );
    test(
      'opt-in schedules all prayers; disable cancels them and persists off',
      () async {
        await reminders.configure(mosque(), 'en');
        expect(await reminders.setEnabled(true), isTrue);
        expect(reminders.scheduledCount, 35);
        expect(reminders.status, PrayerReminderStatus.scheduled);
        expect(gateway.pending, hasLength(35));
        expect(await reminders.setEnabled(false), isTrue);
        expect(store.value.enabled, isFalse);
        expect(gateway.pending, isEmpty);
        expect(reminders.status, PrayerReminderStatus.off);
      },
    );
    test(
      'lead and masjid changes replace old alarms, retaining one schedule',
      () async {
        await reminders.configure(mosque(), 'en');
        await reminders.setEnabled(true);
        await reminders.setLeadMinutes(20);
        expect(store.value.leadMinutes, 20);
        expect(
          gateway.reminders.every(
            (r) => r.prayerAt.difference(r.remindAt).inMinutes == 20,
          ),
          isTrue,
        );
        await reminders.configure(mosque(id: 'b', fajr: '6:00 AM'), 'ur');
        expect(gateway.masjidId, 'b');
        expect(gateway.locale, 'ur');
        expect(gateway.pending, hasLength(35));
        expect(
          gateway.reminders
              .firstWhere((r) => r.prayerName == 'Fajr')
              .prayerAt
              .hour,
          6,
        );
      },
    );
    test(
      'rapid queued changes finish with the newest mosque and offset',
      () async {
        await reminders.configure(mosque(), 'en');
        await reminders.setEnabled(true);
        final changes = [
          reminders.setLeadMinutes(20),
          reminders.configure(mosque(id: 'b'), 'en'),
          reminders.setLeadMinutes(30),
        ];
        await Future.wait(changes);
        expect(gateway.masjidId, 'b');
        expect(gateway.pending, hasLength(35));
        expect(
          gateway.reminders.every(
            (r) => r.prayerAt.difference(r.remindAt).inMinutes == 30,
          ),
          isTrue,
        );
        expect(reminders.busy, isFalse);
      },
    );
    test(
      'live timetable edits reschedule; unchanged snapshots do not',
      () async {
        await reminders.configure(mosque(), 'en');
        await reminders.setEnabled(true);
        final before = gateway.cancels;
        streams['a']!.add(mosque());
        await Future<void>.delayed(Duration.zero);
        expect(gateway.cancels, before);
        streams['a']!.add(mosque(fajr: '6:10 AM'));
        await Future<void>.delayed(Duration.zero);
        await reminders.refresh();
        expect(
          gateway.reminders
              .firstWhere((r) => r.prayerName == 'Fajr')
              .prayerAt
              .minute,
          10,
        );
        streams['a']!.addError(StateError('Stream unavailable'));
        await Future<void>.delayed(Duration.zero);
        expect(reminders.status, PrayerReminderStatus.error);
        expect(gateway.pending, isEmpty);
        expect(reminders.errorKey, 'reminder_sync_failed');
      },
    );
    test(
      'partial scheduling failure rolls back every reminder and is visible',
      () async {
        await reminders.configure(mosque(), 'en');
        gateway.failSchedule = true;
        expect(await reminders.setEnabled(true), isFalse);
        expect(reminders.status, PrayerReminderStatus.error);
        expect(reminders.scheduledCount, 0);
        expect(gateway.pending, isEmpty);
        gateway.failSchedule = false;
        expect(await reminders.refresh(), isTrue);
        expect(reminders.scheduledCount, 35);
      },
    );
    test(
      'missing native pending IDs cannot be reported as scheduled',
      () async {
        await reminders.configure(mosque(), 'en');
        gateway.retainAll = false;
        expect(await reminders.setEnabled(true), isFalse);
        expect(reminders.status, PrayerReminderStatus.error);
        expect(gateway.pending, isEmpty);
      },
    );
    test('storage failure leaves the saved preference unchanged', () async {
      await reminders.configure(mosque(), 'en');
      store.fail = true;
      expect(await reminders.setEnabled(true), isFalse);
      expect(reminders.enabled, isFalse);
      expect(store.value.enabled, isFalse);
      expect(gateway.pending, isEmpty);
    });
    test(
      'revoked permission on resume clears alarms without another prompt',
      () async {
        await reminders.configure(mosque(), 'en');
        await reminders.setEnabled(true);
        final prompts = gateway.prompts;
        gateway.permission = const ReminderPermissions(
          notifications: true,
          exactAlarms: false,
        );
        expect(await reminders.refresh(), isFalse);
        expect(gateway.pending, isEmpty);
        expect(reminders.status, PrayerReminderStatus.permissionsNeeded);
        expect(gateway.prompts, prompts);
      },
    );
    test('restart restores opt-in and custom lead without prompting', () async {
      reminders.dispose();
      store.value = const PrayerReminderPreferences(
        enabled: true,
        leadMinutes: 17,
      );
      reminders = PrayerReminderProvider(
        store: store,
        gateway: gateway,
        masjidStream: (id) => streams[id]!.stream,
      );
      await reminders.configure(mosque(), 'en');
      expect(reminders.status, PrayerReminderStatus.scheduled);
      expect(gateway.prompts, 0);
      expect(
        gateway.reminders.every(
          (r) => r.prayerAt.difference(r.remindAt).inMinutes == 17,
        ),
        isTrue,
      );
    });
    test(
      'no mosque or no valid timetable is never presented as ready',
      () async {
        await reminders.configure(null, 'en');
        await reminders.setEnabled(true);
        expect(reminders.status, PrayerReminderStatus.noMasjid);
        final empty = mosque()
          ..prayerTimes = []
          ..jummahTime = null;
        await reminders.configure(empty, 'en');
        expect(reminders.status, PrayerReminderStatus.noTimes);
        expect(gateway.pending, isEmpty);
      },
    );
    test(
      'non-Android platforms save lead preferences without native alarms',
      () async {
        gateway.supported = false;
        await reminders.configure(mosque(), 'en');
        expect(await reminders.setEnabled(true), isFalse);
        await reminders.setLeadMinutes(20);
        expect(store.value.leadMinutes, 20);
        expect(gateway.prompts, 0);
        expect(gateway.cancels, 0);
        expect(reminders.status, PrayerReminderStatus.unsupported);
      },
    );
    test(
      'one-minute test does not remove prayer alarms even if it fails',
      () async {
        await reminders.configure(mosque(), 'en');
        await reminders.setEnabled(true);
        expect(await reminders.testReminder(), isTrue);
        expect(gateway.pending, hasLength(36));
        gateway.failTest = true;
        expect(await reminders.testReminder(), isFalse);
        expect(gateway.pending, hasLength(36));
        expect(reminders.status, PrayerReminderStatus.scheduled);
        expect(reminders.errorKey, 'reminder_failed');
      },
    );
    test('notification tap requests the prayer tab', () async {
      expect(reminders.tapRevision, 0);
      gateway.onTap!();
      expect(reminders.tapRevision, 1);
    });
  });

  for (final locale in ['en', 'ur']) {
    testWidgets(
      'lead picker validates custom values and works at 320px in $locale',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await appLocalization.setLanguage(locale);
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final provider = PrayerReminderProvider(
          store: MemoryStore(),
          gateway: FakeNotifications(),
          masjidStream: (_) => const Stream.empty(),
        );
        addTearDown(provider.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              home: Scaffold(
                body: Directionality(
                  textDirection: locale == 'ur'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: const SingleChildScrollView(
                    child: PrayerReminderSettings(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text(appLocalization.t('reminder_lead_title')));
        await tester.pumpAndSettle();
        final twenty = appLocalization
            .t('reminder_minutes')
            .replaceAll('{minutes}', '20');
        await tester.tap(find.text(twenty));
        await tester.pumpAndSettle();
        expect(provider.leadMinutes, 20);
        await tester.tap(find.text(appLocalization.t('reminder_lead_title')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '61');
        await tester.tap(find.text(appLocalization.t('save')));
        await tester.pumpAndSettle();
        expect(find.text(appLocalization.t('reminder_range')), findsOneWidget);
        expect(provider.leadMinutes, 20);
        await tester.enterText(find.byType(TextFormField), '17');
        await tester.tap(find.text(appLocalization.t('save')));
        await tester.pumpAndSettle();
        expect(provider.leadMinutes, 17);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
