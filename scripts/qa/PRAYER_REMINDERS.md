# Android prayer reminder acceptance

Implemented at the owner's request on 14 October 2026. **Local logic/UI checks and one controlled Android background-delivery test pass.** The owner subsequently connected an Android 14 phone: the actual one-minute notification arrived at its scheduled time. See [device evidence](ANDROID_DEVICE_QA.md). This is a debug build on one device; broader delivery, reboot, permission-revocation and signed-release acceptance remain pending.

In Settings → Prayer reminders, enable alerts explicitly. The default lead is 15 minutes; presets are 5, 10, 15, 20, 30, and 60, with custom whole minutes from 1 through 60. The old saved-only notification preference does not opt users into the new scheduler. Permissions are requested only when enabling/retrying, not during startup or ordinary navigation.

Alerts use Android local exact alarms, the phone's IANA timezone, and the selected mosque's saved timetable. Up to 35 weekly slots cover five prayers, with Friday Jummah replacing Dhuhr if set. Sunrise, sunset, unset and invalid times are excluded. The schedule survives normal app closing through native receivers; reopen the app to refresh edited times or timezone changes. Force-stop, revoked permissions, and device battery restrictions can prevent delivery. There is no background server refresh or uploaded audio/media.

## Local evidence

`test/prayer_reminders_test.dart` adds 28 tests covering lead offsets, unique slots, Friday substitution/fallback, midnight/year/DST rollover, invalid times, legacy/default/corrupt preference handling, persistence, opt-in and denied permissions, replacing mosque/time/lead schedules, rapid changes, partial native failure rollback, missing pending IDs, storage errors, revocation, restart restoration, unsupported platforms, test-alarm isolation, and English/Urdu custom validation at 320px. Native calls use a fake boundary; these tests do not establish OS delivery.

`playwright-reminder-qa.js` passes 6 local browser assertions. The current source also builds an ARM64 debug APK at `build/app/outputs/flutter-apk/app-debug.apk` (14 October, 17:22 PKT). Compilation passed after clearing generated caches when disk exhaustion interrupted earlier attempts. No Android installation or actual alarm delivery was verified.

## Required Android checks

Use a real Android phone with the installed debug build first, then repeat on the signed release candidate. Use a staging mosque/timetable for controlled times; never seed test prayer data into production.

1. Fresh installation shows reminders off with 15 minutes selected. Old `notifications_enabled=true` must also remain off. Browsing or signing in does not prompt for notification/alarm permissions.
2. Enable reminders. On Android 13+ allow notifications; on Android versions requiring special alarm access, allow **Alarms & reminders**. Return to the app and check the scheduled state. Deny each permission separately and verify a clear recoverable state, without a false success message.
3. Use **Test reminder in 1 minute**, close the app normally, and confirm one visible notification with its white clock icon and sound. Tapping it should open the prayer tab. Repeat in Urdu and dark mode. Test an already-running app and a cold start.
4. Set a nearby staging prayer time. Confirm one alert 15 minutes beforehand; select 20 and repeat. Set a custom 17 minutes, restart the app, and confirm it persists. Values 0, 61, blank, and non-numeric input must fail validation.
5. Confirm five daily prayer alerts, no sunrise/sunset alert, and Friday Jummah instead of a second Dhuhr alert. If Jummah is unset, confirm Friday Dhuhr remains. Test a prayer whose lead crosses midnight.
6. Change selected mosque and edit its timetable while the app is open. Confirm old alerts are replaced and the new mosque/time appears. Edit while the app is closed, reopen it, and confirm refresh. Closing the app cannot fetch subsequent timetable edits automatically.
7. Disable reminders and confirm pending prayer/test alerts stop. Re-enable, revoke notifications, revoke exact-alarm permission, and disable the prayer channel separately in Android settings. Return to the app: it must show permission recovery and clear stale schedules. Retry and confirm recovery.
8. Reboot the phone after scheduling and confirm future alerts recover. Change phone timezone, reopen the app, and verify the schedule follows the documented phone-timezone behavior. Confirm disposal/closing does not cancel active schedules.
9. Check delivery in battery saver/Doze and on an OEM with aggressive battery controls. Record Android version/model, granted permissions, expected/actual timestamps, reboot behavior, and any required device settings. Test the signed artifact before store submission.

Implementation follows the plugin's [Android setup and scheduling documentation](https://pub.dev/packages/flutter_local_notifications) and Android's [exact alarm guidance](https://developer.android.com/develop/background-work/services/alarms/schedule). It uses user-granted `SCHEDULE_EXACT_ALARM`, without a fullscreen intent or `USE_EXACT_ALARM`.
