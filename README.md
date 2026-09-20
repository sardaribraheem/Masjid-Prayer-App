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

## Roles (as modeled)

```
guest → muqtaddi (new account) → verifiedMuqtaddi → imam → admin
```

- Registered users start as a plain **Muqtaddi** (`role` stored in Firestore `users/{uid}`, never self-elevated).
- Roadmap adds: **Verification Request → Verified Muqtaddi** (event approval-required | full event-posting permission) + separate **Imam/Admin** track.
- Google login does NOT auto-elevate to admin; roles come from the Firestore doc.

## Current Status

- ✅ App runs on Android (Redmi 12C) and web; prayer times, masjid selection, navigation functional
- ✅ **Hassan Masjid** (`6qkkBODeZ8kLHkNOCjqx`) is patched & clean in Firestore: no `password` field, `nameUrdu=حسن مسجد`, 6 prayers (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
- ✅ Email/password register + login for normal Muqtaddis (done) — **anonymous auth removed**
- ✅ Q&A flow verified E2E: ask question → real Firestore doc → survives reload
- ✅ Playwright UI verification: all 4 pages × light/dark × mobile/desktop × English/Urdu-RTL
- ✅ Countdown language + bottom-nav "Time" label + Tablighi→Jammat rename (done)
- 🚧 In progress: delete leftover sample masjid docs, verification flow, verified-event permissions, Urdu *prayer-name* translations, profile/RBAC UI, branding/icons — tracked in [`latesttodo.md`](latesttodo.md)

> ⚠️ **Firestore admin writes (2026-09-16):** the CLI's cached refresh token is invalid
> (`INVALID_REFRESH_TOKEN`); run `firebase login` to re-auth before any scripted Firestore
> admin work. Raw REST deletes are also gated by the classifier — name exact doc IDs. The
> app itself still works against the real project.

## Dev Notes

- No automated tests yet — `flutter analyze` is the static check.
- Keep all UI strings in `lib/l10n/` (English + Urdu, RTL-aware).
- Verify every feature against REAL Firestore before marking it done.
- **Never store plaintext passwords in Firestore** (Hassan Masjid's `password` field was stripped for exactly this reason).
- Read `latesttodo.md` first — it is the authoritative Phase 1 roadmap and wears a ⚠️ READ-THIS-FIRST block with the current Firestore-access blocker.