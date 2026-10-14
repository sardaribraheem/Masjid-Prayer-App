import 'package:timezone/timezone.dart' as tz;
import 'app_data.dart';
import '../utils/prayer_schedule.dart';

/// Device preferences. The legacy saved-only notification toggle is ignored.
class PrayerReminderPreferences {
  final bool enabled;
  final int leadMinutes;
  const PrayerReminderPreferences({
    this.enabled = false,
    this.leadMinutes = 15,
  });
  PrayerReminderPreferences copyWith({bool? enabled, int? leadMinutes}) =>
      PrayerReminderPreferences(
        enabled: enabled ?? this.enabled,
        leadMinutes: leadMinutes ?? this.leadMinutes,
      );
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'leadMinutes': leadMinutes,
  };
  factory PrayerReminderPreferences.fromJson(Map<String, dynamic> json) {
    final lead = json['leadMinutes'];
    return PrayerReminderPreferences(
      enabled: json['enabled'] == true,
      leadMinutes: lead is int && lead >= 1 && lead <= 60 ? lead : 15,
    );
  }
}

class PrayerReminder {
  final int id;
  final String prayerName;
  final String prayerTime;
  final tz.TZDateTime prayerAt;
  final tz.TZDateTime remindAt;
  const PrayerReminder({
    required this.id,
    required this.prayerName,
    required this.prayerTime,
    required this.prayerAt,
    required this.remindAt,
  });
}

const prayerReminderTestId = 41100;
final prayerReminderIds = [
  for (var weekday = 1; weekday <= 7; weekday++)
    for (var prayer = 0; prayer < 5; prayer++) 41000 + weekday * 10 + prayer,
  prayerReminderTestId,
];

/// Seven weekly slots per prayer keep Friday Jummah separate from Dhuhr.
/// Recurrence follows the reminder's weekday, including midnight lead offsets.
List<PrayerReminder> buildPrayerReminders({
  required Masjid masjid,
  required tz.TZDateTime now,
  required int leadMinutes,
}) {
  if (leadMinutes < 1 || leadMinutes > 60) {
    throw ArgumentError.value(leadMinutes, 'leadMinutes', 'Use 1–60 minutes');
  }
  const names = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final times = {
    for (final prayer in masjid.prayerTimes)
      prayer.name.trim().toLowerCase(): prayer,
  };
  final result = <PrayerReminder>[];
  for (var weekday = 1; weekday <= 7; weekday++) {
    for (var index = 0; index < names.length; index++) {
      var prayer = times[names[index]];
      if (weekday == DateTime.friday &&
          names[index] == 'dhuhr' &&
          parsePrayerMinutes(masjid.jummahTime ?? '') != null) {
        prayer = PrayerTime(name: 'Jummah', time: masjid.jummahTime!);
      }
      if (prayer == null) continue;
      final minutes = parsePrayerMinutes(prayer.time);
      if (minutes == null) continue;
      var daysAhead = (weekday - now.weekday + 7) % 7;
      var prayerAt = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + daysAhead,
        minutes ~/ 60,
        minutes % 60,
      );
      var remindAt = prayerAt.subtract(Duration(minutes: leadMinutes));
      if (!remindAt.isAfter(now)) {
        daysAhead += 7;
        prayerAt = tz.TZDateTime(
          now.location,
          now.year,
          now.month,
          now.day + daysAhead,
          minutes ~/ 60,
          minutes % 60,
        );
        remindAt = prayerAt.subtract(Duration(minutes: leadMinutes));
      }
      result.add(
        PrayerReminder(
          id: 41000 + weekday * 10 + index,
          prayerName: prayer.name,
          prayerTime: prayer.time,
          prayerAt: prayerAt,
          remindAt: remindAt,
        ),
      );
    }
  }
  result.sort((a, b) => a.remindAt.compareTo(b.remindAt));
  return result;
}
