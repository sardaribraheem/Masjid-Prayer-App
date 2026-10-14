import '../models/prayer_reminder.dart';

abstract class PrayerReminderStore {
  PrayerReminderPreferences loadPrayerReminders();
  Future<void> savePrayerReminders(PrayerReminderPreferences preferences);
}
