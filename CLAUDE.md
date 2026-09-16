# CLAUDE.md

Project guidance for Claude Code working in this repository.

## Project Overview

**Masjid Prayer App** — a Flutter app for the **Hassan Masjid** community (first real deployment target). Users select the masjid, view prayer times, browse community events, post questions (answered by imams/admins), request verification, and manage settings (dark mode, English/Urdu, RTL). Admins/imams manage prayer times, events, Q&A, and verification requests.

**Dart SDK:** ^3.9.0 | **Framework:** Flutter 3.44.x | **Backend:** Firebase (Auth + Firestore) | **Local state:** shared_preferences + ChangeNotifier/Provider

**Firebase project:** `masjid-prayer-app-49f50` (web config in `lib/firebase_options.dart`; Android via `google-services.json`).

> **Deployment principle (from `latesttodo.md`):** *Real User → Real Firebase → Real Data → Real Imam/Admin → Real Persistence.* Do NOT silently fall back to sample/local data when Firebase fails. Make Firebase errors visible during development. Do not keep adding features — the local MVP for Hassan Masjid must work first.

## Commands

```bash
flutter pub get
flutter analyze          # no test suite exists
dart format lib/
flutter run -d <device>  # or -d chrome for web
flutter build apk        # Android release
```

Firestore rules/indexes are deployed with:
```bash
firebase deploy --only firestore:rules
```

## Architecture

```
lib/
├── main.dart                  # Entry: init localization/storage/firebase, anonymous-auth fallback, routes to MainNavigation or MasjidSelection
├── firebase_options.dart      # Generated Firebase config (web is REAL; other platforms have PLACEHOLDER values!)
├── models/
│   └── app_data.dart          # Masjid, PrayerTime, Question, Event, User, UserRole + AppData (static global state)
├── services/
│   ├── firebase_service.dart  # Singleton: Firestore CRUD, streams, sample-data seeding (MUST REMOVE)
│   ├── storage_service.dart   # Singleton: shared_preferences persistence
│   └── location_service.dart  # geolocator wrapper
├── repositories/              # Firestore subcollection CRUD (separate from legacy FirebaseService)
│   ├── question_repository.dart  # masjids/{id}/questions
│   ├── event_repository.dart     # masjids/{id}/events
│   └── masjid_repository.dart    # masjids + claimRequests
├── providers/                 # ChangeNotifier state wrappers (Provider package)
│   ├── auth_provider.dart     # FirebaseAuth state → app.User (role mapping)
│   ├── question_provider.dart # question list + stream subscription
│   ├── event_provider.dart    # event list + stream subscription
│   ├── masjid_provider.dart   # masjid list, filtering, selection, distance sort
│   ├── masjid_claim_provider.dart
│   ├── location_provider.dart # GPS state
│   └── settings_provider.dart # dark mode / language / notifications (persisted)
├── screens/                   # 17 screens (see below)
├── l10n/                      # Key-based manual localization (NOT Flutter built-in)
│   ├── app_localization.dart  # appLocalization singleton (ChangeNotifier), t(key), isRTL
│   ├── app_strings.dart       # AppStrings.* key constants
│   └── app_translations.dart  # EN/UR maps
├── theme/
│   ├── app_theme.dart         # ColorPalette constants + light/dark ThemeData
│   └── app_state.dart         # appStateProvider (dark mode ChangeNotifier)
├── utils/                     # distance_utils, time_utils, validators
└── widgets/                   # category_slider, enhanced_event_card, event_search_bar, shared/*
```

## Screens (17)

| Screen | File | Purpose |
|---|---|---|
| MasjidSelectionScreen | `screens/masjid_selection_screen.dart` | First screen — pick nearby masjid (location-sorted) |
| MainNavigationScreen | `screens/main_navigation_screen.dart` | 4-tab bottom nav shell |
| PrayerPage | `screens/prayer_page.dart` | Tab 1 — prayer times + countdown (live Firestore stream) |
| CommunityPage | `screens/community_page.dart` | Tab 2 — events, search, category + filter chips |
| QuestionsPage | `screens/questions_page.dart` | Tab 3 — ask question + list with answer status |
| SettingsPage | `screens/settings_page.dart` | Tab 4 — profile, masjid, prefs, admin panel, about |
| AdminLoginScreen | `screens/admin_login_screen.dart` | Email/password + Google admin login |
| AdminPanelScreen | `screens/admin_panel_screen.dart` | Edit prayer times + links to Q&A/Events mgmt |
| AdminQAScreen | `screens/admin_qa_screen.dart` | Answer/delete user questions |
| AdminEventsScreen | `screens/admin_events_screen.dart` | Event CRUD (dialog form) |
| AdminRegisterScreen | `screens/admin_register_screen.dart` | Register new masjid (creates Auth + Firestore doc) |
| AskQuestionScreen | `screens/ask_question_screen.dart` | Dedicated ask-question form |
| EditProfileScreen | `screens/edit_profile_screen.dart` | Display name + password change (re-auth via EmailAuthProvider) |
| ClaimMasjidScreen | `screens/claim_masjid_screen.dart` | Request to claim/register a masjid |
| SuperAdminDashboard | `screens/super_admin_dashboard.dart` | Approve claim requests |
| HomeScreen | `screens/home_screen.dart` | LEGACY pre-nav-screen prayer view (not routed anymore) |

