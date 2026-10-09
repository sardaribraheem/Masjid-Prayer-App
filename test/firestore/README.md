# Firestore authorization tests

Run from the repository root with Node, Firebase CLI, and Java 21+ available:

```sh
npm ci --prefix test/firestore
firebase emulators:exec --project demo-masjid-rules --only firestore --config firebase.emulator.json 'npm --prefix test/firestore test'
```

On this workstation, Android Studio provides Java 21 at `/Applications/Android Studio.app/Contents/jbr/Contents/Home`; the shell's default Java 20 cannot run the cached emulator. Set JAVA_HOME and include its bin directory in PATH for the command if needed.

The explicit demo project prevents production writes. The suite covers user registration, role escalation, manager association/grants, email impersonation, claim identity/approval, atomic onboarding, rollback, text-only community schemas, author/moderation permissions, verification, event approval/full permission, pending privacy, deletion freezes/recent-auth, cleanup queries/ownership/retry, and guest reads.

Rules compile and execute in the emulator. This suite does not test the Dart client, Firebase Auth deletion, configured sign-in providers, deployed indexes, or Android UI; staging/device checks remain required. Firebase's [testing guide](https://firebase.google.com/docs/firestore/security/test-rules-emulator) and [query authorization guide](https://firebase.google.com/docs/firestore/security/rules-query) describe the testing and collection-group permission model used here.
