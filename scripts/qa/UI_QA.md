# Local UI and acceptance evidence

Updated 14 October 2026. Android is the launch target. Browser checks use a debug Flutter web preview connected to local Auth/Firestore emulators. Local tests, browser screenshots and a debug APK do not establish deployed authorization or signed Android acceptance.

## Recorded results

These results come from separate 14 October passes. The 29 core browser assertions predate the reminder pass; they were not all rerun together against a signed release. No production deployment was performed.

The documentation cleanup reran Flutter analysis (clean) and all 38 Flutter tests (passed). Relative Markdown links/code fences and comment-only Dart changes were checked. Rules, browser suites and device scenarios were not rerun for this cleanup; their results below are prior recorded evidence. Required launcher-source and icon-catalog PNGs previously hidden by a broad ignore rule are retained in Git.

| Check | Recorded evidence / limit |
| --- | --- |
| Flutter analysis | No issues found |
| Flutter tests | 38 passed: original model/prayer cases plus 28 reminder cases |
| Firestore rules | 35 emulator cases passed; role denial, scoped grants/approval, schema bounds, private proposals and deletion behavior |
| Core browser flows | `playwright-smoke.js`: 17 assertions; `playwright-account-qa.js`: 12 assertions |
| Reminder browser flows | `playwright-reminder-qa.js`: 6 assertions for preset/custom validation, persistence, unsupported-platform status and Urdu controls |
| Browser visual checks | Scoped light/dark and English/Urdu RTL at 390×844 and 320×640; signup at 320×400; reminder picker at 320×740 |
| Owner prayer adjustment | Separate cards, opposing name/time alignment and Material time-of-day icons inspected in English/light and Urdu/dark |
| Android compilation | ARM64 debug APK built 14 October at 17:22 PKT, 90,840,181 bytes; no signed release |
| Actual phone | Same APK installed without clearing data on one Android 14 phone; native startup and English/dark screens, custom lead persistence, 35 weekly slots and disable cancellation observed |
| Background notification | One-minute test posted at 17:47:58.065 PKT while app was in background; tap, sound, reboot and daily/Friday delivery not verified |

See [device evidence](ANDROID_DEVICE_QA.md), [reminder acceptance](PRAYER_REMINDERS.md) and the [production audit](PRODUCTION_AUDIT.md). The production audit confirmed the active older rules differ from the tested source.

The core browser suite covers guest/event filtering, reset requests, login, posts/comments, parent/child cleanup, older replies, verification/proposals/manager approval, failed-save draft recovery, answer refresh, failed reauthentication safety and local profile/content/Auth cleanup. It is scoped acceptance, not every form/error/device state.

## Repeat the local checks

Run Flutter analysis/tests from the root. Use Java 21+ for the Firestore emulator; this Mac has Android Studio's JBR at `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. Start the local services in separate terminals:

```sh
firebase emulators:start --project demo-masjid-rules --only firestore,auth --config firebase.emulator.json
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix test/firestore test
node scripts/qa/seed-emulator.mjs --reset
flutter build web --debug --no-wasm-dry-run --dart-define=USE_FIREBASE_EMULATORS=true
python3 -m http.server 7360 --bind 127.0.0.1 --directory build/web
```

Install test dependencies first if needed: `npm ci --prefix test/firestore`. Rules tests reset their demo database; seed afterward. The seed script accepts only its hardcoded localhost demo endpoints. `--reset` deletes/recreates isolated fixtures; never point it at production. Demo passwords are public local-test credentials.

Navigate Playwright to `http://localhost:7360/`. Use `browser_run_code_unsafe` with `filename: "scripts/qa/playwright-smoke.js"`, then the account script and reminder script as appropriate. Emulator-only owner REST reads check records; actual app writes use the signed-in client/rules. The account recovery test temporarily removes a demo grant and restores it in `finally`.

Flutter editable semantics change on focus; scripts type sequentially after focus settles. Older-page controls can require scrolling before lookup. The red emulator warning is removed only from the QA browser to avoid covering navigation. Normal builds do not enable emulator mode.

## Open acceptance

- Final ID, owner signing, Firebase/OAuth registration and a signed candidate: [Android release gate](ANDROID_RELEASE.md).
- Timetable editor unset-time/partial-save defects and public report/block/terms flows: [current review](../../MVP_REVIEW.md).
- Native small-screen keyboard, large text, complete Urdu/light/dark forms, accessibility, optional location denied, offline/reconnect and restart/auth switching.
- Password-reset email delivery/templates; an emulator out-of-band request is not real mail delivery.
- Interrupted cleanup, Auth deletion failure, restart/retry, legacy unattributed data and manager transfer in staging/device acceptance.
- Reminder actual daily/Friday alerts, reboot, revocation, Doze/OEM battery, tap and signed delivery: [checklist](PRAYER_REMINDERS.md).
- Actual deployed indexes/rules/grants, migration compatibility, quota and performance. Browser/emulator success does not certify production.
- Hosted privacy/deletion resources, community moderation, accurate store disclosures and required Play Console testing: [launch plan](../../launchplan.md).

Filters search loaded pages; older pages are snapshots. No attendance or automatic expiry is promised. Optional reminders are implemented locally and have limited native evidence.

Temporary Playwright captures stay ignored. The 27 stale tracked snapshots were removed during documentation cleanup; repeatable scripts and useful evidence summaries remain. Keep [asset attribution](../../assets/README.md). Password recovery follows the [Firebase Flutter API](https://firebase.google.com/docs/auth/flutter/manage-users#send_a_password_reset_email).
