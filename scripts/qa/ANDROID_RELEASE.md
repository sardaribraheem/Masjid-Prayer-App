# Android release gate

The app remains registered as `com.example.masjid_app`. The owner confirmed Android-only launch and explicitly left the final application ID pending. Do not publish until that identity and its corresponding Firebase Android configuration are confirmed.

Release signing no longer falls back to the debug key. Create an owner-controlled upload keystore outside Git and an ignored `android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. `storeFile` is relative to android/app unless absolute. A release task fails clearly when the file is absent. Keep both the keystore and its passwords backed up privately; do not add either to Git.

After identity/signing and Firebase configuration are ready, run Flutter analysis/tests and the demo rule suite, then build the AAB in the reviewed release environment. Install and verify the signed app on Android: startup, offline fonts, selection, location denied, prayers, Urdu/RTL, light/dark, small-screen keyboard, auth/account switching, verification, event proposals, post/comment deletion, account cleanup/retry, and restart persistence.

`USE_FIREBASE_EMULATORS` is a compile-time debug-only QA option. It targets `demo-masjid-rules` on localhost and must not be used for release. Google sign-in UI is excluded by default; enable `ENABLE_GOOGLE_SIGN_IN=true` only after provider/OAuth setup and device testing. Email/password remains available.

Reviewed production role migration, trusted administrator bootstrap, Firestore indexes/rules deployment, staging acceptance, and device QA remain separate release gates. No production Firebase deployment or store publication is performed by the UI QA scripts.
