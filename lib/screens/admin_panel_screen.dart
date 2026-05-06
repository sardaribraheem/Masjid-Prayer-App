import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_qa_screen.dart';
import 'masjid_selection_screen.dart';

/// Admin Panel - where admins can edit prayer times for their masjid
/// All changes are saved to Firestore in real-time
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // Prayer times stored as TimeOfDay objects for easy picking
  late List<TimeOfDay?> prayerTimes;
  late TimeOfDay? jummahTime;
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  String? successMessage;
  String? errorMessage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTimes();
  }

  /// Parse existing prayer times from strings to TimeOfDay objects
  void _initializeTimes() {
    final masjid = AppData.selectedMasjid;
    if (masjid != null) {
      // Parse each prayer time string to TimeOfDay
      prayerTimes = List.generate(
        masjid.prayerTimes.length,
        (index) => _parseTimeString(masjid.prayerTimes[index].time),
      );
      // Parse Jummah time
      jummahTime = _parseTimeString(masjid.jummahTime ?? '1:00 PM');
    } else {
      prayerTimes = [];
      jummahTime = null;
    }
  }

  /// Parse time string (e.g., '5:30 AM') to TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    try {
      timeStr = timeStr.trim();
      final parts = timeStr.split(':');
      if (parts.length != 2) return const TimeOfDay(hour: 12, minute: 0);

      int hour = int.parse(parts[0]);
      final minuteAndPeriod = parts[1].split(' ');
      if (minuteAndPeriod.isEmpty) return const TimeOfDay(hour: 12, minute: 0);

      int minute = int.parse(minuteAndPeriod[0]);
      final period = minuteAndPeriod.length > 1
          ? minuteAndPeriod[1].toUpperCase()
          : 'AM';

      // Convert 12-hour format to 24-hour
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  /// Convert TimeOfDay to display string (e.g., '5:30 AM')
  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(1, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  /// Validate time is within 24hrs format and not empty
  bool _isValidTime(TimeOfDay? time) {
    return time != null &&
        time.hour >= 0 &&
        time.hour < 24 &&
        time.minute >= 0 &&
        time.minute < 60;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Show TimePicker and update the selected time
  Future<void> _selectPrayerTime(int index) async {
    if (isSaving || prayerTimes[index] == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: prayerTimes[index]!,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              dialBackgroundColor: ColorPalette.primary.withOpacity(0.1),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != prayerTimes[index]) {
      setState(() {
        prayerTimes[index] = picked;
      });
    }
  }

  /// Show TimePicker for Jummah time
  Future<void> _selectJummahTime() async {
    if (isSaving || jummahTime == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: jummahTime!,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              dialBackgroundColor: ColorPalette.primary.withOpacity(0.1),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != jummahTime) {
      setState(() {
        jummahTime = picked;
      });
    }
  }

  /// Save the updated prayer times to Firestore
  Future<void> handleSave() async {
    final masjid = AppData.selectedMasjid;
    if (masjid == null || masjid.id.isEmpty) {
      setState(() {
        errorMessage = appLocalization.t(AppStrings.noMasjidSelected2);
      });
      return;
    }

    // Validate all times are set
    if (!prayerTimes.every(_isValidTime)) {
      setState(() {
        errorMessage = 'Please set all prayer times';
      });
      return;
    }

    if (!_isValidTime(jummahTime)) {
      setState(() {
        errorMessage = 'Please set Jummah time';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      // Update prayer times in local object with formatted strings
      for (int i = 0; i < masjid.prayerTimes.length; i++) {
        if (_isValidTime(prayerTimes[i])) {
          masjid.prayerTimes[i].time = _formatTimeOfDay(prayerTimes[i]);
        }
      }

      // Update Jummah time
      if (_isValidTime(jummahTime)) {
        masjid.jummahTime = _formatTimeOfDay(jummahTime);
      }
      masjid.lastUpdated = DateTime.now();

      // Save to Firestore
      final success = await _firebaseService.updatePrayerTimes(
        masjid.id,
        masjid.prayerTimes,
      );

      if (success) {
        // Also update Jummah time
        await _firebaseService.updateJummahTime(
          masjid.id,
          _formatTimeOfDay(jummahTime),
        );

        if (mounted) {
          setState(() {
            successMessage = appLocalization.t(
              AppStrings.prayerTimesUpdatedSuccessfully,
            );
          });

          // Hide the message after 3 seconds
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            setState(() {
              successMessage = null;
            });
          }
        }
      } else {
        setState(() {
          errorMessage = appLocalization.t(AppStrings.failedToSavePrayerTimes);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            '${appLocalization.t(AppStrings.errorSavingPrayerTimes)}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  /// Logout admin
  void handleLogout() {
    _storageService.clearAdminLoginStatus();
    AppData.selectedMasjid = null;
    AppData.selectedMasjidId = null;
    Navigator.pushReplacementNamed(
      context,
      MaterialPageRoute(
            builder: (_) => const MasjidSelectionScreen(),
          ).settings.name ??
          '/',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MasjidSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masjid = AppData.selectedMasjid;

    if (masjid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(appLocalization.t(AppStrings.noMasjidSelected2)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${masjid.name} - ${appLocalization.t(AppStrings.adminImmam)}',
        ),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
        actions: [
          // Logout button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextButton(
                onPressed: isSaving ? null : handleLogout,
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.primary.withOpacity(0.1),
                border: Border.all(color: ColorPalette.primary, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: ColorPalette.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appLocalization.t(AppStrings.editPrayerTimes),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    masjid.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    masjid.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prayer times editing section
            Expanded(
              child: ListView.builder(
                itemCount: masjid.prayerTimes.length + 1,
                itemBuilder: (context, index) {
                  // Last item is Jummah time
                  if (index == masjid.prayerTimes.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ColorPalette.secondary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: ColorPalette.secondary.withOpacity(0.05),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Prayer name
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'Jummah',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Prayer time picker button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isSaving
                                      ? null
                                      : _selectJummahTime,
                                  icon: const Icon(Icons.access_time),
                                  label: Text(
                                    _formatTimeOfDay(jummahTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPalette.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final prayer = masjid.prayerTimes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ColorPalette.primary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.darkCardBg
                            : Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Prayer name
                            SizedBox(
                              width: 80,
                              child: Text(
                                prayer.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Prayer time picker button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => _selectPrayerTime(index),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _formatTimeOfDay(prayerTimes[index]),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorPalette.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Success message
            if (successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.success.withOpacity(0.15),
                    border: Border.all(color: ColorPalette.success, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: ColorPalette.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: TextStyle(
                            color: ColorPalette.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.error.withOpacity(0.15),
                    border: Border.all(color: ColorPalette.error, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: ColorPalette.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: ColorPalette.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                // Q&A Management Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminQAScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(
                      Icons.question_answer,
                      color: Colors.white,
                    ),
                    label: Text(
                      appLocalization.t(AppStrings.qnaManagement),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Changes Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            appLocalization.t(AppStrings.savePrayerTimes),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
