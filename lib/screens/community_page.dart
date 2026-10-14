import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import 'admin_events_screen.dart';
import '../widgets/event_search_bar.dart';
import '../widgets/category_slider.dart';
import '../utils/prayer_schedule.dart';
import '../widgets/enhanced_event_card.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';

/// Community Page - Shows events from masjids with search and category filtering
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _filterType = 'upcoming'; // 'upcoming', 'nearby', 'all'
  String _selectedCategory = 'all'; // Category filter
  String _searchQuery = ''; // Search query

  StreamSubscription<List<Event>>? _eventSub;

  String? _listeningMasjidId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        (context.watch<MasjidProvider>().selectedMasjid ??
                AppData.selectedMasjid)
            ?.id;
    if (id != _listeningMasjidId) {
      _listeningMasjidId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && id == _listeningMasjidId) _loadEvents();
      });
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      _eventSub?.cancel();
      _eventSub = context.read<EventProvider>().subscribeToEvents(
        masjidId,
        upcomingOnly: _filterType == 'upcoming',
      );
    }
  }

  Future<void> _proposeEvent() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final masjid = AppData.selectedMasjid;
    if (user == null ||
        !user.canSubmitEvents ||
        masjid == null ||
        user.masjidId != masjid.id) {
      return;
    }
    final provider = context.read<EventProvider>();
    final result = await showEventProposalForm(
      context,
      onSubmit: (draft) async {
        if (auth.currentUser?.id != user.id) return false;
        return provider.addEvent(
          Event(
            id: '',
            title: draft.title,
            description: draft.description,
            masjidId: masjid.id,
            masjidName: masjid.name,
            eventDate: draft.eventDate,
            startTime: draft.startTime,
            endTime: draft.endTime,
            location: draft.location,
            category: draft.category,
            status: user.canPublishEventsDirectly
                ? EventStatus.approved
                : EventStatus.pending,
            createdByUid: user.id,
            createdByName: user.username,
          ),
        );
      },
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalization.t('event_proposal_submitted'))),
      );
    }
  }

  /// Get category definitions with localized labels
  List<CategoryItem> _getCategories() {
    return [
      CategoryItem(
        id: 'all',
        label: appLocalization.t(AppStrings.allCategories),
        icon: Icons.apps,
      ),
      CategoryItem(
        id: 'Taleem',
        label: appLocalization.t(AppStrings.taleem),
        icon: Icons.school,
      ),
      CategoryItem(
        id: 'Dars',
        label: appLocalization.t(AppStrings.dars),
        icon: Icons.book,
      ),
      CategoryItem(
        id: 'Jammat',
        label: appLocalization.t(AppStrings.jammat),
        icon: Icons.group,
      ),
      CategoryItem(
        id: 'Other',
        label: appLocalization.t('other'),
        icon: Icons.event_outlined,
      ),
      CategoryItem(
        id: 'Gasht',
        label: appLocalization.t(AppStrings.gasht),
        icon: Icons.directions_walk,
      ),
    ];
  }

  List<Event> _getFilteredEvents() {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    final provider = context.watch<EventProvider>();
    List<Event> events = provider.getApprovedEventsByMasjid(masjidId);

    if (_filterType == 'upcoming') {
      final now = DateTime.now();
      events = events.where((event) {
        final date = event.eventDate.toLocal();
        final minutes = parsePrayerMinutes(event.endTime) ?? 1439;
        final ends = DateTime(
          date.year,
          date.month,
          date.day,
          minutes ~/ 60,
          minutes % 60,
        );
        return ends.isAfter(now);
      }).toList();
    }
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appLocalization,
    builder: (context, _) => _buildLocalized(context),
  );

  Widget _buildLocalized(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.communityEvents)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: appLocalization.t(AppStrings.refresh),
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          context.watch<AuthProvider>().currentUser?.canSubmitEvents == true &&
              context.watch<AuthProvider>().currentUser?.masjidId ==
                  AppData.selectedMasjid?.id
          ? FloatingActionButton.extended(
              onPressed: _proposeEvent,
              icon: const Icon(Icons.add),
              label: Text(appLocalization.t('propose_event')),
            )
          : null,
      body: ListView(
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
                    onTap: () {
                      setState(() => _filterType = 'upcoming');
                      _loadEvents();
                    },
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(
                    label: appLocalization.t(AppStrings.allEvents),
                    isSelected: _filterType == 'all',
                    onTap: () {
                      setState(() => _filterType = 'all');
                      _loadEvents();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (context.watch<EventProvider>().isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (context.watch<EventProvider>().error != null)
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: appLocalization.t('feed_error'),
              actionLabel: appLocalization.t(AppStrings.refresh),
              onAction: _loadEvents,
            )
          else if (filteredEvents.isEmpty)
            EmptyState(
              icon: Icons.event_outlined,
              title: appLocalization.t(AppStrings.noEvents),
              subtitle: appLocalization.t(AppStrings.eventsWillAppearHere),
              actionLabel: appLocalization.t(AppStrings.refresh),
              onAction: _loadEvents,
            )
          else
            ...filteredEvents.map((event) => EnhancedEventCard(event: event)),
          if (context.watch<EventProvider>().hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: context.watch<EventProvider>().loadingMore
                    ? null
                    : context.read<EventProvider>().loadMore,
                child: Text(appLocalization.t('load_more')),
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
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (_) => onTap(),
    visualDensity: VisualDensity.standard,
  );
}
