import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'providers/masjid_claim_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Enable semantics tree so Playwright/accessibility tools can interact with
  // the Flutter web CanvasKit renderer (which hides the DOM by default).
  binding.ensureSemantics();

  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize localization
  await appLocalization.initialize();

  // Initialize services
  final storageService = StorageService();
  await storageService.initialize();
  appStateProvider.setDarkMode(storageService.getTheme() == 'dark');

  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // NO anonymous sign-in: a signed-out user is a guest who can read public
  // data (masjids) and must register/login as a Muqtaddi to write
  // (`latesttodo.md` §1, §2). Auth state is handled by AuthProvider.

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
                ChangeNotifierProvider(create: (_) => MasjidClaimProvider()),
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
