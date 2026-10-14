# Connected Android device evidence — 14 October 2026

This pass uses the owner's connected Android phone and the current debug APK. Production Firebase configuration is used for startup and existing public timetable reads; no test posts/accounts/mosques were seeded, no rules/indexes/claims were deployed, and existing app data was preserved during installation. The deployed-backend blocker in [PRODUCTION_AUDIT.md](PRODUCTION_AUDIT.md) still applies.

## Device and artifact

- Android 14 / API 34, model `22120RN86G`, ARM64.
- Display 720×1650 at density 320; timezone `Asia/Karachi`.
- Debug package `com.example.masjid_app`, version `1.0.0+1`.
- APK SHA-256: `de5b4c6c782cbceb34c6ba8b4c3365ecf2fc5f8ad5218bf532a2bfd6cafedbf9`.
- Installed with `adb install -r`; no uninstall, app-data clear or device reset.

## Verified so far

| Check | Evidence |
| --- | --- |
| Installation and startup | Installation succeeds; app restores the existing selected mosque, timetable and account session. No fatal/uncaught/reminder error appeared in the scoped app-log check. New sign-in/reauthentication was not tested. |
| Native prayer/settings UI | English/dark prayer rows and countdown are visible. The owner used the custom lead picker; its dialog and Save control remained above the native numeric keyboard. |
| Custom lead and scheduling | Owner-selected 33 minutes persists in device preferences. Native notification cache contains 35 unique weekly slots in `Asia/Karachi`. Friday slot 41051 is Jummah at 12:57 for a 13:30 prayer; no Friday Dhuhr duplicate. |
| Permission state | Native notification permission and `SCHEDULE_EXACT_ALARM` read as allowed after the owner used reminder controls. Denial/revocation/recovery were not independently completed in this pass. |
| Disable behavior | With the saved preference off, the native pending-notification cache becomes empty. |
| Background delivery | After coordinating exclusive device control, the real UI test button saves one-shot ID 41100 for 17:47:58 PKT; cache count becomes 36. The app is sent Home before delivery. Android posts ID 41100 on `prayer_reminders_v1` at **17:47:58.065 PKT**, with high importance and a notification icon. Native pending cache returns to 35 after the one-shot alarm fires. |
| Restore/cancellation | After the controlled test, the real Settings switch restores the owner's prior `enabled=false, leadMinutes=33` preference. Native pending cache is verified empty. Account, mosque selection, language and theme are preserved. |

The owner was initially interacting with the phone concurrently. Early test clicks were interrupted and are not counted as delivery evidence. The successful controlled retry started after the owner confirmed the phone was ready. Android's notification record supplies the creation timestamp, channel, ID and visible state; this is real native delivery evidence, not a mocked test or scheduling-only assertion. Audible output was not independently confirmed. The notification was cleared by the normal resume/reconciliation path before the tap test completed, so tap-to-open navigation remains **unverified** in this pass.

## Remaining acceptance

This debug-device pass does not establish signed-release behavior, reboot recovery, long battery-saver/Doze behavior, other OEMs/Android versions, actual daily prayer/Friday delivery, timezone changes, denied/revoked permission recovery, all English/Urdu/light/dark native flows, or interrupted account cleanup. Follow [PRAYER_REMINDERS.md](PRAYER_REMINDERS.md) and [ANDROID_RELEASE.md](ANDROID_RELEASE.md). Final identity/signing and reviewed backend migration/deployment remain release gates.
