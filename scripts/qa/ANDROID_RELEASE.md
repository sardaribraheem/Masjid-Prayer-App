# Android release gate

Updated 14 October 2026. Public launch remains on hold. This is the native release procedure; [launchplan.md](../../launchplan.md) owns the ordered technical/business gates.

The app remains registered as `com.example.masjid_app`. The owner confirmed Android-only launch and explicitly left the final application ID pending. Do not publish until that identity and its corresponding Firebase Android configuration are confirmed.

Release signing no longer falls back to the debug key. Create an owner-controlled upload keystore outside Git and an ignored `android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. `storeFile` is relative to android/app unless absolute. A release task fails clearly when the file is absent. Keep both the keystore and its passwords backed up privately; do not add either to Git.

After identity/signing and Firebase configuration are ready, run Flutter analysis/tests and the demo rule suite, then build the AAB in the reviewed release environment. Install and verify the signed app on Android: startup, offline fonts, selection, location denied, prayers, Urdu/RTL, light/dark, small-screen keyboard, auth/account switching, verification, event proposals, post/comment deletion, account cleanup/retry, and restart persistence.

`USE_FIREBASE_EMULATORS` is a compile-time debug-only QA option. It targets `demo-masjid-rules` on localhost and must not be used for release. Google sign-in UI is excluded by default; enable `ENABLE_GOOGLE_SIGN_IN=true` only after provider/OAuth setup and device testing. Email/password remains available.

Reviewed production role migration, trusted administrator bootstrap, Firestore indexes/rules deployment, staging acceptance, and device QA remain separate release gates. No production Firebase deployment or store publication is performed by the UI QA scripts.

The 14 October read-only [production audit](PRODUCTION_AUDIT.md) confirmed that deployed rules still use the old email-based policy. Do not install the current app for public use against that backend until the reviewed migration/deployment and acceptance sequence passes. Optional prayer reminders now require [additional device checks](PRAYER_REMINDERS.md), including permission denial/revocation, app closed, reboot and selected-mosque changes. Android setup uses compile SDK 36, Java 17 desugaring, AGP 8.11.1 and Gradle 8.13. The installed Flutter SDK warns that Gradle 8.14+ will be required in a future version; this warning is not a current compilation failure.

Before store submission, also close the timetable-editor and public community moderation gaps in [MVP_REVIEW.md](../../MVP_REVIEW.md), publish working privacy/deletion-request pages, and complete accurate Data safety, content rating, audience and reviewer-access setup. Check the actual Play Console account's testing requirements. Relevant official policies and the conditional 12-tester/14-day requirement are linked in [launchplan.md](../../launchplan.md); no public store deadline is guaranteed.
