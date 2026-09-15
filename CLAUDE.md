# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Masjid Prayer App — a Flutter app for mosque communities. Users select a nearby masjid, view prayer times, browse community events, post questions (answered by imams/admins), and manage settings with dark mode and English/Urdu localization (RTL support). Admins/imams can log in to manage prayer times, events, and answer questions.

**Dart SDK:** ^3.9.0 | **Backend:** Firebase Firestore | **Local storage:** shared_preferences

## Commands

```bash
# Run the app (Chrome for web, or connected device)
flutter run -d chrome
flutter run

# Build
flutter build web
flutter build apk
flutter build ios

# Analyze (no test suite present)
flutter analyze

# Format
dart format lib/

# Get dependencies
flutter pub get
```

No test suite exists in the project.

## Architecture

```
lib/
├── main.dart                    # Entry point, initializes services, routes to first screen
├── models/
│   └── app_data.dart            # All data models + global AppData singleton (static state)
├── screens/                     # UI screens
│   ├── masjid_selection_screen  # First screen: pick a masjid (sorted by distance)
│   ├── main_navigation_screen   # Bottom nav shell (4 tabs)
│   ├── prayer_page              # Tab 1: prayer times + countdown
│   ├── community_page           # Tab 2: community events
│   ├── questions_page           # Tab 3: Q&A list
│   ├── settings_page            # Tab 4: language, theme, profile
│   ├── admin_login_screen       # Imam/admin login
│   ├── admin_register_screen    # Register new masjid
│   ├── admin_panel_screen       # Dashboard to manage prayer times & events
│   ├── admin_qa_screen          # Answer user questions
│   └── ask_question_screen      # Post a question
├── services/
│   ├── firebase_service.dart    # Singleton — all Firestore CRUD operations
│   ├── storage_service.dart     # Singleton — local persistence via shared_preferences
│   └── location_service.dart    # GPS location (geolocator + location packages)
├── theme/
│   ├── app_theme.dart           # Light/dark ThemeData + ColorPalette constants
│   └── app_state.dart           # AppStateProvider (ChangeNotifier) for dark mode toggle
├── l10n/
│   ├── app_localization.dart    # Localization singleton (ListenableBuilder-compatible)
│   ├── app_strings.dart         # String key enum (AppStrings.xxx)
│   └── app_translations.dart    # EN/UR translation maps
└── widgets/
    ├── category_slider.dart     # Horizontal category filter chips
    ├── enhanced_event_card.dart # Event card with details
    └── event_search_bar.dart    # Search/filter bar for events
```

**Key architectural decisions:**

- **`AppData` (static singleton):** Global mutable state holder — `selectedMasjid`, `allMasjids`, `allQuestions`, `allEvents`, `currentUser`, `allUsers`. All data access is through static methods on this class. Not reactive — UI must manually rebuild.
- **`FirebaseService` / `StorageService`:** Singleton pattern (`factory` constructor returning a single `_instance`). Both initialized in `main()` before `runApp()`.
- **Role-based access:** `UserRole` enum (guest → verifiedUser → imam → admin) with permission getters on the `User` model. Imam and admin have most elevated permissions.
- **Localization:** Manual key-based system (not Flutter's built-in `l10n`). Use `appLocalization.t(AppStrings.someKey)` to get translated strings. RTL is toggled via `appLocalization.isRTL`.
- **Theming:** Colors defined as static constants in `ColorPalette`. Light/dark variants accessed as `ColorPalette.lightXxx` / `ColorPalette.darkXxx`. Theme toggle uses `AppStateProvider` (a `ChangeNotifier` exposed via global `appStateProvider` instance).

**Data flow pattern:**
1. `FirebaseService` fetches from Firestore → maps to `AppData` static fields
2. UI reads from `AppData` statics directly
3. Mutations go through `AppData` static methods (local) or `FirebaseService` (Firestore)
4. Real-time updates use `StreamBuilder` wrapping `FirebaseService.getMasjidStream()`

## Important Files

- `lib/models/app_data.dart` — All models (Masjid, PrayerTime, Question, Event, User) and the global AppData class. Read this first to understand the data layer.
- `lib/services/firebase_service.dart` — All Firestore operations. Hardcoded Firebase web config is in `initialize()` (line 25–31).
- `lib/screens/main_navigation_screen.dart` — The 4-tab bottom navigation shell.
- `lib/theme/app_theme.dart` — ColorPalette and ThemeData definitions.
- `ARCHITECTURE.md` — More detailed architecture documentation with diagrams.
