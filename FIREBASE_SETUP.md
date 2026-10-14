# Firebase configuration and local QA

Updated 14 October 2026. The project uses Firebase Authentication and Firestore. Community posts/comments are text-only; the app does not need Storage uploads or a paid notification backend.

**Production is not ready for this client.** The read-only [audit](scripts/qa/PRODUCTION_AUDIT.md) found older deployed rules. Local configuration does not deploy the reviewed policy or certify production workflows.

## Current configuration

| Item | Current value |
| --- | --- |
| Firebase project | `masjid-prayer-app-49f50` |
| Launch platform | Android only |
| Existing Android ID | `com.example.masjid_app`; final ID pending |
| Android native config | `android/app/google-services.json`, provided locally and ignored by Git |
| Web options | `lib/firebase_options.dart`; web retained for browser QA |
| Other native options | Placeholders; iOS/macOS/Windows/Linux are not launch targets |
| Production Firestore | Native database in `asia-south1` (Mumbai), confirmed read-only; other Firebase service locations not inferred |
| Rules/index source | `firestore.rules`, `firestore.indexes.json`, `firebase.json` |

There is no committed `.firebaserc`; use an explicit project argument for Firebase CLI operations. Project identifiers/API configuration are not administrator credentials. Authorization belongs in deployed rules and trusted grants.

## Run Android locally

1. Obtain the matching Android configuration file from the owner-controlled Firebase project and put it at `android/app/google-services.json`. Do not use another project's file.
2. Confirm Email/Password sign-in is enabled in the intended Firebase Authentication project. Google sign-in remains hidden by default; enable it only after OAuth and device verification.
3. Run:

```sh
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d DEVICE_SERIAL
```

Replace `DEVICE_SERIAL` with the connected device ID. Android initialization uses the native config; the placeholder Android Dart options do not block this path. Existing accounts/data are production data unless the app is explicitly using the isolated QA configuration. Test controlled writes against emulators/staging, not production fixtures.

Changing the final Android application ID requires a matching Firebase Android registration/configuration and signing/OAuth review. Follow [Android release instructions](scripts/qa/ANDROID_RELEASE.md). Do not run an all-platform FlutterFire regeneration simply to clear placeholder values for platforms outside the launch scope.

## Safe isolated testing

Install Node, Firebase CLI and Java 21+ for the Firestore emulator. Then:

```sh
npm ci --prefix test/firestore
firebase emulators:exec --project demo-masjid-rules --only firestore --config firebase.emulator.json 'npm --prefix test/firestore test'
```

See [rules test instructions](test/firestore/README.md) for Java setup. For app/browser QA, follow [UI QA](scripts/qa/UI_QA.md): run Auth/Firestore emulators, seed only their hardcoded localhost demo endpoints, and build the debug preview with `USE_FIREBASE_EMULATORS=true`. Release mode rejects this flag.

Never enable public write/test-mode rules, paste account secrets into source, or seed example mosques into production. The former `setup_firebase.sh` was removed because it used an obsolete path/project and recommended unrestricted writes. Sample-production seed scripts referenced in old guides no longer exist.

## Production activation is a separate operation

Before any rollout, independently review privileged users and mosque ownership, rehearse grant/data migration and rollback in staging, bootstrap a reviewed administrator UID through [the trusted procedure](scripts/admin/README.md), and verify compatible rules/index/client behavior. Apply only after explicit deployment authorization, then retrieve active rules and test real allowed/denied operations. Do not infer authorization from an email string or bulk-trust legacy roles.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Missing Android Firebase config | Confirm the local file and package/project match; never commit signing or service-account secrets. |
| Permission denied for comments/approval/deletion | Compare the actual deployed rules to the audit; do not solve it with public writes. |
| Missing index | Review the required index and target environment; emulator success does not create production indexes. |
| Emulator cannot start | Check Java 21+, ports and explicit demo project; follow the test README. |
| CLI authentication expired | Reauthenticate with the Firebase CLI as the intended owner; do not copy/mint tokens from credential-cache instructions in old roadmaps. |
