import '../models/app_data.dart';

int? parsePrayerMinutes(String value) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  var hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  final period = match[3]?.toUpperCase();
  if (minute > 59 || hour > 23 || (period != null && (hour < 1 || hour > 12))) {
    return null;
  }
  if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
  return hour * 60 + minute;
}

({PrayerTime prayer, DateTime at})? nextPrayer(
  List<PrayerTime> prayers,
  DateTime now,
) {
  ({PrayerTime prayer, DateTime at})? next;
  for (final prayer in prayers) {
    if (['sunrise', 'sunset'].contains(prayer.name.toLowerCase())) continue;
    final minutes = parsePrayerMinutes(prayer.time);
    if (minutes == null) continue;
    var at = DateTime(
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!at.isAfter(now)) {
      at = DateTime(
        now.year,
        now.month,
        now.day + 1,
        minutes ~/ 60,
        minutes % 60,
      );
    }
    if (next == null || at.isBefore(next.at)) next = (prayer: prayer, at: at);
  }
  return next;
}
