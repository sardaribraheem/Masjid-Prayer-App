# Masjid Prayer App

Flutter Android app for local masjid communities: mosque selection, congregation prayer times, approved events, text-only community posts/comments, and scoped imam management. Firebase Authentication and Firestore store accounts and community data. Provider manages app state; English, Urdu and RTL are supported.

**Public launch: HOLD as of 14 October 2026.** Production still uses older email-based Firestore rules. Local fixes are not deployed. Final Android identity/signing, remaining device acceptance, timetable-editor fixes and community moderation controls are also pending.

## Start here

| Document | Purpose |
| --- | --- |
| [app_guide.md](app_guide.md) | Run the app; guest, muqtaddi and imam workflows; registration requirements; data storage |
| [launchplan.md](launchplan.md) | Ordered technical gates, mosque pilot, outreach, operations and revenue experiments |
| [FINALTODO.md](FINALTODO.md) | Current requirement status and deferred scope |
| [MVP_REVIEW.md](MVP_REVIEW.md) | Current risks and the evidence needed to close them |
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | Local Firebase configuration and safe emulator setup |
| [CLAUDE.md](CLAUDE.md) | Architecture and contributor briefing; also read [AGENTS.md](AGENTS.md) |
| [UI QA](scripts/qa/UI_QA.md) | Local test commands and browser verification limits |
| [Android device QA](scripts/qa/ANDROID_DEVICE_QA.md) | Actual phone observations and remaining acceptance checks |
| [Android release gate](scripts/qa/ANDROID_RELEASE.md) | Application ID, signing and store prerequisites |
| [Production audit](scripts/qa/PRODUCTION_AUDIT.md) | Confirmed deployed-rule gaps and migration sequence |

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run # connected Android device
```

Provide `android/app/google-services.json` locally; Git ignores it. Android startup uses native Firebase configuration. The existing application ID is `com.example.masjid_app`; the final ID remains an owner decision. Android is the only launch target. Web is retained for emulator/browser QA; other Flutter platform scaffolds are not release commitments.

For isolated QA, follow [UI QA](scripts/qa/UI_QA.md) and [rules tests](test/firestore/README.md). Fixtures are restricted to the local `demo-masjid-rules` emulators. Never seed production. Production rules/index deployment, administrator grants and publication require a separately reviewed, authorized operation.

## Product boundaries

- **Events** uses `CommunityPage`; **Community** uses `QuestionsPage`. Posts, questions, ayat/hadith text and comments have no attachment/upload controls.
- New accounts are ordinary members. Imam access requires approval, a matching mosque assignment and its protected manager UID grant. Super-admin access requires the server-issued `superAdmin` claim; email addresses grant no privileges in the reviewed source rules.
- Optional local Android reminders start off. Users choose 5, 10, 15, 20, 30 or 60 minutes, or custom 1–60 minutes. Friday uses Jummah when set. Alerts use phone timezone and the last saved timetable; reopening refreshes edits. One Android 14 background test passed; reboot, revocation and signed-release acceptance remain open.
- Attendance, media uploads, automatic expiry, payments and multi-mosque management are deferred. Google sign-in is hidden unless explicitly enabled and configured.
- Feeds/comments paginate by 30. Search applies to loaded pages. The mosque directory still loads all mosques and needs review before expansion.
- Anonymous posting hides a display name, while stored author UIDs remain readable. Deletion cleans UID-attributed data and can require retry after interruption; managers need reviewed transfer/revocation.

Bundled fonts and navigation icons support offline rendering. Keep [asset attribution](assets/README.md) and the font license. The launcher source PNG is retained for the existing icon-generation configuration; its final branding, resolution and usage rights require release review.

## Cleanup policy

The obsolete session log, duplicate `latesttodo.md`, unsafe Firebase helper and 27 old tracked Playwright snapshots were removed on 14 October. Useful requirements now live in FINALTODO; current risks and execution steps live in MVP_REVIEW and launchplan. Earlier document versions remain in Git history.

Keep source, platform tooling, lockfiles, licenses, security tests and QA procedures. Build output and temporary browser captures stay ignored. The current debug APK is local test output, not a release artifact.
