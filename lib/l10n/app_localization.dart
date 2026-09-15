import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

/// Global app localization provider
/// Manages current language and provides translations throughout the app
class AppLocalization extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _currentLocale = 'en';
  late AppTranslations _translations;

  AppLocalization() {
    _translations = AppTranslations(locale: _currentLocale);
  }

  /// Get current locale
  String get locale => _currentLocale;

  /// Get translations object
  AppTranslations get translations => _translations;

  /// Get a translated string
  String t(String key) => _translations.t(key);

  /// Check if current language is RTL
  bool get isRTL => _translations.isRTL;

  /// Initialize localization from shared preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'en';
      await setLanguage(savedLanguage);
    } catch (e) {
      // Default to English if error
      setLanguage('en');
    }
  }

  /// Change app language
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ur') {
      return; // Invalid language code
    }

    _currentLocale = languageCode;
    _translations = AppTranslations(locale: languageCode);

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // Preference save failed, but language still changed in memory
    }

    notifyListeners();
  }

  /// Toggle between English and Urdu
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale == 'en' ? 'ur' : 'en';
    await setLanguage(newLanguage);
  }
}

/// Global instance for accessing localization anywhere
final appLocalization = AppLocalization();
