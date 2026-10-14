import 'package:flutter/material.dart';

/// Global app state notifier for theme and other settings
class AppStateProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}

/// Global instance
final appStateProvider = AppStateProvider();
