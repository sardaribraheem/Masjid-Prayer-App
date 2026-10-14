# UI and local acceptance evidence — 14 October 2026

This pass uses Streamline MCP for the bundled Nova icons and Playwright MCP against a Flutter web preview connected to local Firebase Auth/Firestore emulators. The launch target remains Android. Browser QA and a debug APK do not establish signed Android behavior or deployed Firebase rules.

**Later 14 October reminder pass:** clean analysis, 38 Flutter tests and 35 rules cases now pass. `playwright-reminder-qa.js` passes 6 assertions for the 20-minute preset, rejection of custom 61, custom 17 and its persistence after reload, Android-only browser status, and Urdu controls; the Urdu picker was visually inspected at 320×740 after reload. A provider subscription placement issue caught during this pass was corrected. Actual Android reminder delivery remains pending. [Production audit](PRODUCTION_AUDIT.md) confirms deployed rules still differ from the tested local rules and block public launch. The table below records the earlier UI pass, not native acceptance of the new reminders.

The new reminder Android build initially failed downloading dependencies because this workstation ran out of disk space. Generated project caches and the obsolete downloaded Gradle 8.12 distribution were cleared; a final build attempt is pending. The earlier APK predates these reminders and must not be treated as notification verification.

## Verified locally

| Check | Evidence |
| --- | --- |
| Flutter static analysis | No issues found |
| Flutter tests | 10 passed: permission/model tests and prayer parsing/countdown edge cases |
| Firestore security | 31 emulator cases passed, including self-promotion denial, private proposals, text constraints, deletion races, cursor ties, and a pending queue independent of approved history |
| Android compilation | Current source builds an ARM64 debug APK; no signed release or installation |
| Browser compilation | Static debug web preview builds with `USE_FIREBASE_EMULATORS=true` |
| Repeatable browser flow | `playwright-smoke.js` passes 17 assertions for guest/event filtering, reset requests, login, posting, comments, parent/child deletion, older replies, verification, proposals, and manager approval |
| Failure and account acceptance | `playwright-account-qa.js` passes 12 assertions: denied event draft retained/retried, immediate answer refresh, failed reauthentication safety, profile/content/Auth cleanup, and guest return |
| Visual/manual browser checks | 390×844 and 320×640, plus signup at 320×400; prayer/community light and dark; English/Urdu labels and RTL; settings, masjid selection and wrapping; older post navigation; manager answer/event forms; successful signup returns directly to the signed-in app |

Playwright snapshots and screenshots were inspected during the pass; temporary evidence is ignored under `.playwright-mcp/`. Browser errors caught during development were corrected, including an obscured checkbox ink surface, stale answer cards, dark-button contrast, collapsed offscreen comment state, and an event error placed outside the accessible form content.

## Repeat the local checks

Use JDK 21 for the Firestore emulator. On this Mac the Android Studio bundled JBR supplies it. Start the local services in separate terminals:

```sh
firebase emulators:start --project demo-masjid-rules --only firestore,auth --config firebase.emulator.json
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix test/firestore test
node scripts/qa/seed-emulator.mjs --reset
flutter build web --debug --no-wasm-dry-run --dart-define=USE_FIREBASE_EMULATORS=true
python3 -m http.server 7360 --bind 127.0.0.1 --directory build/web
```

The seed script has hardcoded localhost demo endpoints. `--reset` clears that isolated demo database, then creates labeled fixtures, an ordinary member, and a demo imam. It does not accept a production project or endpoint. The public test password is only for these local accounts. Rules tests reset their demo database; seed afterward.

Navigate Playwright to **http://localhost:7360/**. Use `browser_run_code_unsafe` with `filename: "scripts/qa/playwright-smoke.js"`. Run `playwright-account-qa.js` afterward; it tests denied-write recovery, answering, reauthentication failure, and complete local account cleanup. The scripts use emulator-only owner REST reads to verify records; app writes still use the actual signed-in client and rules. The recovery test temporarily removes only the demo manager grant and restores it in `finally`.

Flutter's editable semantics names change when fields gain focus. The scripts use sequential typing after focus settles. Lazy scrolling requires wheel gestures before selecting controls in older pages. The red Firebase emulator warning is removed only from the QA browser to avoid covering navigation; normal builds do not enable emulator mode.

## Remaining release acceptance

- No Android device was connected (`flutter devices` found macOS and Chrome). Actual soft-keyboard, font fallback, accessibility scaling, permissions, offline/reconnect, restart persistence, and native authentication still need device checks.
- Password-reset delivery/templates are not tested by an emulator OOB request.
- Complete cleanup with injected interruption, Auth deletion failure, retry after restart, legacy UID-less content, and manager transfer still needs staging/device acceptance.
- The emulator does not validate production index availability, existing grants, quotas, or deployment. Review legacy roles/UID attribution and trusted super-admin bootstrap before rules/app rollout.
- Final application ID and owner-controlled signing remain pending. Release builds require ignored signing configuration and never use the debug key. Flutter reports future Gradle/AGP/Kotlin support warnings; the debug build currently succeeds.
- Location-denied and missing-native-configuration behavior needs actual Android acceptance. A previously selected masjid lookup is time-bounded to avoid an indefinite network wait at startup.
- Category/text and answer filters apply to loaded feed pages. Load more extends those results. Refresh returns to the newest listener; older pages are point-in-time snapshots.
- Notification scheduling and attendance registration remain outside the Spark MVP. No automatic content expiry is promised.

No production Firebase rules, indexes, claims, data, or store releases were deployed in this pass.

Password recovery uses the documented [Firebase Flutter API](https://firebase.google.com/docs/auth/flutter/manage-users#send_a_password_reset_email). See [asset licensing](../../assets/README.md) and [Android release gate](ANDROID_RELEASE.md).


## Prayer-page follow-up

A small owner-requested visual adjustment restores individual prayer cards, name/time alignment at opposite edges (mirrored in Urdu), and Material dawn/sun/afternoon/moon icons. The next-prayer card is slightly smaller and omits a zero-hour countdown segment. Clean analysis and all 10 Flutter tests pass. Playwright screenshots were inspected at 390×844 English/light and 320×640 Urdu/dark with no Flutter console errors. This follow-up does not change Firestore rules or establish Android device acceptance.
