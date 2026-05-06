import 'package:shared_preferences/shared_preferences.dart';

/// Service class for local storage using shared_preferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _preferences;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  /// Initialize shared preferences
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Save selected masjid ID
  Future<bool> saveSelectedMasjidId(String masjidId) async {
    return await _preferences.setString('selectedMasjidId', masjidId);
  }

  /// Get selected masjid ID
  String? getSelectedMasjidId() {
    return _preferences.getString('selectedMasjidId');
  }

  /// Clear selected masjid ID
  Future<bool> clearSelectedMasjidId() async {
    return await _preferences.remove('selectedMasjidId');
  }

  /// Save admin login status
  Future<bool> saveAdminLoginStatus(String masjidId, String username) async {
    await _preferences.setString('adminMasjidId', masjidId);
    await _preferences.setString('adminUsername', username);
    return await _preferences.setString('lastAdminLogin', DateTime.now().toString());
  }

  /// Get admin login status
  Map<String, String?>? getAdminLoginStatus() {
    final masjidId = _preferences.getString('adminMasjidId');
    final username = _preferences.getString('adminUsername');
    final lastLogin = _preferences.getString('lastAdminLogin');

    if (masjidId != null && username != null) {
      return {
        'masjidId': masjidId,
        'username': username,
        'lastLogin': lastLogin,
      };
    }
    return null;
  }

  /// Clear admin login status
  Future<bool> clearAdminLoginStatus() async {
    await _preferences.remove('adminMasjidId');
    await _preferences.remove('adminUsername');
    await _preferences.remove('lastAdminLogin');
    return true;
  }

  /// Save app language preference
  Future<bool> saveLanguage(String language) async {
    return await _preferences.setString('language', language);
  }

  /// Get app language preference
  String? getLanguage() {
    return _preferences.getString('language') ?? 'en';
  }

  /// Save theme preference
  Future<bool> saveTheme(String theme) async {
    return await _preferences.setString('theme', theme);
  }

  /// Get theme preference
  String? getTheme() {
    return _preferences.getString('theme') ?? 'light';
  }

  /// Clear all data
  Future<bool> clearAll() async {
    return await _preferences.clear();
  }
}
