# Masjid App contributor briefing

Updated 14 October 2026. Read [AGENTS.md](AGENTS.md), this file, [FINALTODO.md](FINALTODO.md) and [launchplan.md](launchplan.md) before changes. Inspect task-relevant files and preserve existing work.

## Product and current state

Android-only MVP for local mosque timetables, approved events, text-only community posts/comments, member verification and imam management. English/Urdu, RTL and light/dark modes must remain supported. Preserve the owner's restrained prayer layout: separate prayer cards, names and times at opposite edges, and familiar time-of-day icons.

**Public release remains on hold.** The deployed backend uses older rules; source rules passing locally do not protect production. See [MVP_REVIEW.md](MVP_REVIEW.md) and the [production audit](scripts/qa/PRODUCTION_AUDIT.md). Final application ID/signing, remaining Android acceptance, timetable-editor correctness and public community moderation are open gates.

## Architecture

| Area | Main files / responsibility |
| --- | --- |
| Startup | `lib/main.dart`; initializes preferences, localization, Firebase and selected mosque |
| Navigation | `lib/screens/main_navigation_screen.dart`; Time, Events, Community, Settings |
| Prayer | `prayer_page.dart`, `admin_panel_screen.dart`; display and manager editing |
| Events | `community_page.dart`, event provider/repository, manager events screen |
| Community | `questions_page.dart`, question provider/repository; posts, answers and comments |
| Accounts | Auth provider; muqtaddi/admin login and registration; edit profile; account deletion service |
| Mosque onboarding | Claim screen/provider/repository and super-admin dashboard |
| Models/cache | `lib/models/app_data.dart`; Firestore is the source of truth, AppData is a client cache |
| Persistence | Firebase service; local storage service; settings/location providers |
| Reminders | Prayer reminder provider/services and Android native notification configuration |
| Localization/theme | `lib/l10n/`, `lib/theme/`, bundled fonts/icons |

`CommunityPage` is the Events tab. `QuestionsPage` is the Community tab. Do not introduce photo/video attachments or Storage uploads.

## Authorization and data

Ordinary muqtaddi, mosque-verified muqtaddi and imam/admin are distinct roles, not a client-controlled promotion ladder. Member verification and event permissions are separate from Firebase email verification. A manager needs an imam/admin role, the assigned `masjidId`, and membership in that mosque's protected `authorizedImamUids`. Super-admin access uses a trusted Auth custom claim. Never grant privileges by email or editable profile fields.

Source rules enforce these boundaries; the deployed policy currently does not match them. Changes must include server rules as well as UI constraints. Follow [trusted bootstrap/migration](scripts/admin/README.md); never bulk-trust legacy elevated roles.

Paths: `users/{uid}`, `claimRequests/{id}`, `masjids/{id}`, mosque `events/{id}`, `questions/{id}` and question `comments/{id}`. Preserve current ISO-string post/event ordering until an explicit migration. Public anonymity is limited to display-name hiding. Account/post deletion can partially complete and must remain retryable.

Firebase project: `masjid-prayer-app-49f50`. Android uses the ignored native `google-services.json`; web options are in `lib/firebase_options.dart`. Other native Dart options remain placeholders. The production Firestore database is in `asia-south1`; this does not establish the region of every Firebase service.

## Verification and workflow

```sh
flutter pub get
flutter analyze
flutter test
```

Use the explicit demo project and local emulators for fixtures: [rules tests](test/firestore/README.md), [browser QA](scripts/qa/UI_QA.md). Recorded local evidence: clean analysis, 38 Flutter tests, 35 rules cases, 29 core browser assertions plus 6 reminder assertions. These cover different passes; they are not production acceptance.

The current ARM64 debug APK installs on one Android 14 phone and a one-minute notification delivered in the background. Keep reboot, Doze/OEM battery, revocation, daily/Friday delivery, tap navigation and signed-artifact checks open: [device evidence](scripts/qa/ANDROID_DEVICE_QA.md), [reminder checklist](scripts/qa/PRAYER_REMINDERS.md).

Do not implicitly deploy rules/indexes, change production claims/data, or publish a release. Keep signing credentials outside Git. No production sample seeding, plaintext passwords, client-only authorization or unsupported completion claims. Retain asset licenses. Attendance and payments remain deferred.
