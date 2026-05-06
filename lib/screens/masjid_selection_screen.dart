import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'main_navigation_screen.dart';

/// Screen for location-based masjid selection with distance sorting
class MasjidSelectionScreen extends StatefulWidget {
  const MasjidSelectionScreen({super.key});

  @override
  State<MasjidSelectionScreen> createState() => _MasjidSelectionScreenState();
}

class _MasjidSelectionScreenState extends State<MasjidSelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  // Islamic Design Colors
  static const Color deepEmerald = Color(0xFF1B5E47);
  static const Color softCream = Color(0xFFFAF7F2);
  static const Color brushGold = Color(0xFFD4A574);

  Position? _userPosition;
  List<Masjid> _allMasjids = [];
  List<Masjid> _filteredMasjids = [];
  bool _isLoadingLocation = false;
  bool _isLoadingMasjids = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMasjids();
    _searchController.addListener(_filterMasjids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize location and fetch nearby masjids
  Future<void> _initializeLocationAndMasjids() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Request location permission
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = appLocalization.t(
            AppStrings.locationPermissionRequired,
          );
          _isLoadingLocation = false;
        });
        return;
      }

      // Get user location
      final position = await _locationService.getUserLocation();
      if (position == null) {
        setState(() {
          _errorMessage = appLocalization.t(AppStrings.unableToGetYourLocation);
          _isLoadingLocation = false;
        });
        return;
      }

      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
        _isLoadingMasjids = true;
      });

      // Fetch masjids sorted by distance
      final masjids = await _firebaseService.getMasjidsSortedByDistance(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _allMasjids = masjids;
        _filteredMasjids = masjids;
        _isLoadingMasjids = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            '${appLocalization.t(AppStrings.errorOccurredMsg)}: ${e.toString()}';
        _isLoadingLocation = false;
        _isLoadingMasjids = false;
      });
    }
  }

  /// Filter masjids based on search query
  void _filterMasjids() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredMasjids = _allMasjids;
      });
    } else {
      setState(() {
        _filteredMasjids = _allMasjids
            .where(
              (masjid) =>
                  masjid.name.toLowerCase().contains(query) ||
                  masjid.location.toLowerCase().contains(query),
            )
            .toList();
      });
    }
  }

  /// Handle masjid selection
  Future<void> _selectMasjid(Masjid masjid) async {
    // Save selection locally
    await _storageService.saveSelectedMasjidId(masjid.id);

    // Update app data
    AppData.selectedMasjid = masjid;
    AppData.selectedMasjidId = masjid.id;

    // Navigate to main navigation (bottom nav bar)
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalization.t(AppStrings.findNearbyMasjid),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: softCream,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softCream, softCream.withOpacity(0.92)],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),

            // Location Status
            if (_userPosition == null && _isLoadingLocation)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildLocationLoadingWidget(),
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildErrorWidget(),
              ),

            // Masjid List or Loading
            Expanded(
              child: _isLoadingMasjids
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(deepEmerald),
                      ),
                    )
                  : _filteredMasjids.isEmpty
                  ? _buildEmptyStateWidget()
                  : _buildMasjidsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.admin_panel_settings),
        label: Text(appLocalization.t(AppStrings.adminImmam)),
        backgroundColor: ColorPalette.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          );
        },
      ),
    );
  }

  /// Build search bar widget
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: deepEmerald.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          hintText: appLocalization.t(AppStrings.searchMasjidByName),
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade500
                : Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: brushGold,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: Icon(
                    Icons.clear,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade500
                        : Colors.grey.shade400,
                  ),
                )
              : null,
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? ColorPalette.darkCardBg
              : Colors.white,
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
            borderSide: BorderSide(color: brushGold, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  /// Build location loading widget
  Widget _buildLocationLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brushGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brushGold, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(brushGold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            appLocalization.t(AppStrings.gettingYourLocation),
            style: GoogleFonts.poppins(
              color: deepEmerald,
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
        color: Colors.red.withOpacity(0.1),
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
                  _errorMessage ??
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
              style: ElevatedButton.styleFrom(backgroundColor: deepEmerald),
              child: Text(
                appLocalization.t(AppStrings.retryButton),
                style: GoogleFonts.poppins(color: Colors.white),
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
          Icon(Icons.location_off_rounded, size: 60, color: brushGold),
          const SizedBox(height: 16),
          Text(
            appLocalization.t(AppStrings.noMasjidsFound),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: deepEmerald,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.t(AppStrings.tryAdjustingYourSearch),
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build masjids list
  Widget _buildMasjidsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredMasjids.length,
      itemBuilder: (context, index) {
        final masjid = _filteredMasjids[index];
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
              color: deepEmerald.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.9),
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
                                color: deepEmerald,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: brushGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  masjid.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
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
                          color: brushGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.near_me, size: 14, color: brushGold),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(masjid.distanceFromUser),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: brushGold,
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
                        color: deepEmerald.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${appLocalization.t(AppStrings.nextPrayerPreview)} ${masjid.prayerTimes.isNotEmpty ? masjid.prayerTimes[0].name : appLocalization.t(AppStrings.unknown)} at ${masjid.prayerTimes.isNotEmpty ? masjid.prayerTimes[0].time : appLocalization.t(AppStrings.unknown)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: deepEmerald.withOpacity(0.7),
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
                          color: softCream,
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
