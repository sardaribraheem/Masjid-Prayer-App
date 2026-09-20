import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Prayer Times Page - Shows prayer times for selected masjid
/// Part of bottom navigation bar
class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masjidProvider = context.watch<MasjidProvider>();
    final masjid = masjidProvider.selectedMasjid ?? AppData.selectedMasjid;

    if (masjid == null || masjid.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalization.t(AppStrings.error))),
        body: Center(child: Text(appLocalization.t(AppStrings.noMasjidSelected))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          masjid.name,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAF7F2),
          ),
        ),
        elevation: 0,
        backgroundColor: ColorPalette.primary,
      ),
      body: StreamBuilder<Masjid?>(
        stream: _firebaseService.getMasjidStream(masjid.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorPalette.primary,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: ColorPalette.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLocalization.t(AppStrings.errorOccurred),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final currentMasjid = snapshot.data ?? masjid;
          AppData.selectedMasjid = currentMasjid;

          final allPrayers = _getAllPrayersWithJummah(currentMasjid);
          final nextPrayerIndex = _getNextPrayerIndex(allPrayers);
          final nextPrayer = nextPrayerIndex >= 0
              ? allPrayers[nextPrayerIndex]
              : allPrayers[0];

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                ],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpcomingPrayerCard(
                      nextPrayer,
                      currentMasjid,
                      nextPrayerIndex,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        bottom: 16.0,
                      ),
                      child: Text(
                        appLocalization.t(AppStrings.allPrayers),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primary,
                        ),
                      ),
                    ),
                    _buildPrayersList(
                      allPrayers,
                      currentMasjid,
                      nextPrayerIndex,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingPrayerCard(
    _PrayerDisplay prayer,
    Masjid masjid,
    int prayerIndex,
  ) {
    final gradientColors = _getPrayerGradientColors(prayer.name);
    final timeRemaining = _calculateTimeRemaining(prayer.time);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalization.t(AppStrings.nextPrayer),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prayer.name,
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _getPrayerIcon(prayer.name, size: 60),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prayer.time,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  timeRemaining,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayersList(
    List<_PrayerDisplay> prayers,
    Masjid masjid,
    int nextPrayerIndex,
  ) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: prayers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final isNext = index == nextPrayerIndex;
        return _buildPrayerCard(prayer, masjid, index, isNext);
      },
    );
  }

  Widget _buildPrayerCard(
    _PrayerDisplay prayer,
    Masjid masjid,
    int index,
    bool isNext,
  ) {
    final cardColor = isNext
        ? ColorPalette.primary.withValues(alpha: 0.08)
        : const Color.fromRGBO(255, 255, 255, 1).withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isNext
            ? Border.all(color: ColorPalette.secondary, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _getPrayerIcon(prayer.name, size: 32),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appLocalization.t(AppStrings.updated)} ${_getLastUpdatedText(masjid.lastUpdated)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    prayer.time,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isNext
                          ? ColorPalette.secondary
                          : ColorPalette.primary,
                    ),
                  ),
                  if (isNext)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorPalette.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appLocalization.t(AppStrings.next),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPrayerIcon(String prayerName, {double size = 32}) {
    IconData icon;
    Color color;

    switch (prayerName.toLowerCase()) {
      case 'fajr':
        icon = Icons.light_mode_rounded;
        color = const Color(0xFFFFA500);
        break;
      case 'dhuhr':
        icon = Icons.wb_sunny;
        color = const Color(0xFFFFD700);
        break;
      case 'asr':
        icon = Icons.wb_twilight_rounded;
        color = const Color(0xFFFF8C00);
        break;
      case 'maghrib':
        icon = Icons.wb_sunny_rounded;
        color = const Color(0xFFFF6347);
        break;
      case 'isha':
        icon = Icons.dark_mode_rounded;
        color = const Color(0xFF1C1C7E);
        break;
      case 'jummah':
        icon = Icons.mosque;
        color = ColorPalette.secondary;
        break;
      default:
        icon = Icons.access_time_rounded;
        color = ColorPalette.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  List<Color> _getPrayerGradientColors(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return [const Color(0xFFFF9A56), const Color(0xFFFF6B9D)];
      case 'dhuhr':
        return [const Color(0xFF87CEEB), const Color(0xFF87CEFA)];
      case 'asr':
        return [const Color(0xFFFFB347), const Color(0xFFFF8C00)];
      case 'maghrib':
        return [const Color(0xFFFF7F50), const Color(0xFFDC143C)];
      case 'isha':
        return [const Color(0xFF191970), const Color(0xFF000080)];
      case 'jummah':
        return [ColorPalette.secondary, const Color(0xFF8B7355)];
      default:
        return [
          ColorPalette.primary,
          ColorPalette.primary.withValues(alpha: 0.5),
        ];
    }
  }

  String _calculateTimeRemaining(String prayerTime) {
    try {
      final now = DateTime.now();
      final prayerMinutes = _convertTimeToMinutes(prayerTime);
      final nowMinutes = now.hour * 60 + now.minute;
      var diffMinutes = prayerMinutes - nowMinutes;
      if (diffMinutes < 0) {
        diffMinutes = (24 * 60) + diffMinutes;
      }
      final hours = diffMinutes ~/ 60;
      final minutes = diffMinutes % 60;
      if (hours == 0) {
        // Under an hour: "50 minutes remaining" (singular/plural, no padding).
        final key = minutes == 1
            ? AppStrings.minuteRemaining
            : AppStrings.minutesRemaining;
        return '$minutes ${appLocalization.t(key)}';
      } else {
        // Whole hours, rounded down: "2:30" → "2 hours remaining".
        final key =
            hours == 1 ? AppStrings.hourRemaining : AppStrings.hoursRemaining;
        return '$hours ${appLocalization.t(key)}';
      }
    } catch (e) {
      return appLocalization.t(AppStrings.errorOccurred);
    }
  }

  String _getLastUpdatedText(DateTime? lastUpdated) {
    if (lastUpdated == null) return appLocalization.t(AppStrings.justNow);
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    if (difference.inSeconds < 60) {
      return appLocalization.t(AppStrings.justNow);
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${appLocalization.t(AppStrings.minutesAgo)}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${appLocalization.t(AppStrings.hoursAgo)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${appLocalization.t(AppStrings.daysAgo)}';
    } else {
      final weeks = (difference.inDays / 7).toStringAsFixed(0);
      return '$weeks${appLocalization.t(AppStrings.weeksAgo)}';
    }
  }

  List<_PrayerDisplay> _getAllPrayersWithJummah(Masjid masjid) {
    final prayers = <_PrayerDisplay>[];
    for (final prayer in masjid.prayerTimes) {
      prayers.add(_PrayerDisplay(name: prayer.name, time: prayer.time));
    }
    if (masjid.jummahTime != null && masjid.jummahTime!.isNotEmpty) {
      prayers.add(_PrayerDisplay(name: 'Jummah', time: masjid.jummahTime!));
    }
    return prayers;
  }

  int _getNextPrayerIndex(List<_PrayerDisplay> prayers) {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = _convertTimeToMinutes(prayers[i].time);
      if (prayerTime >= currentTimeInMinutes) {
        return i;
      }
    }
    return 0;
  }

  int _convertTimeToMinutes(String timeString) {
    try {
      final parts = timeString.replaceAll(RegExp(r'\s'), '').split(':');
      var hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1].replaceAll(RegExp(r'[AP]M'), ''));
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
}

class _PrayerDisplay {
  final String name;
  final String time;

  _PrayerDisplay({required this.name, required this.time});
}
