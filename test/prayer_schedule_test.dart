import 'package:flutter_test/flutter_test.dart';
import 'package:masjid_app/models/app_data.dart';
import 'package:masjid_app/utils/prayer_schedule.dart';

void main() {
  test('handles midnight, noon, 24-hour time and rejects invalid times', () {
    expect(parsePrayerMinutes('12:00 AM'), 0);
    expect(parsePrayerMinutes('12:00 PM'), 720);
    expect(parsePrayerMinutes('17:30'), 1050);
    expect(parsePrayerMinutes('5:30 pm'), 1050);
    for (final invalid in ['', 'not set', '25:10', '12:61', '0:30 PM']) {
      expect(parsePrayerMinutes(invalid), isNull);
    }
  });
  test('no schedule has no next prayer', () {
    expect(nextPrayer([], DateTime(2026, 10, 13)), isNull);
  });
  test('unsorted times, sunrise and unset times do not corrupt countdown', () {
    final result = nextPrayer([
      PrayerTime(name: 'Dhuhr', time: '1:15 PM'),
      PrayerTime(name: 'Sunrise', time: '6:20 AM'),
      PrayerTime(name: 'Fajr', time: '5:15 AM'),
      PrayerTime(name: 'Isha', time: ''),
    ], DateTime(2026, 10, 13, 5, 30));
    expect(result!.prayer.name, 'Dhuhr');
    expect(result.at, DateTime(2026, 10, 13, 13, 15));
  });
  test('after the last prayer rolls to tomorrow even at month boundaries', () {
    final result = nextPrayer([
      PrayerTime(name: 'Fajr', time: '5:15 AM'),
      PrayerTime(name: 'Isha', time: '8:00 PM'),
    ], DateTime(2026, 10, 31, 23));
    expect(result!.at, DateTime(2026, 11, 1, 5, 15));
  });
}
