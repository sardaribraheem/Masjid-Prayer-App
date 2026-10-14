# Masjid Prayer App

Flutter Android MVP for masjid communities, using Firebase Authentication, Firestore, Provider, and English/Urdu with RTL support. The app provides masjid selection, prayer times, approved events, text-only community posts and comments, member verification, and scoped imam management.

## Launch status

The current implementation has local Flutter, security-emulator, and browser QA evidence. This is not production or Android device acceptance. [launchplan.md](launchplan.md) records phase progress, and [MVP_REVIEW.md](MVP_REVIEW.md) retains the initial findings. See [UI QA](scripts/qa/UI_QA.md) for the latest checks and limits.

Android is the only launch target. The final application ID remains pending; the existing registration is `com.example.masjid_app`. Release signing, reviewed production role migration, rules/index deployment, and real-device acceptance remain release gates. See [Android release instructions](scripts/qa/ANDROID_RELEASE.md).

Notification scheduling and attendance registration are deferred. Google sign-in UI is disabled unless `ENABLE_GOOGLE_SIGN_IN=true`; enable it only after OAuth configuration and device verification. Community attachments and uploads are excluded. Anonymous posting hides the display name; stored author UIDs remain readable.

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
