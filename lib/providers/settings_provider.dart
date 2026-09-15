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
    _loadSettings();
  }

  /// Load saved settings from local storage
  Future<void> _loadSettings() async {
    final theme = _storageService.getTheme();
    _isDarkMode = theme == 'dark';
    _locale = _storageService.getLanguage() ?? 'en';

    // Sync with the existing appStateProvider
    if (appStateProvider.isDarkMode != _isDarkMode) {
      appStateProvider.toggleDarkMode();
    }

    notifyListeners();
  }

  /// Toggle dark mode and persist
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    appStateProvider.toggleDarkMode();
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
