# MVP readiness review

Updated 14 October 2026. **Decision: HOLD public launch.** The app has useful local implementation and limited phone evidence, but the deployed backend and public-release requirements do not yet support a safe, reliable launch. Use [launchplan.md](launchplan.md) for execution and [FINALTODO.md](FINALTODO.md) for requirements.

## Current blockers

| Priority | Finding and evidence | Required closure |
| --- | --- | --- |
| P0 | Production still serves the older email-based rules. Read-only audit retrieved the release updated 16 September; it differs from source and lacks current comments, scoped approvals and cleanup permissions. | Independently review legacy grants/data, bootstrap the trusted claim, test migration in staging, authorize coordinated rules/index/client rollout, then retrieve and test deployed policy. [Audit](scripts/qa/PRODUCTION_AUDIT.md) |
| P0 | Imam editor maps unset/invalid prayer times to noon, supplies a default Friday time, mutates the selected model before persistence, and ignores the separate Friday write result. Source: `_initializeTimes`, `_parseTimeString`, `handleSave` in [admin_panel_screen.dart](lib/screens/admin_panel_screen.dart). | Require intentional valid selections, save the timetable coherently and report failures accurately. Test a newly approved empty timetable and denied/failed saves; do not advertise example values as verified congregation times. |
| P0 for public community | Posting-policy acceptance, in-app report-content/report-user and user blocking were not found in current client/rules. Manager delete controls alone do not complete public community moderation. | Add localized flows, protected/bounded reports, blocking and a staffed review process. Verify behavior and follow [Google Play UGC policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en). |
| P0 for store release | Application ID remains `com.example.masjid_app`; final ID/signing are pending. There is no certified signed candidate. | Owner confirms identity and controls signing; verify matching Firebase/OAuth registration and signed artifact. [Release gate](scripts/qa/ANDROID_RELEASE.md) |
| P0 for store release | In-app privacy/deletion exist, but public privacy and deletion-request resources and store disclosures have not been verified. | Publish working resources, check real deletion support, complete accurate Data safety/store setup. [Google Play user-data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en) and [deletion guidance](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) |
| P1 | Reminder background test passed on one Android 14 debug device; reboot, revocation, daily/Friday delivery, tap navigation, OEM/Doze and signed behavior remain open. | Run and record [reminder acceptance](scripts/qa/PRAYER_REMINDERS.md) on the signed candidate; explain observed device restrictions. |
| P1 | Native keyboard/RTL/accessibility/offline/auth restart and cleanup-interruption coverage is incomplete. | Complete staging/device matrix; retry after partial cleanup, verify manager handover and legacy UID-less contributions. |

## Operational risks before expansion

- The mosque directory is an unbounded read. Content feeds/comments paginate, but filter/search applies to loaded pages. Measure usage and loading behavior before growing the directory.
- Current valid post/event ordering uses client-provided ISO dates. A reviewed migration is needed before changing timestamp types; do not mix types silently.
- No production load/concurrency or abuse-rate acceptance has been completed. Text limits constrain individual documents, not how many requests an attacker can make. Define usage monitoring and abuse response before opening wider signup.
- Anonymous mode hides a display name, not the stored author UID. Privacy and user expectations must remain explicit.
- Registration currently needs name/location and account details, not uploaded documents or a map pin. Committee identity/authority is checked manually; request progress/contact/Urdu-name UI is incomplete.
- An earlier requirement called for Firebase verified-email posting. Current posting accepts signed-in members; mosque verification is a different concept. Resolve the product decision explicitly before release.
- Retention, automatic expiry, attendance and payments are not implemented release features. Do not include them in marketing.
- Launcher source is only 48×48; confirm final icon quality/usage rights and splash/store branding before submission.

## What the evidence establishes

| Evidence | Result / limit |
| --- | --- |
| Local Flutter | Clean analysis; 38 tests, including 28 reminder tests. No deployed authorization claim. |
| Local Firestore | 35 emulator cases covering allowed/denied roles, text/schema bounds, approval privacy and cleanup. No production index/grant/latency certification. |
| Browser | 29 core assertions plus 6 reminder assertions in separate demo-emulator passes; scoped EN/UR and small-screen visual checks. No signed native acceptance. |
| Android debug | Current ARM64 APK builds and installs with existing device data preserved. One one-minute notification posted at 17:47:58.065 PKT in the background. No reboot/tap/signed acceptance. |
| Production | Read-only rules audit and Firestore `asia-south1` location lookup. No rules, claims, indexes or data were changed. |

Detailed evidence: [UI QA](scripts/qa/UI_QA.md), [device QA](scripts/qa/ANDROID_DEVICE_QA.md), [production audit](scripts/qa/PRODUCTION_AUDIT.md).

## Findings corrected locally since the initial review

Ordinary-member imam applications and transactional approval; claim-based super-admin and protected manager grants; text-only community/comment schemas; paginated feeds/comments; private event proposals; retryable UID-attributed deletion; accurate settings/privacy; bundled fonts/icons; password recovery; optional configurable local reminders. These are source improvements with scoped local evidence, not proof that production has changed.

This file replaces the stale baseline review and appended session narratives. Git history preserves the original findings. Close risks only with recorded evidence for the relevant environment and artifact.
