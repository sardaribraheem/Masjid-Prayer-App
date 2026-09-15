# Firebase Setup Guide

This project uses Firebase for authentication, Firestore, and (optionally) storage.
The web build is wired up to work out of the box; **Android and iOS require a one-time
credential download from the Firebase console** before they will run.

## 1. Configure Firebase projects

1. Open the [Firebase Console](https://console.firebase.google.com/) and create (or reuse)
   a Firebase project. This repo currently points at `masjid-prayer-app-49f50`.
2. Add the apps you plan to ship to the project:
   - **Android**: package id `com.example.masjid_app`
   - **iOS**: bundle id `com.example.masjidApp`
   - **Web**: register the app and copy the SDK snippet (already wired up in
     `lib/firebase_options.dart` for the values currently committed).

## 2. Download credentials

| Platform | File | Destination |
| -------- | ---- | ----------- |
| Android  | `google-services.json` | `android/app/google-services.json` |
| iOS      | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

The Android file is **already committed** at `android/app/google-services.json`.
The iOS file **is not** — it must be downloaded manually. iOS builds will fail
with `No such module 'Firebase'` / `FirebaseApp.configure()` errors until the
plist is added.

After dropping the file into `ios/Runner/`, also confirm the Xcode project
references it:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Right-click the `Runner` group → *Add Files to "Runner"…* → pick the plist.
3. Make sure *Copy items if needed* is **off** and the *Runner* target is checked.

## 3. Regenerate `lib/firebase_options.dart`

The committed `lib/firebase_options.dart` has real web values but **placeholders**
for Android, iOS, macOS, Windows, and Linux. Run the FlutterFire CLI to populate
them from your project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --platforms=android,ios,web,macos,windows,linux \
  --project=masjid-prayer-app-49f50
```

This overwrites `lib/firebase_options.dart` with values pulled from each platform's
credential file. After running, re-run `flutter pub get` and `flutter analyze`.

## 4. Deploy security rules

Firestore security rules live in `firestore.rules`. Deploy them with:

```bash
firebase deploy --only firestore:rules
```

The rules deny access by default and grant admins/imams write access to their
masjid's prayer times, events, and questions. A super-admin email
(`superadmin@masjid-app.com`) is used for global write access — replace this
with your own email before deploying to production, or rotate the value to a
non-deterministic secret.

## 5. (Optional) Seed sample data

`main.dart` only calls `firebaseService.initializeSampleData()` when running in
**debug mode** (`kDebugMode`). To seed the Firestore database during local
development, simply run the app on a debug build the first time — it will add
three sample masjids if the collection is empty.

For a richer Lahore seed, run the dedicated script:

```bash
dart run lib/scripts/seed_lahore_masjids.dart
```

## 6. Common errors

| Symptom | Likely cause |
| ------- | ------------ |
| `No Firebase App '[DEFAULT]' has been created` | `Firebase.initializeApp()` not called; check `FirebaseService.initialize()` runs before `runApp`. |
| `permission-denied` reading `masjids` | Security rules not deployed, or you read a sub-collection that requires sign-in. |
| iOS build fails on `FirebaseApp.configure()` | Missing `ios/Runner/GoogleService-Info.plist`. |
| Android build fails with `google-services.json not found` | File missing at `android/app/google-services.json`. |