## Key Architectural Facts

- **`AppData`** is a static singleton — NOT reactive. `selectedMasjid`, `allMasjids`, `allQuestions`, `allEvents`, `currentUser`, `allUsers`. UI must manually rebuild via `setState`.
- **`UserRole` enum**: `guest → verifiedUser → imam → admin`. The MVP roadmap adds **Normal Muqtaddi → Verification Request → Verified Muqtaddi (approval-required | full event permission)** + separately **Imam/Admin**.
- **Data flow**: Firestore → Repository/Service → Provider (ChangeNotifier) → UI via `context.watch`; mutations via repository / `FirebaseService`.
- **Real-time**: `FirebaseService.getMasjidStream()` + `QuestionProvider.subscribeToQuestions()` + `EventProvider.subscribeToEvents()`.
- **Localization**: `appLocalization.t(AppStrings.someKey)` everywhere. RTL toggled by `appLocalization.isRTL` + a `Directionality` wrapper in `main.dart`.
- **Theming**: `ColorPalette.primary` (green), `.secondary` (amber/gold), `.tertiary` (orange), `.success`, `.error`, `.warning`, `.info`, `.lightBorder`, `.darkBorder`. `Theme.of(context).colorScheme.surface` for card backgrounds.
- **Firestore paths**: `masjids/{id}`, `masjids/{id}/questions/{qid}`, `masjids/{id}/events/{eid}`, top-level `claimRequests/{id}`.
- **Anonymous auth fallback** in `main.dart`: if no Firebase Auth user, signs in anonymously so Firestore `isSignedIn()` rules pass. MVP roadmap wants this replaced by real email/password auth.

## Known Issues / TODOs (see `latesttodo.md` for full Phase 1 roadmap)

1. **Sample/mock data**: `AppData.initialize()` (3 fake masjids + fake events) and `FirebaseService.initializeSampleData()` still exist — MUST be removed. Keep ONLY Hassan Masjid in Firestore.
2. **Auth**: Anonymous auth is the default path. Need email/password register/login for normal Muqtaddis; admin identity should not rely on `masjid.username == email` alone.
3. **Firestore rules** (`firestore.rules`): admin check reads `masjids/{id}` `.username` field comparing to `request.auth.token.email`. Works only with real email auth (anonymous users can never be admin). Needs verification system (roles: normal/verified muqtaddi, event-permission flags).
4. **Event categories**: `'Tablighi Jamaat'` must become `'Jammat'` — currently in `community_page.dart` (id `'Tablighi Jamaat'`) and `app_translations.dart` key `tablighi_jamaat`.
5. **Countdown language**: `prayer_page.dart` shows `"$hours:$minStr hours remaining"` (e.g. `2:30 hours remaining`) — must become `"2 hours remaining"` / `"50 minutes remaining"` with singular/plural.
6. **Bottom nav label**: `main_navigation_screen.dart` uses `AppStrings.prayerTimes` ("Prayer Times") for tab 1 — must be shortened to "Time".
7. **Prayer names/masjid names**: no Urdu translations stored in Firestore yet (prayer name, masjid name). Structure is `list<{name, time}>` per masjid.
8. **Profile UI**: `settings_page.dart` has a basic profile card only. Needs role/verification status/event permission/verification request UI.
9. **Placeholder config**: `lib/firebase_options.dart` has PLACEHOLDER values for android/ios/macos/etc. Only `web` is fully configured. Android works because `google-services.json` handles native init.
10. **`authenticateAdmin()`** in `firebase_service.dart` queries `masjids.where('username').where('password')` — queries a `password` field that the rules reject and that doesn't exist. Dead/legacy code.
11. **HomeScreen** is legacy/unused (main nav uses PrayerPage + CommunityPage + QuestionsPage + SettingsPage).

## Firebase Auth State Mapping (AuthProvider)

- `_onAuthStateChanged`: firebaseUser == null → guest `app.User`; else builds `app.User(role: verifiedUser, isLoggedIn: true)`.
- `signInWithGoogle()` is gated to admins: reads ID-token custom claims (`admin`/`imam`/`superadmin`) — a plain Google login does NOT become admin.
- `EditProfileScreen` handles password change with `reauthenticateWithCredential`.

## Testing & Deployment Notes

- No automated test suite exists. `flutter analyze` is the main static check.
- Redmi 12C (Android 14, API 34, 720x1650) is the primary test device via ADB.
- Playwright MCP is configured for Flutter-web UI verification (screenshots in repo root: `*.png`).
- Streamline MCP is configured for app icons/branding.

## Starter reminder

1. Read `latesttodo.md` — it is the authoritative Phase 1 MVP roadmap and drives all feature work.
2. Verify against REAL Firestore (`masjid-prayer-app-49f50`), never against hardcoded `AppData` defaults.
3. Before declaring any feature done, prove data lands in Firestore and survives restart.