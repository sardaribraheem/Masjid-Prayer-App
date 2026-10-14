import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_state.dart';
import '../l10n/app_localization.dart';

/// Provides persisted settings state (dark mode, language, notifications).
/// Wraps StorageService and appStateProvider/appLocalization in a reactive provider.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _locale = 'en';

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get locale => _locale;

  SettingsProvider() {
    // Startup restores global preferences before the widget tree is built.
    // Reading them here must not notify ancestors during a build.
    _isDarkMode = appStateProvider.isDarkMode;
    _locale = appLocalization.locale;
  }

  /// Toggle dark mode and persist
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    appStateProvider.setDarkMode(_isDarkMode);
    await _storageService.saveTheme(_isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }

  /// Toggle notifications and persist
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _storageService.saveNotificationsEnabled(_notificationsEnabled);
    notifyListeners();
  }

  /// Set language and persist
  Future<void> setLanguage(String locale) async {
    if (locale == _locale) return;
    _locale = locale;
    await appLocalization.setLanguage(locale);
    await _storageService.saveLanguage(locale);
    notifyListeners();
  }
}
