import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'community_page.dart';
import 'prayer_page.dart';
import 'questions_page.dart';
import 'settings_page.dart';

/// Main Navigation Shell with Bottom Navigation Bar
/// Contains 4 tabs: Prayer Times, Community Events, Questions, Settings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.schedule),
            label: appLocalization.t(AppStrings.prayerTimes),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event),
            label: appLocalization.t(AppStrings.community),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help_outline),
            label: appLocalization.t(AppStrings.questions),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: appLocalization.t(AppStrings.settings),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: ColorPalette.primary,
        unselectedItemColor: ColorPalette.lightTextSecondary,
        backgroundColor: ColorPalette.lightCardBg,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}
