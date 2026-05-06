import 'package:flutter/material.dart';

/// Global app state notifier for theme and other settings
class AppStateProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }
}

/// Global instance
final appStateProvider = AppStateProvider();
