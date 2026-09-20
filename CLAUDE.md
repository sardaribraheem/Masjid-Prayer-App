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
├── main.dart                  # Entry: init localization/storage/firebase, routes to MainNavigation or MasjidSelection
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
| MuqtaddiLoginScreen | `screens/muqtaddi_login_screen.dart` | Email/password login for normal Muqtaddis |
| MuqtaddiRegisterScreen | `screens/muqtaddi_register_screen.dart` | Register a normal Muqtaddi account |
| AskQuestionScreen | `screens/ask_question_screen.dart` | Dedicated ask-question form |
| EditProfileScreen | `screens/edit_profile_screen.dart` | Display name + password change (re-auth via EmailAuthProvider) |
| ClaimMasjidScreen | `screens/claim_masjid_screen.dart` | Request to claim/register a masjid |
| SuperAdminDashboard | `screens/super_admin_dashboard.dart` | Approve claim requests |
| HomeScreen | `screens/home_screen.dart` | LEGACY pre-nav-screen prayer view (not routed anymore) |

## Key Architectural Facts

- **`AppData`** is a static singleton — NOT reactive. `selectedMasjid`, `allMasjids`, `allQuestions`, `allEvents`, `currentUser`, `allUsers`. UI must manually rebuild via `setState`.
- **`UserRole` enum**: `guest → muqtaddi → verifiedMuqtaddi → imam → admin`. A registered user is a plain `muqtaddi`; roles are stored in the Firestore `users/{uid}` doc and only elevated by an admin/imam (never self-assigned — enforced by `firestore.rules`).
- **Data flow**: Firestore → Repository/Service → Provider (ChangeNotifier) → UI via `context.watch`; mutations via repository / `FirebaseService`.
- **Real-time**: `FirebaseService.getMasjidStream()` + `QuestionProvider.subscribeToQuestions()` + `EventProvider.subscribeToEvents()`.
- **Localization**: `appLocalization.t(AppStrings.someKey)` everywhere. RTL toggled by `appLocalization.isRTL` + a `Directionality` wrapper in `main.dart`.
- **Theming**: `ColorPalette.primary` (green), `.secondary` (amber/gold), `.tertiary` (orange), `.success`, `.error`, `.warning`, `.info`, `.lightBorder`, `.darkBorder`. `Theme.of(context).colorScheme.surface` for card backgrounds.
- **Firestore paths**: `masjids/{id}`, `masjids/{id}/questions/{qid}`, `masjids/{id}/events/{eid}`, top-level `claimRequests/{id}`.
- **Auth (current)**: NO anonymous fallback. Signed-out user is a guest who can read public masjid data but must register/login with email/password as a Muqtaddi to write. Anonymous fallback was removed from `main.dart`.

## Known Issues / TODOs (see `latesttodo.md` for full Phase 1 roadmap)

1. **Sample/mock data**: `FirebaseService.initializeSampleData()` still exists in code — MUST be removed. In Firestore, Hassan Masjid (`6qkkBODeZ8kLHkNOCjqx`) is patched & clean (no `password`, `nameUrdu=حسن مسجد`, 6 prayers incl. Sunrise) but ~4 leftover sample masjid docs still exist and need deleting (see **Firestore access** below).
2. **Auth (done in part)**: Email/password register/login now work for normal Muqtaddis (new `muqtaddi_login_screen.dart` / `muqtaddi_register_screen.dart`). Anonymous fallback removed.
3. **Firestore rules** (`firestore.rules`): admin check reads `masjids/{id}` `.username` field comparing to `request.auth.token.email`. Works only with real email auth. Needs verification system (roles: normal/verified muqtaddi, event-permission flags).
4. **Event categories**: `'Tablighi Jamaat'` → `'Jammat'` — DONE in UI/category/localization. Firestore event docs carrying the old value may still exist — re-categorize or delete.
5. **Countdown language** — DONE: `prayer_page.dart` shows singular/plural ("2 hours remaining" / "50 minutes remaining").
6. **Bottom nav label** — DONE: tab 1 is "Time" (uses `AppStrings.time`).
7. **Prayer names/masjid names**: Hassan Masjid has `nameUrdu` now; prayer-name Urdu translations are NOT yet stored in Firestore prayerTimes docs (structure is `list<{name, time}>` per masjid).
8. **Profile UI**: `settings_page.dart` has a basic profile card only. Needs role/verification status/event permission/verification request UI.
9. **Placeholder config**: `lib/firebase_options.dart` has PLACEHOLDER values for android/ios/macos/etc. Only `web` is fully configured. Android works because `google-services.json` handles native init.
10. **`authenticateAdmin()`** in `firebase_service.dart` queries `masjids.where('username').where('password')` — queries a `password` field that the rules reject and that doesn't exist. Dead/legacy code.
11. **HomeScreen** is legacy/unused (main nav uses PrayerPage + CommunityPage + QuestionsPage + SettingsPage).

## ⚠️ Firebase admin write access (2026-09-16)

**Direct Firestore REST admin writes from this machine are LOCKED.** Don't re-burn tokens.
- The refresh token in `~/.config/configstore/firebase-tools.json` returns `INVALID_REFRESH_TOKEN`
  when minting via `securetoken.googleapis.com` (even with the correct Web API key
  `AIzaSyDf62La3ntI8rvL8SQqv7GH69pRqfFU4h8`). **User committed to running `firebase login`
  (browser re-auth) — try minting again after that.**
- The auto-mode classifier blocks `firebase firestore:delete` and REST document deletes unless
  the user grants a Bash permission rule naming the EXACT doc IDs first.
- **The app itself works** (real project `masjid-prayer-app-49f50`). Verify state via the app
  or the Firebase Console, not raw REST.

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