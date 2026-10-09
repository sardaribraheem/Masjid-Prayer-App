# Masjid Prayer App — Project Briefing

> **IMPORTANT**: Before modifying anything, read `CLAUDE.md` and `FINALTODO.md`, then inspect **ONLY** the relevant files for the current task. Do not read the entire codebase.

## 1. Overview & Vision
- **App**: Masjid Prayer App for the Hassan Masjid community and general deployment.
- **Goal**: Allow users to select a masjid, view prayer times, browse/propose community events, ask questions answered by imams/admins, request verification, and manage settings (dark mode, English/Urdu, RTL). Admins/imams manage prayer times, events, Q&A, and verification requests.
- **Tech Stack**: Flutter (^3.9.0 / 3.44.x), Dart (^3.9.0), Firebase (Auth + Firestore), Local state (`shared_preferences` + Provider/ChangeNotifier).
- **Firebase Project**: `masjid-prayer-app-49f50` (`lib/firebase_options.dart` for web; `google-services.json` for Android).

## 2. Architecture & File Structure

### Navigation & Screens
- **Entry (`main.dart`)**: Initializes localization, storage, Firebase; routes to `MainNavigationScreen` or `MasjidSelectionScreen`.
- **Main Navigation Shell (`screens/main_navigation_screen.dart`)**: 4-tab bottom navigation shell:
  1. `PrayerPage` (`screens/prayer_page.dart`) — Tab 1: Prayer times + live countdown.
  2. `CommunityPage` (`screens/community_page.dart`) — Tab 2: Community events/posts/feed.
  3. `QuestionsPage` (`screens/questions_page.dart`) — Tab 3: Ask questions & view answers.
  4. `SettingsPage` (`screens/settings_page.dart`) — Tab 4: Profile, masjid, prefs, admin panel, about.
- **Admin & Auth Screens**:
  - `AdminLoginScreen` (`screens/admin_login_screen.dart`)
  - `AdminPanelScreen` (`screens/admin_panel_screen.dart`)
  - `AdminQAScreen` (`screens/admin_qa_screen.dart`)
  - `AdminEventsScreen` (`screens/admin_events_screen.dart`)
  - `AdminRegisterScreen` (`screens/admin_register_screen.dart`)
  - `MuqtaddiLoginScreen` (`screens/muqtaddi_login_screen.dart`)
  - `MuqtaddiRegisterScreen` (`screens/muqtaddi_register_screen.dart`)
  - `AskQuestionScreen` (`screens/ask_question_screen.dart`)
  - `EditProfileScreen` (`screens/edit_profile_screen.dart`)
  - `ClaimMasjidScreen` (`screens/claim_masjid_screen.dart`)
  - `SuperAdminDashboard` (`screens/super_admin_dashboard.dart`)

### Models (`models/`)
- `app_data.dart`: Defines `Masjid`, `PrayerTime`, `Question`, `Event`, `User`, `UserRole`, `ClaimRequest`, and static global state `AppData`.

### Services (`services/`)
- `firebase_service.dart`: Singleton for Firestore CRUD, streams, queries.
- `storage_service.dart`: Singleton for `shared_preferences` persistence.
- `location_service.dart`: Geolocator wrapper.

### Repositories (`repositories/`)
- `question_repository.dart`: `masjids/{id}/questions`
- `event_repository.dart`: `masjids/{id}/events`
- `masjid_repository.dart`: `masjids` + `claimRequests`

### Providers (`providers/`)
- `auth_provider.dart`: FirebaseAuth state & role mapping.
- `question_provider.dart`: Question list + stream subscription.
- `event_provider.dart`: Event list + stream subscription.
- `masjid_provider.dart`: Masjid list, filtering, selection, distance sort.
- `masjid_claim_provider.dart`: Masjid claims & registrations.
- `location_provider.dart`: GPS state.
- `settings_provider.dart`: Dark mode / language / notifications persistence.

## 3. Role & Permission Model
- **UserRole Enum**: `guest` → `muqtaddi` → `verifiedMuqtaddi` → `imam` → `admin` (Ultimate Admin).
- **Enforcement**: Backend security (`firestore.rules`) strictly prevents self-promotion, self-verification, and unauthorized masjid management.

## 4. Firestore Collections & Security
- `masjids/{id}`
- `masjids/{id}/questions/{qid}`
- `masjids/{id}/events/{eid}`
- `claimRequests/{id}`
- `users/{uid}`
- **Security Rules**: [`firestore.rules`](firestore.rules) enforces auth token claims, role checks, and prevents privilege escalation.

## 5. Localization & Theming
- **Localization**: Key-based manual localization via `AppLocalization` singleton (`l10n/app_localization.dart`), `AppStrings` (`l10n/app_strings.dart`), and EN/UR maps (`l10n/app_translations.dart`). RTL supported via `Directionality`.
- **Theming**: `ColorPalette` constants & light/dark `ThemeData` (`theme/app_theme.dart`).

## 6. Development Workflow & Commands
```bash
flutter pub get
flutter run -d chrome
flutter analyze
firebase deploy --only firestore:rules
```

## 7. What NOT to Touch Unnecessarily
- Do not modify core localization maps or routing structure unless required by an explicit checklist task in `FINALTODO.md`.
- Do not re-introduce fake sample data seeding in production (`FirebaseService.initializeSampleData`).
