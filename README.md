# Masjid Prayer App

A Flutter app for mosque communities, built for the first real deployment at **Hassan Masjid**. Users select their masjid, view prayer times, browse community events, post questions answered by imams/admins, request verification, and manage settings (dark mode, English/Urdu, RTL).

> **Goal:** *Real User → Real Firebase → Real Data → Real Imam/Admin → Real Persistence.* No fakery, no silent fallback to sample data. See [`latesttodo.md`](latesttodo.md) for the full Phase 1 MVP roadmap.

## Tech Stack

- **Flutter / Dart** (SDK ^3.9.0)
- **Firebase** — Auth (email/password, Google), Firestore, (web + Android config)
  - Project: `masjid-prayer-app-49f50`
- **Provider** (ChangeNotifier state management)
- **shared_preferences** (local persistence)
- **geolocator** (nearby-masjid distance sorting)
- **google_fonts** (Poppins typography)
- **intl** (date/time formatting)

## Setup

```bash
flutter pub get
flutter run -d chrome   # web (fully configured)
flutter run             # connected Android device (via google-services.json)
flutter build apk       # release build
```

`lib/firebase_options.dart` contains real credentials for **web** and placeholders for other platforms. Android authenticates through `android/app/google-services.json`, so don't rely on the Dart placeholder values on native.

Firestore rules/indexes:
```bash
firebase deploy --only firestore:rules
```

## Architecture

```
lib/
├── main.dart              # Entry point + routing
├── models/app_data.dart   # Models + AppData static globals
├── screens/               # 17 screens (masjid selection, prayer, community, Q&A, settings, admin panels)
├── services/              # firebase_service, storage_service, location_service
├── repositories/          # question/event/masjid Firestore CRUD
├── providers/             # Auth, Question, Event, Masjid, Location, Settings (ChangeNotifier)
├── l10n/                  # Manual EN/UR localization (key-based + RTL)
├── theme/                 # ColorPalette + light/dark themes
├── utils/                 # distance, time, validation helpers
└── widgets/               # Shared UI components
```

**Data flow:** Firestore → Repository/Service → Provider → UI (`context.watch`). Real-time updates via `snapshots()` streams underneath the providers.

## Roles (Phase 1 roadmap)

```
Normal Muqtaddi  →  Verification Request  →  Verified Muqtaddi
                                              ├── Event approval required
                                              └── Full event-posting permission
Imam / Admin (separate)
```

## Current Status

- ✅ App runs on Android (Redmi 12C) and web; prayer times, masjid selection, navigation functional
- ✅ Anonymous Firebase Auth + Firestore reads/writes working
- 🚧 In progress: real user accounts (email/password), verification flow, verified-event permissions, sample-data removal, Urdu prayer/masjid names, event category rename, countdown/branding polish — tracked in [`latesttodo.md`](latesttodo.md)

## Dev Notes

- No automated tests yet — `flutter analyze` is the static check.
- Keep all UI strings in `lib/l10n/` (English + Urdu, RTL-aware).
- Verify every feature against REAL Firestore before marking it done.