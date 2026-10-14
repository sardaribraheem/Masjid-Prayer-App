# Masjid Prayer App

Flutter Android MVP for masjid communities, using Firebase Authentication, Firestore, Provider, and English/Urdu with RTL support. The app provides masjid selection, prayer times, approved events, text-only community posts and comments, member verification, and scoped imam management.

Read [app_guide.md](app_guide.md) for installation/development commands, guest/member/imam workflows, mosque registration requirements, reminders, data storage and owner approval instructions.

## Launch status

The current implementation has local Flutter, security-emulator, browser QA, and limited [Android device evidence](scripts/qa/ANDROID_DEVICE_QA.md). Broader device/signed-release acceptance and production migration remain pending. [launchplan.md](launchplan.md) records phase progress, and [MVP_REVIEW.md](MVP_REVIEW.md) retains the initial findings. See [UI QA](scripts/qa/UI_QA.md) for the latest checks and limits.

Android is the only launch target. The final application ID remains pending; the existing registration is `com.example.masjid_app`. Release signing, reviewed production role migration, rules/index deployment, and real-device acceptance remain release gates. See [Android release instructions](scripts/qa/ANDROID_RELEASE.md).

Optional local Android prayer reminders are implemented: default 15 minutes, presets including 20 minutes, or a custom 1–60 minute lead for the selected masjid. Friday uses Jummah instead of Dhuhr when set. Reminders are off until the user enables them and grants notification/alarm permissions. They use the phone timezone and last saved timetable; reopen the app to refresh changes. One Android 14 background test delivers on time; reboot, broader delivery and signed-release acceptance remain pending. See [reminder QA](scripts/qa/PRAYER_REMINDERS.md). No Storage uploads or paid server scheduler are added.

Attendance registration remains deferred. Google sign-in UI is disabled unless `ENABLE_GOOGLE_SIGN_IN=true`; enable it only after OAuth configuration and device verification. Community attachments and uploads are excluded. Anonymous posting hides the display name; stored author UIDs remain readable.

**Production security blocker:** a read-only audit on 14 October retrieved the older deployed email-based rules, last updated 16 September. They do not match the locally tested rules or current client workflows. Reviewed grants/migration, administrator bootstrap, rules/index deployment, and staging verification are required before launch. See [production audit](scripts/qa/PRODUCTION_AUDIT.md).

## Development

Read `AGENTS.md`, `CLAUDE.md`, `FINALTODO.md`, and `launchplan.md` before changes.

```sh
flutter pub get
flutter analyze
flutter test
flutter run # connected Android device
flutter build apk --debug --target-platform android-arm64
```

Provide the project's Android `google-services.json` locally; it is ignored by Git. Android startup uses the native configuration. Other native targets have placeholder Dart options and are not launch targets. Poppins fonts and Streamline icons are bundled for offline rendering; [asset attribution](assets/README.md) and the font license accompany them.

For browser QA, use the isolated local demo emulators described in [UI QA](scripts/qa/UI_QA.md). Do not seed fixtures into production. [Security test instructions](test/firestore/README.md) and [trusted administrator bootstrap/migration](scripts/admin/README.md) are separate from visual QA.

## Authorization and data lifecycle

New accounts are ordinary members. Approved verification controls event proposals; publication requires manager approval unless the member has an explicit full grant. Imam access requires a reviewed assignment and a protected masjid grant. Super-admin access requires the server-issued `superAdmin` claim; email addresses grant no privileges. UI checks supplement Firestore rules.

Posts and events load in pages of 30 with a lookahead document; comments load on demand with older-page navigation. Older pages are snapshots; Refresh reconnects to the newest feed. Event text/category search and community answer filters apply to loaded pages. The manager's pending-event queue is queried separately from approved history.

Post deletion freezes replies, deletes child comments in batches, then deletes the post. Account deletion requires recent authentication, freezes contributions, removes UID-attributed content and profile, then deletes Auth. Interrupted cleanup is retryable and may partially complete. Managers require reviewed transfer/revocation; legacy content without creator UIDs needs migration. No automatic archival or expiry is promised.

Production deployments must pair reviewed rules, indexes, migration, and compatible app behavior. Local tests do not establish deployed Firebase behavior. Do not deploy or publish implicitly during code review.
