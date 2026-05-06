import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'ask_question_screen.dart';
import 'masjid_selection_screen.dart';

/// This screen shows the prayer times for the selected masjid
/// Updates in real-time when admins make changes, with beautiful Islamic design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();

  // Islamic Design Color Palette - Moved to ColorPalette class
  // Using ColorPalette constants instead of local hardcoded colors

  @override
  Widget build(BuildContext context) {
    // Get the selected masjid from our app data
    final masjid = AppData.selectedMasjid;

    if (masjid == null || masjid.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalization.t(AppStrings.error))),
        body: Center(
          child: Text(appLocalization.t(AppStrings.noMasjidSelected)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          masjid.name,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ColorPalette.lightText,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  _storageService.clearSelectedMasjidId();
                  AppData.selectedMasjid = null;
                  AppData.selectedMasjidId = null;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MasjidSelectionScreen(),
                    ),
                  );
                },
                child: Text(
                  appLocalization.t(AppStrings.changeButton),
                  style: GoogleFonts.poppins(
                    color: ColorPalette.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Masjid?>(
        stream: _firebaseService.getMasjidStream(masjid.id),
        builder: (context, snapshot) {
          // Show loading state initially
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorPalette.lightCardBg,
                    ColorPalette.lightCardBg.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorPalette.primary,
                  ),
                ),
              ),
            );
          }

          // Handle errors
          if (snapshot.hasError) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorPalette.lightCardBg,
                    ColorPalette.lightCardBg.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: ColorPalette.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLocalization.t(AppStrings.errorLoadingPrayerTimes),
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

          // Get the masjid data from stream or use cached data
          final currentMasjid = snapshot.data ?? masjid;
          AppData.selectedMasjid = currentMasjid;

          // Get all prayers including Jummah
          final allPrayers = _getAllPrayersWithJummah(currentMasjid);

          // Find the next upcoming prayer
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
                  ColorPalette.lightCardBg,
                  ColorPalette.lightCardBg.withValues(alpha: 0.92),
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
                    // Location Info Card
                    _buildLocationCard(currentMasjid),
                    const SizedBox(height: 28),

                    // Featured Upcoming Prayer Card
                    _buildUpcomingPrayerCard(
                      nextPrayer,
                      currentMasjid,
                      nextPrayerIndex,
                    ),
                    const SizedBox(height: 32),

                    // Remaining Prayers Section Title
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        appLocalization.t(AppStrings.allPrayers),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primary,
                        ),
                      ),
                    ),

                    // All Prayer Cards
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
      floatingActionButton: _buildAskQuestionButton(),
    );
  }

  /// Floating Action Button for Ask Question Screen
  FloatingActionButton _buildAskQuestionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AskQuestionScreen()),
        );
      },
      backgroundColor: Colors.blue[700],
      tooltip: 'Ask Imam',
      child: const Icon(Icons.help_outline, color: Colors.white),
    );
  }

  /// Build location information card
  Widget _buildLocationCard(Masjid masjid) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: ColorPalette.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      masjid.location,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLastUpdatedText(masjid.lastUpdated),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main featured upcoming prayer card
  Widget _buildUpcomingPrayerCard(
    _PrayerDisplay prayer,
    Masjid masjid,
    int prayerIndex,
  ) {
    // Determine gradient colors based on prayer time
    final gradientColors = _getPrayerGradientColors(prayer.name);

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
                            'Next Prayer',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
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
                    color: Colors.white.withOpacity(0.25),
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
                  'Updated ${_getLastUpdatedText(masjid.lastUpdated)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build list of all prayers in smaller cards
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

  /// Build individual prayer time card
  Widget _buildPrayerCard(
    _PrayerDisplay prayer,
    Masjid masjid,
    int index,
    bool isNext,
  ) {
    final cardColor = isNext
        ? ColorPalette.primary.withValues(alpha: 0.08)
        : const Color.fromRGBO(255, 255, 255, 1).withOpacity(0.7);

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
                        'Updated ${_getLastUpdatedText(masjid.lastUpdated)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
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
                        'Next',
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

  /// Get icon for prayer based on prayer name
  Widget _getPrayerIcon(String prayerName, {double size = 32}) {
    IconData icon;
    Color color;

    switch (prayerName.toLowerCase()) {
      case 'fajr':
        icon = Icons.light_mode_rounded;
        color = const Color(0xFFFFA500);
        break;
      case 'dhuhr':
        icon = Icons.sunny_snowing;
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  /// Get gradient colors based on prayer timings
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
          ColorPalette.primary.withValues(alpha: 0.7),
        ];
    }
  }

  /// Get last updated text
  String _getLastUpdatedText(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'just now';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).toStringAsFixed(0)}w ago';
    }
  }

  /// Get all prayers including Jummah as a prayer object
  List<_PrayerDisplay> _getAllPrayersWithJummah(Masjid masjid) {
    final prayers = <_PrayerDisplay>[];

    // Add all 5 daily prayers
    for (final prayer in masjid.prayerTimes) {
      prayers.add(_PrayerDisplay(name: prayer.name, time: prayer.time));
    }

    // Add Jummah as part of the prayers
    if (masjid.jummahTime != null && masjid.jummahTime!.isNotEmpty) {
      prayers.add(_PrayerDisplay(name: 'Jummah', time: masjid.jummahTime!));
    }

    return prayers;
  }

  /// Determine which prayer is next based on current time
  int _getNextPrayerIndex(List<_PrayerDisplay> prayers) {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    // Convert prayer times to minutes for comparison
    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = _convertTimeToMinutes(prayers[i].time);
      if (prayerTime >= currentTimeInMinutes) {
        return i;
      }
    }

    // If no prayer found today, first prayer is tomorrow (Fajr usually)
    return 0;
  }

  /// Convert time string like "5:30 AM" to minutes since midnight
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

/// Helper class to display prayer information
class _PrayerDisplay {
  final String name;
  final String time;

  _PrayerDisplay({required this.name, required this.time});
}
