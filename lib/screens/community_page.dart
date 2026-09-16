import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/event_provider.dart';
import '../widgets/event_search_bar.dart';
import '../widgets/category_slider.dart';
import '../widgets/enhanced_event_card.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Community Page - Shows events from masjids with search and category filtering
class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _filterType = 'upcoming'; // 'upcoming', 'nearby', 'all'
  String _selectedCategory = 'all'; // Category filter
  String _searchQuery = ''; // Search query

  StreamSubscription<List<Event>>? _eventSub;

  @override
  void initState() {
    super.initState();
    // Defer past the first frame: loadEvents()/subscribeToEvents() notify
    // synchronously, which would otherwise trigger "setState() called during
    // build". Subscribing here (not in build) also avoids creating a new
    // Firestore listener on every rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadEvents();
      final masjidId = AppData.selectedMasjid?.id ?? '';
      if (masjidId.isNotEmpty) {
        _eventSub = context.read<EventProvider>().subscribeToEvents(masjidId);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      await context.read<EventProvider>().loadEvents(masjidId);
    }
  }

  /// Get category definitions with localized labels
  List<CategoryItem> _getCategories() {
    return [
      CategoryItem(id: 'all', label: appLocalization.t(AppStrings.allCategories), icon: Icons.apps),
      CategoryItem(id: 'Taleem', label: appLocalization.t(AppStrings.taleem), icon: Icons.school),
      CategoryItem(id: 'Dars', label: appLocalization.t(AppStrings.dars), icon: Icons.book),
      CategoryItem(
        id: 'Tablighi Jamaat',
        label: appLocalization.t(AppStrings.tabblighi),
        icon: Icons.group,
      ),
      CategoryItem(id: 'Gasht', label: appLocalization.t(AppStrings.gasht), icon: Icons.directions_walk),
    ];
  }

  List<Event> _getFilteredEvents() {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    final provider = context.watch<EventProvider>();
    List<Event> events = provider.getEventsByMasjid(masjidId);

    // Apply category filter
    if (_selectedCategory != 'all') {
      events = events
          .where(
            (event) =>
                event.category?.toLowerCase() ==
                _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      events = events.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.masjidName.toLowerCase().contains(query);
      }).toList();
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.communityEvents)),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          EventSearchBar(
            hintText: appLocalization.t(AppStrings.searchEvents),
            onSearchChanged: (query) {
              setState(() => _searchQuery = query);
            },
          ),

          // Category Slider
          CategorySlider(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
            },
            categories: _getCategories(),
          ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterButton(
                    label: appLocalization.t(AppStrings.upcoming),
                    isSelected: _filterType == 'upcoming',
                    onTap: () => setState(() => _filterType = 'upcoming'),
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(
                    label: appLocalization.t(AppStrings.nearby),
                    isSelected: _filterType == 'nearby',
                    onTap: () => setState(() => _filterType = 'nearby'),
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(
                    label: appLocalization.t(AppStrings.allEvents),
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                ],
              ),
            ),
          ),

          // Events List
          Expanded(
            child: context.watch<EventProvider>().isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                    ? EmptyState(
                        icon: Icons.event_outlined,
                        title: appLocalization.t(AppStrings.noEvents),
                        subtitle: appLocalization.t(AppStrings.eventsWillAppearHere),
                        actionLabel: appLocalization.t(AppStrings.refresh),
                        onAction: _loadEvents,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20, top: 8),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            return EnhancedEventCard(
                              event: filteredEvents[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Filter button widget
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
