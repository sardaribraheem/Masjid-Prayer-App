/// Shared time and date formatting utilities
/// Extracted from screens to eliminate duplication (was in questions_page.dart
/// and admin_qa_screen.dart)
class TimeUtils {
  /// Format a DateTime into a human-readable relative time string
  /// e.g., "Just now", "5m ago", "3h ago", "2d ago", "1/15"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// Format a DateTime into a short date string like "Mon, 5 Jan"
  static String formatShortDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  /// Convert a time string like "5:30 AM" to minutes since midnight
  static int convertTimeToMinutes(String timeString) {
    try {
      final parts = timeString.replaceAll(RegExp(r'\s'), '').split(':');
      if (parts.length < 2) return 0;
      var hours = int.parse(parts[0]);
      final minuteStr = parts[1].replaceAll(RegExp(r'[AP]M'), '');
      final minutes = int.parse(minuteStr);
      final isPM = timeString.toUpperCase().contains('PM');

      if (isPM && hours != 12) {
        hours += 12;
      } else if (!isPM && hours == 12) {
        hours = 0;
      }

      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }

  /// Parse a time string (e.g., '5:30 AM') to TimeOfDay hour and minute
  /// Returns [hour, minute] in 24-hour format
  static (int hour, int minute) parseTimeString(String timeStr) {
    try {
      timeStr = timeStr.trim();
      final parts = timeStr.split(':');
      if (parts.length != 2) return (12, 0);

      int hour = int.parse(parts[0]);
      final minuteAndPeriod = parts[1].split(' ');
      if (minuteAndPeriod.isEmpty) return (12, 0);

      int minute = int.parse(minuteAndPeriod[0]);
      final period = minuteAndPeriod.length > 1
          ? minuteAndPeriod[1].toUpperCase()
          : 'AM';

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return (hour, minute);
    } catch (e) {
      return (12, 0);
    }
  }

  /// Format hour and minute to display string like "5:30 AM"
  static String formatTimeOfDay(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(1, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get "last updated" text for prayer times
  static String getLastUpdatedText(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'just now';
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).toStringAsFixed(0)}w ago';
  }
}
