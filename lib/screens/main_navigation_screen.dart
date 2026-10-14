import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../widgets/app_icon.dart';
import 'community_page.dart';
import 'prayer_page.dart';
import 'questions_page.dart';
import 'settings_page.dart';

/// Main Navigation Shell with Bottom Navigation Bar
/// Contains 4 tabs: Prayer Times, Community Events, Questions, Settings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // The 4 pages
  late final List<Widget> _pages = [
    const PrayerPage(),
    const CommunityPage(),
    const QuestionsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appLocalization,
    builder: (context, _) => _buildLocalized(context),
  );

  Widget _buildLocalized(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const AppIcon('prayer'),
            label: appLocalization.t(AppStrings.time),
          ),
          NavigationDestination(
            icon: const AppIcon('events'),
            label: appLocalization.t('events_nav'),
          ),
          NavigationDestination(
            icon: const AppIcon('community'),
            label: appLocalization.t(AppStrings.community),
          ),
          NavigationDestination(
            icon: const AppIcon('settings'),
            label: appLocalization.t(AppStrings.settings),
          ),
        ],
      ),
    );
  }
}
