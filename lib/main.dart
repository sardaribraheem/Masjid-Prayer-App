import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'models/app_data.dart';
import 'screens/masjid_selection_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_state.dart';
import 'l10n/app_localization.dart';
import 'providers/question_provider.dart';
import 'providers/event_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/masjid_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await appLocalization.initialize();

  // Initialize services
  final storageService = StorageService();
  await storageService.initialize();

  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Initialize app data with fallback data (debug only — production reads from Firestore)
  if (kDebugMode) {
    AppData.initialize();
    // Initialize users
    AppData.initializeUsers();

    // Try to initialize Firebase sample data
    try {
      await firebaseService.initializeSampleData();
    } catch (e) {
      // Handle initialization error silently
    }
  }

  // Check if a masjid was previously selected
  final selectedId = storageService.getSelectedMasjidId();
  bool hasSelectedMasjid = false;

  if (selectedId != null) {
    AppData.selectedMasjidId = selectedId;
    // Try to fetch the selected masjid
    try {
      final masjid = await firebaseService.getMasjidById(selectedId);
      if (masjid != null) {
        AppData.selectedMasjid = masjid;
        hasSelectedMasjid = true;
      }
    } catch (e) {
      // Handle error silently
    }
  }

  runApp(MyApp(startWithHome: hasSelectedMasjid));
}

/// Main app widget - this is where the app starts
class MyApp extends StatelessWidget {
  final bool startWithHome;

  const MyApp({super.key, this.startWithHome = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStateProvider,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: appLocalization,
          builder: (context, locChild) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => AuthProvider()),
                ChangeNotifierProvider(create: (_) => QuestionProvider()),
                ChangeNotifierProvider(create: (_) => EventProvider()),
                ChangeNotifierProvider(create: (_) => MasjidProvider()),
                ChangeNotifierProvider(create: (_) => LocationProvider()),
                ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ],
              child: MaterialApp(
                title: 'Masjid Prayer App',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: appStateProvider.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                // RTL support for Urdu
                builder: (context, child) {
                  return Directionality(
                    textDirection: appLocalization.isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },
                home: startWithHome
                    ? const MainNavigationScreen()
                    : const MasjidSelectionScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
