import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../providers/location_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

/// Screen for location-based masjid selection with distance sorting
class MasjidSelectionScreen extends StatefulWidget {
  const MasjidSelectionScreen({super.key});

  @override
  State<MasjidSelectionScreen> createState() => _MasjidSelectionScreenState();
}

class _MasjidSelectionScreenState extends State<MasjidSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Defer past the first frame: requestLocation() notifies synchronously,
    // which would otherwise trigger "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeLocationAndMasjids();
    });
  }

  /// Initialize location and fetch nearby masjids
  Future<void> _initializeLocationAndMasjids() async {
    final locationProvider = context.read<LocationProvider>();
    final masjidProvider = context.read<MasjidProvider>();

    // Try to get location first
    final hasLocation = await locationProvider.requestLocation();

    if (hasLocation) {
      await masjidProvider.loadMasjidsWithLocation(
        locationProvider.latitude!,
        locationProvider.longitude!,
      );
    } else {
      await masjidProvider.loadMasjids();
    }
  }

  /// Handle masjid selection
  Future<void> _selectMasjid(Masjid masjid) async {
    final masjidProvider = context.read<MasjidProvider>();
    await masjidProvider.selectMasjid(masjid);

    // Navigate to main navigation
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  /// Format distance display
  String _formatDistance(double? distance) {
    if (distance == null) return appLocalization.t(AppStrings.unknown);
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final masjidProvider = context.watch<MasjidProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalization.t(AppStrings.findNearbyMasjid),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ColorPalette.lightBg,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(masjidProvider),
            ),

            // Location Status
            if (locationProvider.isLoading || (masjidProvider.isLoading && masjidProvider.allMasjids.isEmpty))
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildLocationLoadingWidget(),
              ),

            if (masjidProvider.error != null && masjidProvider.allMasjids.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildErrorWidget(),
              ),

            // Masjid List or Loading
            Expanded(
              child: masjidProvider.isLoading && masjidProvider.allMasjids.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorPalette.primary,
                        ),
                      ),
                    )
                  : masjidProvider.filteredMasjids.isEmpty
                      ? _buildEmptyStateWidget()
                      : RefreshIndicator(
                          onRefresh: _initializeLocationAndMasjids,
                          child: _buildMasjidsList(masjidProvider),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search bar widget
  Widget _buildSearchBar(MasjidProvider provider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => provider.searchQuery = value,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          hintText: appLocalization.t(AppStrings.searchMasjidByName),
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4A574)),
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
          ),
        ),
      ),
    );
  }

  /// Build location loading widget
  Widget _buildLocationLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A574).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A574), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A574)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            appLocalization.t(AppStrings.gettingYourLocation),
            style: GoogleFonts.poppins(
              color: ColorPalette.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.watch<MasjidProvider>().error ??
                      appLocalization.t(AppStrings.errorOccurredMsg),
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _initializeLocationAndMasjids,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
              ),
              child: Text(
                appLocalization.t(AppStrings.retryButton),
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 60,
            color: const Color(0xFFD4A574),
          ),
          const SizedBox(height: 16),
          Text(
            appLocalization.t(AppStrings.noMasjidsFound),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.t(AppStrings.tryAdjustingYourSearch),
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Build masjids list
  Widget _buildMasjidsList(MasjidProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.filteredMasjids.length,
      itemBuilder: (context, index) {
        final masjid = provider.filteredMasjids[index];
        return _buildMasjidCard(masjid);
      },
    );
  }

  /// Build individual masjid card
  Widget _buildMasjidCard(Masjid masjid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => _selectMasjid(masjid),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Masjid Name and Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              masjid.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Color(0xFFD4A574),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  masjid.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Distance Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.near_me,
                              size: 14,
                              color: Color(0xFFD4A574),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(masjid.distanceFromUser),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD4A574),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Prayer Times Preview
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: ColorPalette.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${appLocalization.t(AppStrings.nextPrayerPreview)} ${masjid.prayerTimes.isNotEmpty ? masjid.prayerTimes[0].name : appLocalization.t(AppStrings.unknown)} at ${masjid.prayerTimes.isNotEmpty ? masjid.prayerTimes[0].time : appLocalization.t(AppStrings.unknown)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ColorPalette.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Select Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectMasjid(masjid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        appLocalization.t(AppStrings.selectThisMasjid),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFAF7F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
